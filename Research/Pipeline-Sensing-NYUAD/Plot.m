
clear;
clc;
close all; % Close any open figures from previous runs
fprintf('--- Starting Comprehensive Plotting of ML Classification Metrics ---\n');

% --- Load Data ---clear;
clc;
close all;
fprintf('--- Starting Comprehensive Plotting of ML Classification Metrics ---\n');
results_file = 'ml_validation_results.mat';
if exist(results_file, 'file')
    load(results_file, 'validation_class_labels', 'predicted_class_labels_val', 'fault_types_map', 'faultClassifier', 'scaled_validation_features');
    fprintf('Loaded classification results, trained classifier, and scaled features from %s.\n', results_file);
else
    error('File %s not found. Please run BaselineDAQ.m first.', results_file);
end
if ~iscategorical(validation_class_labels)
    validation_class_labels = categorical(validation_class_labels);
end
if ~iscategorical(predicted_class_labels_val)
    predicted_class_labels_val = categorical(predicted_class_labels_val);
end
validation_class_labels = reordercats(validation_class_labels, fault_types_map);
predicted_class_labels_val = reordercats(predicted_class_labels_val, fault_types_map);
classNames = categories(validation_class_labels);
numClasses = length(classNames);
dashboard_fig = figure('Name', 'Comprehensive ML Report Dashboard', 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
tiledlayout(2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
C = confusionmat(validation_class_labels, predicted_class_labels_val, 'Order', fault_types_map);
precision_scores = zeros(1, numClasses);
recall_scores = zeros(1, numClasses);
f1_scores = zeros(1, numClasses);
for j = 1:numClasses
    TP = C(j, j);
    FP = sum(C(:, j)) - TP;
    FN = sum(C(j, :)) - TP;
    precision_scores(j) = TP / (TP + FP + eps);
    recall_scores(j) = TP / (TP + FN + eps);
    if (precision_scores(j) + recall_scores(j)) > eps
        f1_scores(j) = 2 * (precision_scores(j) * recall_scores(j)) / (precision_scores(j) + recall_scores(j));
    else
        f1_scores(j) = 0;
    end
end
fprintf('\nPer-Class Classification Metrics (Validation Set):\n');
fprintf('%-20s %-10s %-10s %-10s\n', 'Fault Type', 'Precision', 'Recall', 'F1-Score');
fprintf('%-20s %-10s %-10s %-10s\n', '--------------------', '----------', '----------', '----------');
for j = 1:numClasses
    fprintf('%-20s %-10.4f %-10.4f %-10.4f\n', classNames{j}, precision_scores(j), recall_scores(j), f1_scores(j));
end
nexttile;
bar_data = [precision_scores; recall_scores; f1_scores];
b = bar(bar_data', 'grouped');
set(gca, 'xticklabel', classNames);
ylabel('Score');
title('Precision, Recall, and F1-Score per Fault Type');
legend({'Precision', 'Recall', 'F1-Score'}, 'Location', 'northwest');
grid on;
ylim([0 1]);
for k = 1:size(bar_data, 1)
    for j = 1:size(bar_data, 2)
        text(b(k).XEndPoints(j), b(k).YEndPoints(j), sprintf('%.2f', bar_data(k,j)), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8, 'Color', 'black');
    end
end
nexttile;
cm_chart = confusionchart(validation_class_labels, predicted_class_labels_val, 'Title', 'Fault Type Classification Confusion Matrix (Validation Set)', 'RowSummary', 'row-normalized', 'ColumnSummary', 'column-normalized');
blue_color = [0 0.4470 0.7410];
red_color = [0.8500 0.3250 0.0980];
cm_chart.DiagonalColor = blue_color;
cm_chart.OffDiagonalColor = red_color;
cm_chart.FontSize = 10;
cm_chart.Title = sprintf('%s\nAccuracy: %.2f%%', cm_chart.Title, sum(diag(C))/sum(C(:))*100);
nexttile;
if isa(faultClassifier, 'TreeBagger') && faultClassifier.NTrees > 0
    [~, scores] = predict(faultClassifier, scaled_validation_features);
    sum_scores = sum(scores, 2);
    sum_scores(sum_scores == 0) = 1;
    class_probabilities = scores ./ sum_scores;
    hold on;
    colors = lines(numClasses);
    all_auc = zeros(1, numClasses);
    markers = {'o','s','^','d','p','h','>','<','v'};
    numeric_true_labels = grp2idx(validation_class_labels);
    for i = 1:numClasses
        binary_true_labels = (numeric_true_labels == i);
        current_class_scores = class_probabilities(:, i);
        current_marker = markers{mod(i-1, length(markers)) + 1};
        if ~isempty(current_class_scores) && length(unique(binary_true_labels)) > 1 && any(binary_true_labels) && any(~binary_true_labels)
            [X_roc, Y_roc, ~, AUC] = perfcurve(binary_true_labels, current_class_scores, true);
            all_auc(i) = AUC;
            plot(X_roc, Y_roc, 'Color', colors(i,:), 'LineWidth', 1.5, 'Marker', current_marker, 'MarkerSize', 4, 'DisplayName', sprintf('%s (AUC = %.2f)', classNames{i}, AUC));
        else
            all_auc(i) = NaN;
        end
    end
    plot([0 1], [0 1], 'k--', 'LineWidth', 1, 'DisplayName', 'Random');
    hold off;
    xlabel('False Positive Rate');
    ylabel('True Positive Rate');
    title('One-vs-All ROC Curves (Validation Set)');
    legend('Location', 'southeast', 'FontSize', 8);
    grid on;
else
    warning('Fault classifier invalid. ROC skipped.');
    text(0.5, 0.5, 'ROC Curves Skipped', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 12, 'Color', 'red');
end
fprintf('\n--- All MATLAB Plotting Complete. ---\n');
fprintf('\n--- Generating Feature Importance Plot ---\n');
if isa(faultClassifier, 'TreeBagger') && isprop(faultClassifier, 'OOBPermutedPredictorDeltaError') && ~isempty(faultClassifier.OOBPermutedPredictorDeltaError)
    importance = faultClassifier.OOBPermutedPredictorDeltaError;
    feature_names = {'Peak Prominence','RMS','Max Abs Value','Spectral Centroid','Spectral Bandwidth'};
    if length(importance) ~= length(feature_names)
        feature_names = arrayfun(@(x) sprintf('Feature %d', x), 1:length(importance), 'UniformOutput', false);
    end
    [sorted_importance, sort_idx] = sort(importance, 'descend');
    sorted_feature_names = feature_names(sort_idx);
    num_features = length(sorted_importance);
    figure('Name', 'Standalone Feature Importance Plot', 'Color', 'w', 'Position', [100 100 800 600]);
    colors = flipud(parula(num_features));
    b = barh(sorted_importance, 'FaceColor', 'flat');
    b.CData = colors;
    set(gca, 'YTick', 1:num_features);
    set(gca, 'YTickLabel', sorted_feature_names, 'YDir', 'reverse', 'FontSize', 10);
    xlabel('Feature Importance');
    title('Feature Importance for Fault Classification', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    box on;
    ax = gca;
    ax.GridLineStyle = ':';
    ax.Layer = 'bottom';
    for i = 1:num_features
        text(sorted_importance(i) + max(sorted_importance)*0.01, i, sprintf('%.2f', sorted_importance(i)), 'VerticalAlignment', 'middle', 'FontSize', 9);
    end
    xlim([0 max(sorted_importance)*1.15]);
else
    warning('Could not generate importance plot.');
end

% This file is expected to be generated by train_and_evaluate_models.m
results_file = 'ml_validation_results.mat';
if exist(results_file, 'file')
    load(results_file, 'validation_class_labels', 'predicted_class_labels_val', 'fault_types_map', 'faultClassifier', 'scaled_validation_features');
    fprintf('Loaded classification results, trained classifier, and scaled features from %s.\n', results_file);
else
    error('File %s not found. Please run BaselineDAQ.m (which calls train_and_evaluate_models.m) first to generate the necessary data and save the classifier and features.', results_file);
end

% Ensure labels are categorical and have consistent categories (important for plotting functions)
if ~iscategorical(validation_class_labels)
    validation_class_labels = categorical(validation_class_labels);
end
if ~iscategorical(predicted_class_labels_val)
    predicted_class_labels_val = categorical(predicted_class_labels_val);
end

% Reorder categories to ensure consistent plotting order across figures
validation_class_labels = reordercats(validation_class_labels, fault_types_map);
predicted_class_labels_val = reordercats(predicted_class_labels_val, fault_types_map);
classNames = categories(validation_class_labels);
numClasses = length(classNames);

% Create a single figure for the dashboard
dashboard_fig = figure('Name', 'Comprehensive ML Report Dashboard', 'Units', 'normalized', 'OuterPosition', [0 0 1 1]); % Full screen

% Changed tiledlayout to 2 rows, 2 columns for 4 plots
tiledlayout(2, 2, 'Padding', 'compact', 'TileSpacing', 'compact'); % 2 rows, 2 columns layout for 4 plots

% --- PLOT 1: Per-Class Precision, Recall, F1-Score Bar Chart ---
fprintf('\n--- 1. Generating Per-Class Precision, Recall, F1-Score Bar Chart ---\n');
% Compute Confusion Matrix (essential for TP, FP, FN)
C = confusionmat(validation_class_labels, predicted_class_labels_val, 'Order', fault_types_map);

precision_scores = zeros(1, numClasses);
recall_scores = zeros(1, numClasses);
f1_scores = zeros(1, numClasses);

for j = 1:numClasses
    TP = C(j, j);
    FP = sum(C(:, j)) - TP; % Sum of column j - TP
    FN = sum(C(j, :)) - TP; % Sum of row j - TP
    
    % Add eps (epsilon) to denominators to avoid division by zero
    precision_scores(j) = TP / (TP + FP + eps);
    recall_scores(j) = TP / (TP + FN + eps);
    
    if (precision_scores(j) + recall_scores(j)) > eps
        f1_scores(j) = 2 * (precision_scores(j) * recall_scores(j)) / (precision_scores(j) + recall_scores(j));
    else
        f1_scores(j) = 0;
    end
end

fprintf('\nPer-Class Classification Metrics (Validation Set):\n');
fprintf('%-20s %-10s %-10s %-10s\n', 'Fault Type', 'Precision', 'Recall', 'F1-Score');
fprintf('%-20s %-10s %-10s %-10s\n', '--------------------', '----------', '----------', '----------');
for j = 1:numClasses
    fprintf('%-20s %-10.4f %-10.4f %-10.4f\n', classNames{j}, precision_scores(j), recall_scores(j), f1_scores(j));
end

nexttile; % Move to the first tile (top-left)
bar_data = [precision_scores; recall_scores; f1_scores];
b = bar(bar_data', 'grouped');
set(gca, 'xticklabel', classNames);
ylabel('Score');
title('Precision, Recall, and F1-Score per Fault Type');
legend({'Precision', 'Recall', 'F1-Score'}, 'Location', 'northwest');
grid on;
ylim([0 1]);
% Add value labels on top of bars
for k = 1:size(bar_data, 1)
    for j = 1:size(bar_data, 2)
        text(b(k).XEndPoints(j), b(k).YEndPoints(j), sprintf('%.2f', bar_data(k,j)), ...
             'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'bottom', ...
             'FontSize', 8, 'Color', 'black');
    end
end
fprintf('  Plot 1: Per-Class Bar Chart generated.\n');

% --- PLOT 2: Classification Confusion Matrix Heatmap ---
fprintf('\n--- 2. Generating Classification Confusion Matrix Heatmap ---\n');
nexttile; % Move to the next tile (top-right)
cm_chart = confusionchart(validation_class_labels, predicted_class_labels_val, ...
                          'Title', 'Fault Type Classification Confusion Matrix (Validation Set)', ...
                          'RowSummary', 'row-normalized', ... % Shows Recall values
                          'ColumnSummary', 'column-normalized'); % Shows Precision values
% Define colors:
blue_color = [0 0.4470 0.7410]; % MATLAB's default blue
red_color = [0.8500 0.3250 0.0980]; % MATLAB's default orange-red (good for errors)
cm_chart.DiagonalColor = blue_color;
cm_chart.OffDiagonalColor = red_color; 
cm_chart.FontSize = 10; % Adjust font size for overall chart readability
cm_chart.Title = sprintf('%s\nAccuracy: %.2f%%', cm_chart.Title, sum(diag(C))/sum(C(:))*100); % Add overall accuracy to title
fprintf('  Plot 2: Confusion Matrix Heatmap generated.\n');

% --- PLOT 3: One-vs-All ROC Curves with AUC ---
fprintf('\n--- 3. Generating One-vs-All ROC Curves and AUC ---\n');
nexttile; % Move to the next tile (bottom-left)
if isa(faultClassifier, 'TreeBagger') && faultClassifier.NTrees > 0 
    
    % Get scores (probabilities/votes) for ROC curve calculation
    [~, scores] = predict(faultClassifier, scaled_validation_features); 
    
    % Normalize scores to act as probabilities for `perfcurve`.
    sum_scores = sum(scores, 2);
    sum_scores(sum_scores == 0) = 1; % Avoid division by zero
    class_probabilities = scores ./ sum_scores;
    
    hold on;
    colors = lines(numClasses); % Get distinct colors for each curve
    all_auc = zeros(1, numClasses);
    % Define a set of distinct markers to differentiate overlapping perfect curves
    markers = {'o', 's', '^', 'd', 'p', 'h', '>', '<', 'v'}; % More markers than classes, just in case
    % `grp2idx` converts categorical array to numeric array (1, 2, 3, ...)
    numeric_true_labels = grp2idx(validation_class_labels); 
    
    for i = 1:numClasses
        current_class_name = classNames{i};
        
        % True labels for this one-vs-all comparison: logical array (true for current class, false for others)
        binary_true_labels = (numeric_true_labels == i); 
        
        % Scores for this class (probability of being this class)
        current_class_scores = class_probabilities(:, i);
        
        % Select marker for current class (use modulo to cycle if more classes than markers)
        current_marker = markers{mod(i-1, length(markers)) + 1};
        
        % Calculate ROC curve
        if ~isempty(current_class_scores) && length(unique(binary_true_labels)) > 1 && any(binary_true_labels) && any(~binary_true_labels)
            [X_roc, Y_roc, ~, AUC] = perfcurve(binary_true_labels, current_class_scores, true); 
            all_auc(i) = AUC;
            plot(X_roc, Y_roc, 'Color', colors(i,:), 'LineWidth', 1.5, ...
                 'Marker', current_marker, 'MarkerSize', 4, ... % ADDED MARKER PROPERTIES
                 'DisplayName', sprintf('%s (AUC = %.2f)', current_class_name, AUC)); 
        else
            fprintf('    Skipping ROC for "%s": Insufficient data (only one class, empty, or all same labels) in validation set for ROC plot.\n', current_class_name);
            all_auc(i) = NaN; % Mark AUC as NaN if not plotted
        end
    end
    
    plot([0 1], [0 1], 'k--', 'LineWidth', 1, 'DisplayName', 'Random'); % Diagonal line
    hold off;
    
    xlabel('False Positive Rate');
    ylabel('True Positive Rate');
    title('One-vs-All ROC Curves (Validation Set)');
    legend('Location', 'southeast', 'FontSize', 8);
    grid on;
    fprintf('  Plot 3: One-vs-All ROC Curves generated.\n');
    fprintf('  AUC Scores (per class): \n');
    for i = 1:numClasses
        fprintf('    %s: %.2f\n', classNames{i}, all_auc(i));
    end
else
    warning('Fault classifier is not a valid TreeBagger model or has no trees. Skipping ROC curve plot.');
    fprintf('  Plot 3: ROC Curves skipped.\n');
    text(0.5, 0.5, 'ROC Curves Skipped: Classifier Invalid or No Trees', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 12, 'Color', 'red');
end


fprintf('\n--- All MATLAB Plotting Complete. Check the "Comprehensive ML Report Dashboard" figure window. ---\n');

% === Standalone Feature Importance Plot ===
fprintf('\n--- Generating Feature Importance Plot (Separate Figure) ---\n');

if isa(faultClassifier, 'TreeBagger') && ...
   isprop(faultClassifier, 'OOBPermutedPredictorDeltaError') && ...
   ~isempty(faultClassifier.OOBPermutedPredictorDeltaError)

    importance = faultClassifier.OOBPermutedPredictorDeltaError;

    feature_names = {
        'Max Amplitude', 'Min Amplitude', 'Peak-to-Peak Amplitude', 'Signal Range', ...
        'Sum of Absolute Amplitudes', 'Num Positive Peaks', 'Num Negative Peaks', ...
        'Avg Positive Peak Height', 'Avg Negative Peak Height', 'RMS Value', ...
        'Signal Energy', 'Signal Power', 'Mean', 'Median', 'Standard Deviation', ...
        'Variance', 'Skewness', 'Kurtosis', 'Power (Low Freq Band)', ...
        'Power (High Freq Band)', 'Dominant Frequency', 'Waveform Length', ...
        'Zero Crossings', 'Mean Absolute Deviation', 'Approximate Entropy', ...
        'Wavelet Energy A3', 'Wavelet Energy D1', 'Wavelet Energy D2', ...
        'Wavelet Energy D3', 'Wavelet D1/Total Energy Ratio'
    };

    % Check mismatch
    if length(importance) ~= length(feature_names)
        warning('Feature name count mismatch. Falling back to generic names.');
        feature_names = arrayfun(@(x) sprintf('Feature %d', x), 1:length(importance), 'UniformOutput', false);
    end

    [sorted_importance, sort_idx] = sort(importance, 'descend');
    sorted_feature_names = feature_names(sort_idx);
    num_features = length(sorted_importance);
    
    % New figure
    figure('Name', 'Standalone Feature Importance Plot', 'Color', 'w', 'Position', [100 100 800 600]);

    % Create colored barh
    colors = flipud(parula(num_features));
    b = barh(sorted_importance, 'FaceColor', 'flat');
    b.CData = colors;

    % Y-axis settings
    set(gca, 'YTick', 1:num_features);
    set(gca, 'YTickLabel', sorted_feature_names, 'YDir', 'reverse', 'FontSize', 10);
    xlabel('Feature Importance (OOB Permuted Error)', 'FontSize', 11);
    title('Feature Importance for Fault Classification', 'FontSize', 14, 'FontWeight', 'bold');

    % Add grid and box
    grid on; box on;
    ax = gca;
    ax.GridLineStyle = ':';
    ax.Layer = 'bottom';

    % Annotate all bars
    for i = 1:num_features
        text(sorted_importance(i) + max(sorted_importance)*0.01, i, ...
             sprintf('%.2f', sorted_importance(i)), ...
             'VerticalAlignment', 'middle', 'FontSize', 9);
    end

    xlim([0 max(sorted_importance)*1.15]);
else
    warning('Could not generate  importance plot (TreeBagger missing or invalid).');
end
