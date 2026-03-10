function [faultClassifier, severityRegressor, anomalyDetector, fault_types_map, classification_metrics, regression_metrics] = train_and_evaluate_models(...
    Fs, ...
    training_features, training_class_labels, training_regress_labels, ...
    validation_features, validation_class_labels, validation_regress_labels)
fprintf('  -> Training ML Models...\n');
if isempty(training_features)
    error('Training features are empty. Cannot train models or calculate scaling parameters.');
end
training_mean = mean(training_features, 1);
training_std = std(training_features, 0, 1);
training_std(training_std == 0) = 1;
scaled_training_features = (training_features - training_mean) ./ training_std;
scaled_validation_features = [];
if ~isempty(validation_features)
    scaled_validation_features = (validation_features - training_mean) ./ training_std;
end
save('feature_scaling_params.mat', 'training_mean', 'training_std');
training_class_labels = categorical(training_class_labels);
validation_class_labels = categorical(validation_class_labels);
fault_types_map = cellstr(categories(training_class_labels));
fprintf('  -> Training Fault Classification Model (TreeBagger / Random Forest for Classification)...\n');
figure('Name', 'Feature Space Visualization');
gscatter(scaled_training_features(:,1), scaled_training_features(:,4), training_class_labels);
xlabel('Scaled Peak Prominence');
ylabel('Scaled Spectral Centroid');
title('Feature Space Separation by Fault Type (Training Data)');
legend(unique(training_class_labels), 'Location', 'best');
grid on;
try
    if size(scaled_training_features, 1) < 2 || length(unique(training_class_labels)) < 2
        error('Not enough data or unique classes for TreeBagger classification training.');
    end
    faultClassifier = TreeBagger(150, scaled_training_features, training_class_labels, ...
                                 'Method', 'classification', ...
                                 'OOBPrediction', 'on', ...
                                 'OOBPredictorImportance', 'on', ...
                                 'MinLeafSize', 5, ...
                                 'ClassNames', fault_types_map);
catch ME
    warning('Failed to train Classification Model (TreeBagger). Error: %s. Using a dummy classifier.', ME.message);
    dummy_features = zeros(1, size(scaled_training_features, 2));
    dummy_labels = categorical({'Clean'});
    faultClassifier = fitcsvm(dummy_features, dummy_labels, 'Standardize', false);
end
fprintf('  -> Training Severity Regression Model (TreeBagger / Random Forest for Regression)...\n');
idx_non_clean_train = (training_regress_labels > 0);
if any(idx_non_clean_train)
    try
        if sum(idx_non_clean_train) < 2
            error('Not enough non-Clean samples for TreeBagger regression training.');
        end
        severityRegressor = TreeBagger(150, scaled_training_features(idx_non_clean_train, :), ...
                                       training_regress_labels(idx_non_clean_train), ...
                                       'Method', 'regression', ...
                                       'OOBPrediction', 'on', ...
                                       'OOBPredictorImportance', 'on', ...
                                       'MinLeafSize', 5);
    catch ME
        warning('Failed to train Regression Model (TreeBagger). Error: %s. Using a dummy regressor.', ME.message);
        dummy_features = zeros(1, size(scaled_training_features, 2));
        severityRegressor = fitrlinear(dummy_features, 0);
    end
else
    warning('No non-Clean samples in training data for severity regression. Severity Regressor will be a dummy model.');
    dummy_features = zeros(1, size(scaled_training_features, 2));
    severityRegressor = fitrlinear(dummy_features, 0);
end
fprintf('  -> Training Anomaly Detection Model (One-Class SVM)...\n');
idx_clean_train = (training_class_labels == 'Clean');
if any(idx_clean_train)
    try
        anomalyDetector = fitcsvm(scaled_training_features(idx_clean_train, :), ones(sum(idx_clean_train), 1), ...
                                 'KernelFunction', 'gaussian', ...
                                 'Standardize', true, ...
                                 'ClassNames', [1], ...
                                 'OutlierFraction', 0.05, ...
                                 'KernelScale', 'auto');
    catch ME
        warning('Failed to train Anomaly Detection Model. Error: %s. Anomaly Detector will be empty.', ME.message);
        anomalyDetector = [];
    end
else
    warning('No "Clean" samples in training data for Anomaly Detection. Anomaly Detector will be empty.');
    anomalyDetector = [];
end
fprintf('  -> Evaluating Models on Validation Set...\n');
classification_metrics.confusion_matrix = [];
classification_metrics.accuracy = NaN;
classification_metrics.precision = NaN;
classification_metrics.recall = NaN;
classification_metrics.f1_score = NaN;
regression_metrics.RMSE = NaN;
regression_metrics.MAE = NaN;
regression_metrics.R2 = NaN;
if ~isempty(faultClassifier) && ~isa(faultClassifier, 'double') && ~isempty(scaled_validation_features) && ~isempty(validation_class_labels)
    try
        [predicted_class_labels_val_str, ~] = predict(faultClassifier, scaled_validation_features);
        predicted_class_labels_val = categorical(predicted_class_labels_val_str, categories(validation_class_labels));
        C = confusionmat(validation_class_labels, predicted_class_labels_val);
        classification_metrics.confusion_matrix = C;
        accuracy = sum(diag(C)) / sum(C(:));
        classification_metrics.accuracy = accuracy;
        num_classes = size(C, 1);
        precision_per_class = zeros(1, num_classes);
        recall_per_class = zeros(1, num_classes);
        f1_per_class = zeros(1, num_classes);
        for i = 1:num_classes
            true_positives = C(i, i);
            false_positives = sum(C(:, i)) - true_positives;
            false_negatives = sum(C(i, :)) - true_positives;
            precision_per_class(i) = true_positives / (true_positives + false_positives + eps);
            recall_per_class(i) = true_positives / (true_positives + false_negatives + eps);
            if (precision_per_class(i) + recall_per_class(i)) > eps
                f1_per_class(i) = 2 * (precision_per_class(i) * recall_per_class(i)) / (precision_per_class(i) + recall_per_class(i));
            else
                f1_per_class(i) = 0;
            end
        end
        classification_metrics.precision = mean(precision_per_class);
        classification_metrics.recall = mean(recall_per_class);
        classification_metrics.f1_score = mean(f1_per_class);
        figure('Name', 'Classification Confusion Matrix');
        cm = confusionchart(validation_class_labels, predicted_class_labels_val);
        cm.Title = sprintf('Fault Type Classification Confusion Matrix (Accuracy: %.2f%%)', accuracy * 100);
        cm.ColumnSummary = 'column-normalized';
        cm.RowSummary = 'row-normalized';
        save('ml_validation_results.mat', ...
             'validation_class_labels', ...
             'predicted_class_labels_val', ...
             'fault_types_map', ...
             'faultClassifier', ...
             'scaled_validation_features', ...
             '-v7.3');
        fprintf('  Helper: Saved validation results and classifier to ml_validation_results.mat for plotting.\n');
    catch ME
        warning('Error during classification metric calculation or saving: %s', ME.message);
    end
else
    fprintf('  -> Classification metrics skipped: Classifier not properly trained or validation data empty.\n');
end
idx_non_clean_val = (validation_regress_labels > 0);
if any(idx_non_clean_val) && ~isempty(severityRegressor) && ~isa(severityRegressor, 'double') && ~isempty(scaled_validation_features)
    try
        predicted_severity_val = predict(severityRegressor, scaled_validation_features(idx_non_clean_val, :));
        predicted_severity_val = max(0, min(1, predicted_severity_val));
        actual_severity_val = validation_regress_labels(idx_non_clean_val);
        RMSE = sqrt(mean((predicted_severity_val - actual_severity_val).^2));
        MAE = mean(abs(predicted_severity_val - actual_severity_val));
        SS_total = sum((actual_severity_val - mean(actual_severity_val)).^2);
        SS_residual = sum((actual_severity_val - predicted_severity_val).^2);
        if SS_total > eps
            R2 = 1 - (SS_residual / SS_total);
        else
            R2 = NaN;
        end
        regression_metrics.RMSE = RMSE;
        regression_metrics.MAE = MAE;
        regression_metrics.R2 = R2;
        figure('Name', 'Severity Regression: Predicted vs. Actual');
        scatter(actual_severity_val, predicted_severity_val, 'filled', 'DisplayName', 'Predictions');
        hold on;
        plot([0 1], [0 1], '--r', 'LineWidth', 1.5, 'DisplayName', 'Ideal Prediction');
        hold off;
        xlabel('Actual Severity');
        ylabel('Predicted Severity');
        title(sprintf('Severity Regression Performance (RMSE: %.4f, MAE: %.4f, R2: %.2f)', RMSE, MAE, R2));
        grid on;
        legend('Location', 'best');
    catch ME
        warning('Error during regression metric calculation: %s', ME.message);
    end
else
    fprintf('  -> Regression metrics skipped: Not enough non-Clean validation samples or regressor not trained/validation data empty.\n');
end
end
