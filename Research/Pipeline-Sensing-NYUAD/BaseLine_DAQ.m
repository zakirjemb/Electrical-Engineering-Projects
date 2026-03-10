% BaseLine_DAQ.m - Main script for Fiber Optic Fault Detection and Classification
% This version integrates with a Real-time DAQ system, enhanced feature
% extraction, and includes time-domain signal visualization for fault types.
% It now supports training/validation using either collected real data or synthetic data.
% Includes logic for anomaly detection and more detailed performance metrics.
% --- MODIFIED TO INCLUDE CASCADED HYBRID CLASSIFIER-ANOMALY SYSTEM (CHCAS) ---
function BaseLine_DAQ
% Clear workspace and command window
clear;
clc;
close all; % Close any open figures

% Add path to helper functions
addpath(genpath('helpers')); % Ensure your helper functions are in a subfolder named 'helpers'

% --- Configuration Parameters ---
FIBER_LENGTH_KM = 10; % Total fiber length in km (for distance calculations)
NUM_ITERATIONS = 5;  % Number of live acquisition iterations
EMAIL_NOTIFICATION_THRESHOLD = 0.5; % Severity threshold for sending email

% --- Fault Detection Thresholds (for detect_faults.m) ---
% IMPORTANT: These thresholds are CRITICAL for real-world performance.
% Tune these by observing your *processed* (filtered and normalized) signals.
% Use the live plotting functionality below to aid in tuning.
% Start with values that are clearly above noise in 'Clean' signals
% and clearly below typical fault signatures.
FAULT_DETECTION_PEAK_THRESHOLD = 0.2; % Amplitude threshold for detecting positive peaks (reflections)
                                      % (e.g., 0.05 is too low for many normalized signals; 0.2-0.5 might be better)
FAULT_DETECTION_SLOPE_THRESHOLD = 0.05; % Absolute threshold for detecting significant negative slopes
                                       % (attenuation/drops in signal level). Applied to negative derivative.
                                       % (0.01 is too low for most noisy signals; 0.05-0.2 might be better)

% --- Anomaly Detection Threshold ---
% This threshold is specific to the output of your anomaly detection model (e.g., One-Class SVM score).
% Tune this based on your anomaly detection model's behavior for clean vs. anomalous data.
% Negative scores from One-Class SVM typically indicate 'normal' (inlier), positive indicate 'anomaly'.
% This threshold defines the boundary.
ANOMALY_DETECTION_THRESHOLD = 0.05; % Example value; you MUST tune this by analyzing scores (e.g., histogram).
                                    % Start with 0.05 or 0.1 and adjust based on FP/FN.

% --- CHCAS Specific Thresholds for Severity Mapping ---
% These thresholds map the One-Class SVM anomaly score or regressor output to severity levels.
% You MUST tune these based on empirical data and desired operational thresholds.
CHCAS_NORMAL_THRESHOLD = -0.1; % One-Class SVM score below this is confidently 'Normal'.
                               % Scores from One-Class SVM are often negative for inliers.
CHCAS_SEVERITY_THRESHOLD_1 = 0.1; % Anomaly score above this indicates Minor Anomaly/Severity
CHCAS_SEVERITY_THRESHOLD_2 = 0.3; % Anomaly score above this indicates Moderate Anomaly/Severity
                                 % Scores above this are typically Severe.

% --- GEOGRAPHICAL FIBER LAYOUT CONFIGURATION ---
% Define the starting point of your fiber optic cable (e.g., where your DAQ is located)
START_LAT = 24.4667;    % Example: Latitude of Abu Dhabi (replace with your actual start point)
START_LON = 54.3667;    % Example: Longitude of Abu Dhabi (replace with your actual start point)
% Define the bearing (direction) of your fiber optic cable in degrees from North
% 0 = North, 90 = East, 180 = South, 270 = West.
FIBER_BEARING_DEG = 90; % Example: Fiber runs perfectly East from the start point.
% -------------------------------------------------

% --- DAQ Configuration (YOU MUST VERIFY AND ADJUST THESE) ---
DAQ_ANALOG_INPUT_CHANNEL = 'ai0'; % <<-- Change if your photodiode is on a different channel
Fs_real = 100e3; % Example: 100 kHz (Real DAQ sampling frequency)
                 % Ensure this matches your physical DAQ hardware's actual sampling rate.
% --- Acquisition Duration Guidance ---
% The acquisition duration must be long enough to capture reflections from the furthest expected fault.
% Time of flight (ToF) for a reflection from distance D is: ToF = 2 * D / speed_in_fiber.
% speed_in_fiber (speed of light in fiber) is approximately 2e8 m/s (200,000 km/s).
% For FIBER_LENGTH_KM = 10 km (10,000 meters), max ToF = 2 * 10000 m / 2e8 m/s = 0.0001 seconds (0.1 ms).
% The ACQUISITION_DURATION_S should be greater than the maximum ToF to ensure you capture
% the entire signal, including reflections from the end of the fiber.
ACQUISITION_DURATION_S = 0.01; % Example: 10 milliseconds (This is ample for 10km fiber based on ToF)
% Adjust this based on your specific fiber length and expected event durations.

% --- Signal Filtering Parameters ---
% Tune these based on the noise characteristics of your raw DAQ signal.
MEDIAN_FILTER_WINDOW_SIZE = 5; % Example: window of 5 samples. Good for removing impulsive spikes.
LOWPASS_CUTOFF_FREQ_HZ = 30e3; % Example: 30 kHz cutoff for Fs_real=100kHz.
                               % Should be lower than Fs_real/2 (Nyquist). Tune based on signal content.
LOWPASS_FILTER_ORDER = 4;    % Filter order. Higher order = sharper cutoff, but more processing.

% --- Firebase Configuration (Placeholder - actual integration requires more) ---
FIREBASE_CONFIG = struct(...
    'projectId', 'your-project-id', ...
    'databaseUrl', 'https://your-project-id-default-rtdb.firebaseio.com/', ...
    'storageBucket', 'your-project-id.appspot.com' ...
);
firebaseClient = []; % This won't actually connect to Firebase in this script, it's a placeholder.

% Define fault types (must be consistent across scripts)
fault_types_for_demonstration = {'Clean', 'Connector Fault', 'Fiber Break', 'Bend Loss'};

% --- 1. Initialize DAQ Session ---
fprintf('\n--- DAQ Device Selection ---\n');
daq_devices = daq.getDevices;
if isempty(daq_devices)
    fprintf(2, 'Error: No DAQ devices found. Please ensure your NI DAQ is connected and drivers are installed.\n');
    return;
end
fprintf('Available DAQ Devices:\n');
for i = 1:length(daq_devices)
    fprintf('[%d] ID: %s, Description: %s\n', i, daq_devices(i).ID, daq_devices(i).Description);
end
selected_device_idx = 0;
while selected_device_idx < 1 || selected_device_idx > length(daq_devices)
    try
        prompt = sprintf('Enter the number of the DAQ device to use (1-%d): ', length(daq_devices));
        selected_device_idx = input(prompt);
        if isempty(selected_device_idx) || ~isnumeric(selected_device_idx)
            selected_device_idx = 0; % Force re-loop
        end
    catch
        selected_device_idx = 0; % Force re-loop on invalid input
    end
    if selected_device_idx < 1 || selected_device_idx > length(daq_devices)
        fprintf(2, 'Invalid selection. Please enter a number between 1 and %d.\n', length(daq_devices));
    end
end
DAQ_DEVICE_NAME = daq_devices(selected_device_idx).ID;
fprintf('Selected DAQ Device: %s (%s)\n', DAQ_DEVICE_NAME, daq_devices(selected_device_idx).Description);
fprintf('Initializing DAQ session on channel ''%s''...\n', DAQ_ANALOG_INPUT_CHANNEL);
try
    s = daq.createSession('ni'); % Creates a National Instruments DAQ session
    ch = s.addAnalogInputChannel(DAQ_DEVICE_NAME, DAQ_ANALOG_INPUT_CHANNEL, 'Voltage');
    ch.TerminalConfig = 'SingleEnded'; % Common configuration for many photodiodes
    s.Rate = Fs_real;
    s.DurationInSeconds = ACQUISITION_DURATION_S;
    fprintf('✅ DAQ session initialized successfully. Sample Rate: %.0f Hz, Duration: %.3f s.\n', Fs_real, ACQUISITION_DURATION_S);
catch ME
    fprintf(2, 'Error initializing DAQ: %s\n', ME.message);
    fprintf(2, 'Please ensure your NI DAQ device is connected and selected correctly.\n');
    fprintf(2, 'Run "daq.getDevices" in MATLAB Command Window to list available devices.\n');
    return; % Exit if DAQ initialization fails
end

% --- 2. Prepare Training and Validation Data ---
fprintf('\n--- Preparing Training and Validation Data for ML Models ---\n');
training_features_final = [];
training_class_labels_final = categorical([]);
training_regress_labels_final = [];
validation_features_final = [];
validation_class_labels_final = categorical([]);
validation_regress_labels_final = [];
real_data_source_dir = 'real_daq_data'; % Directory where you will save your real lab data

% Check if real data directory exists and contains .mat files
if exist(real_data_source_dir, 'dir') && ~isempty(dir(fullfile(real_data_source_dir, '*.mat')))
    fprintf('Real data directory "%s" found with existing .mat files. Loading real data for training and validation...\n', real_data_source_dir);
    
    all_loaded_real_features = [];
    all_loaded_real_class_labels = categorical([]);
    all_loaded_real_regress_labels = [];
    
    mat_files_for_ml = dir(fullfile(real_data_source_dir, '*.mat'));
    for k = 1:length(mat_files_for_ml)
        filename = fullfile(real_data_source_dir, mat_files_for_ml(k).name);
        loaded_data = load(filename);
        
        if isfield(loaded_data, 'daq_signal_data') && isfield(loaded_data, 'Fs_real') && ...
           isfield(loaded_data, 'true_fault_type_actual') && isfield(loaded_data, 'true_fault_severity_actual')
            
            % IMPORTANT: extract_features.m now returns 20 features.
            features_current = extract_features(loaded_data.daq_signal_data, loaded_data.Fs_real);
            
            all_loaded_real_features = [all_loaded_real_features; features_current]; %#ok<AGROW>
            all_loaded_real_class_labels = [all_loaded_real_class_labels; categorical({loaded_data.true_fault_type_actual}, fault_types_for_demonstration)]; %#ok<AGROW>
            all_loaded_real_regress_labels = [all_loaded_real_regress_labels; loaded_data.true_fault_severity_actual]; %#ok<AGROW>
        else
            fprintf(2, 'Warning: Skipping malformed file: %s (missing expected fields).\n', filename);
        end
    end
    
    % Need at least 2 samples per class for a stratified split, or 2 total for non-stratified
    if size(all_loaded_real_features, 1) < 2 || length(unique(all_loaded_real_class_labels)) < 2 
        fprintf(2, 'Warning: Not enough diverse real data samples (%d) for a meaningful train/validation split. Falling back to synthetic training.\n', size(all_loaded_real_features, 1));
        use_synthetic_fallback = true;
    else
        % Stratify by class labels to ensure representation in train/validation sets
        cv_real_data = cvpartition(all_loaded_real_class_labels, 'Holdout', 0.2, 'Stratify', true);
        idx_real_train = training(cv_real_data);
        idx_real_val = test(cv_real_data);
        
        training_features_final = all_loaded_real_features(idx_real_train, :);
        training_class_labels_final = all_loaded_real_class_labels(idx_real_train);
        training_regress_labels_final = all_loaded_real_regress_labels(idx_real_train);
        
        validation_features_final = all_loaded_real_features(idx_real_val, :);
        validation_class_labels_final = all_loaded_real_class_labels(idx_real_val);
        validation_regress_labels_final = all_loaded_real_regress_labels(idx_real_val);
        
        fprintf('✅ Successfully loaded and split real data for training (%d samples) and validation (%d samples).\n\n', ...
                size(training_features_final, 1), size(validation_features_final, 1));
        use_synthetic_fallback = false;
    end
else
    fprintf('Real data directory "%s" not found or empty. Generating SYNTHETIC data for training...\n', real_data_source_dir);
    use_synthetic_fallback = true;
end

% --- Synthetic Data Generation (Fallback or Primary for Development) ---
if use_synthetic_fallback
    N_synthetic_samples_per_class = 200; % Number of synthetic samples per fault class
    signal_length_s_synth = ACQUISITION_DURATION_S; % Must match DAQ acquisition duration
    num_points_synth = round(signal_length_s_synth * Fs_real);
    
    % Parameters for synthetic signal variation
    pulse_widths_s = [40e-6, 50e-6, 60e-6]; % Vary pulse width
    pulse_center_fractions = [0.2, 0.3, 0.4, 0.5, 0.6, 0.7]; % Vary pulse start position
    noise_stds = [0.01, 0.03, 0.05, 0.07, 0.1]; % Vary noise level
    fault_severities = [0.1, 0.3, 0.5, 0.7, 0.9]; % Vary fault severity
    
    synthetic_all_features = [];
    synthetic_all_class_labels = categorical([]);
    synthetic_all_regress_labels = [];
    
    fprintf('Generating %d synthetic samples per fault type for TRAINING and internal validation...\n', N_synthetic_samples_per_class);
    for i = 1:N_synthetic_samples_per_class
        for fault_idx = 1:length(fault_types_for_demonstration)
            current_fault_type = fault_types_for_demonstration{fault_idx};
            
            % Randomly select parameters for each synthetic sample
            selected_pulse_width = pulse_widths_s(randi(length(pulse_widths_s)));
            selected_pulse_center_frac = pulse_center_fractions(randi(length(pulse_center_fractions)));
            selected_noise_std = noise_stds(randi(length(noise_stds)));
            selected_severity = fault_severities(randi(length(fault_severities)));
            
            t_synth = (0:num_points_synth-1) / Fs_real;
            pulse_center_idx_synth = round(num_points_synth * selected_pulse_center_frac);
            
            % Base signal (e.g., initial laser pulse or decaying baseline)
            signal_synth = exp(-(t_synth - t_synth(pulse_center_idx_synth)).^2 / (2 * (selected_pulse_width / 4)^2)); % Gaussian pulse
            
            true_severity_synth = selected_severity; % Default, overridden for 'Clean'
            
            % Introduce fault characteristics based on type
            switch current_fault_type
                case 'Clean'
                    true_severity_synth = 0; % Clean has no severity
                    % No additional fault features for clean
                case 'Connector Fault'
                    reflection_coeff = selected_severity * (0.5 + rand*0.3); % Vary reflection magnitude
                    reflection_time_s = signal_length_s_synth * (0.3 + rand*0.4); % Vary fault location
                    reflection_idx = round(reflection_time_s * Fs_real);
                    if reflection_idx > 0 && reflection_idx <= num_points_synth
                        reflection_pulse = reflection_coeff * exp(-(t_synth - t_synth(reflection_idx)).^2 / (2 * (selected_pulse_width / 8)^2));
                        signal_synth = signal_synth + reflection_pulse;
                    end
                case 'Fiber Break'
                    reflection_coeff = selected_severity * (0.7 + rand*0.2); % Stronger reflection
                    reflection_time_s = signal_length_s_synth * (0.3 + rand*0.4); % Vary fault location
                    reflection_idx = round(reflection_time_s * Fs_real);
                    if reflection_idx > 0 && reflection_idx <= num_points_synth
                        reflection_pulse = reflection_coeff * exp(-(t_synth - t_synth(reflection_idx)).^2 / (2 * (selected_pulse_width / 8)^2));
                        signal_synth = signal_synth + reflection_pulse;
                        % Sharp drop in signal level after the break
                        signal_synth(reflection_idx:end) = signal_synth(reflection_idx:end) * (1 - (selected_severity * 0.7));
                    end
                case 'Bend Loss'
                    loss_factor = selected_severity * (0.3 + rand*0.3); % Vary loss magnitude
                    loss_start_time_s = signal_length_s_synth * (0.2 + rand*0.5); % Vary start of loss
                    loss_start_idx = round(loss_start_time_s * Fs_real);
                    if loss_start_idx > 0 && loss_start_idx <= num_points_synth
                        attenuation_profile = ones(1, num_points_synth);
                        % Gradual attenuation profile
                        attenuation_profile(loss_start_idx:end) = 1 - loss_factor * (1:length(loss_start_idx:num_points_synth)) / (num_points_synth - loss_start_idx + 1);
                        signal_synth = signal_synth .* attenuation_profile;
                    end
            end
            
            % Remove DC offset and normalize amplitude of the base signal before adding final noise
            signal_synth = signal_synth - mean(signal_synth);
            max_amp_synth = max(abs(signal_synth));
            if max_amp_synth > 1e-6; signal_synth = signal_synth / max_amp_synth; end
            
            % Add final noise
            signal_with_noise_synth = signal_synth + selected_noise_std * randn(1, num_points_synth);
            
            % IMPORTANT: extract_features.m now returns 20 features.
            features_synth = extract_features(signal_with_noise_synth, Fs_real);
            
            synthetic_all_features = [synthetic_all_features; features_synth]; %#ok<AGROW>
            synthetic_all_class_labels = [synthetic_all_class_labels; categorical({current_fault_type})]; %#ok<AGROW>
            synthetic_all_regress_labels = [synthetic_all_regress_labels; true_severity_synth]; %#ok<AGROW>
        end
    end
    
    % Split synthetic data into training and validation sets
    cv_synthetic = cvpartition(synthetic_all_class_labels, 'Holdout', 0.2, 'Stratify', true);
    idx_synth_train = training(cv_synthetic);
    idx_synth_val = test(cv_synthetic);
    
    training_features_final = synthetic_all_features(idx_synth_train, :);
    training_class_labels_final = synthetic_all_class_labels(idx_synth_train);
    training_regress_labels_final = synthetic_all_regress_labels(idx_synth_train);
    
    validation_features_final = synthetic_all_features(idx_synth_val, :);
    validation_class_labels_final = synthetic_all_class_labels(idx_synth_val);
    validation_regress_labels_final = synthetic_all_regress_labels(idx_synth_val);
    
    fprintf('✅ Generated and split synthetic data for training (%d samples) and validation (%d samples).\n\n', ...
            size(training_features_final, 1), size(validation_features_final, 1));
end

% --- 3. Train Fault Classification, Severity Regression, and Anomaly Detection Models ---
fprintf('\n--- Training ML Models ---\n');
fprintf('Using %d samples for training and %d samples for validation.\n', ...
    size(training_features_final, 1), size(validation_features_final, 1));

% Call train_and_evaluate_models.m with updated outputs to capture scaling parameters.
% The 'training_features_mean' and 'training_features_std' are crucial for
% correctly scaling live data before prediction.
[faultClassifier, severityRegressor, anomalyDetector, fault_types_map, classification_metrics, regression_metrics, training_features_mean, training_features_std] = train_and_evaluate_models(...
    Fs_real, ...
    training_features_final, training_class_labels_final, training_regress_labels_final, ...
    validation_features_final, validation_class_labels_final, validation_regress_labels_final);

fprintf('Models trained and evaluated successfully.\n');

% --- Display Detailed Model Evaluation Metrics ---
fprintf('\n--- Detailed Model Evaluation Metrics (on Validation Set) ---\n');
fprintf('Classification Accuracy: %.2f%%\n', classification_metrics.accuracy * 100);
fprintf('Classification Precision (Macro Avg): %.2f\n', classification_metrics.precision);
fprintf('Classification Recall (Macro Avg): %.2f\n', classification_metrics.recall);
fprintf('Classification F1-Score (Macro Avg): %.2f\n', classification_metrics.f1_score);
fprintf('Confusion Matrix:\n');
disp(classification_metrics.confusion_matrix);
fprintf('Regression RMSE: %.4f\n', regression_metrics.RMSE);
fprintf('Regression MAE: %.4f\n', regression_metrics.MAE);
fprintf('Regression R-squared: %.4f\n', regression_metrics.R2);
fprintf('-------------------------------------------------------------\n');

% --- 4. Live Fault Acquisition & Analysis Loop ---
fprintf('\nStarting live data acquisition and fault analysis...\n\n');
captured_real_signals = struct('type', {}, 'severity', {}, 'signal', {});
capture_count = 0;
max_captures_for_plot = 5; % Max unique signals to capture for plotting
total_acquired_signals = 0;
total_detected_faults = 0;
correct_classifications = 0;
total_severity_errors = []; % For calculating RMSE of severity predictions

% Define figure handles for live plotting (for easy closing later)
h_fig_signal = [];
h_fig_derivative = [];

% --- Optional: App Designer Dashboard Integration ---
% If you are building an App Designer dashboard, this live loop might be
% integrated into the app's button callbacks. The UI would replace these
% fprintf statements with real-time displays.
% You would pass data to your app's UI components here.
% E.g., app.updateSignalPlot(processed_signal); app.updateMap(detected_distance_m, predicted_fault_type);
% ---------------------------------------------------

for iteration = 1:NUM_ITERATIONS
    fprintf('--- Iteration %d ---\n', iteration);
    
    % Randomly suggest a fault type for the user to physically introduce
    suggested_fault_type = fault_types_for_demonstration{randi(length(fault_types_for_demonstration))};
    fprintf('>> Please physically introduce a "%s" type fault for this test.\n', suggested_fault_type);
    fprintf('>> Ensure your laser pulse is ready and DAQ is connected.\n');
    input('Press Enter to start DAQ acquisition...'); % User prompt to introduce fault
    
    % Acquire data from DAQ
    daq_signal_data = s.startForeground();
    total_acquired_signals = total_acquired_signals + 1;
    fprintf('✅ Data acquired from DAQ.\n');
    
    % --- Pre-processing & Filtering Pipeline ---
    t_plot = (0:length(daq_signal_data)-1) / Fs_real; % Time vector for plotting
    
    % 4.1 Remove DC offset
    daq_signal_data_processed = daq_signal_data - mean(daq_signal_data);
    
    % 4.2 Normalize peak amplitude
    max_amp = max(abs(daq_signal_data_processed));
    if max_amp > 1e-6 % Avoid division by zero for flat signals
        daq_signal_data_normalized = daq_signal_data_processed / max_amp; 
    else
        daq_signal_data_normalized = daq_signal_data_processed;
    end
    
    % 4.3 Median Filtering
    filtered_signal_median = medfilt1(daq_signal_data_normalized, MEDIAN_FILTER_WINDOW_SIZE);
    
    % 4.4 Low-Pass Filtering
    [b, a] = butter(LOWPASS_FILTER_ORDER, LOWPASS_CUTOFF_FREQ_HZ / (Fs_real/2), 'low');
    processed_signal = filtfilt(b, a, filtered_signal_median);
    
    % --- LIVE PLOTS FOR THRESHOLD TUNING (Temporary, for debugging) ---
    % Plot Processed Signal for Peak Threshold Tuning
    if isempty(h_fig_signal) || ~isvalid(h_fig_signal)
        h_fig_signal = figure('Name', 'Live Processed Signal for Peak Threshold Tuning');
    else
        figure(h_fig_signal); % Make active
    end
    clf; % Clear current figure for new plot
    plot(t_plot, processed_signal, 'b', 'LineWidth', 1.5);
    hold on;
    yline(FAULT_DETECTION_PEAK_THRESHOLD, 'r--', 'LineWidth', 1.5, 'Label', 'Peak Threshold');
    title(sprintf('Iteration %d: Processed Signal - Tune Peak Threshold (Current: %.2f)', iteration, FAULT_DETECTION_PEAK_THRESHOLD));
    xlabel('Time (s)');
    ylabel('Normalized Amplitude');
    grid on;
    hold off;
    
    % Plot Negative Derivative for Slope Threshold Tuning
    signal_derivative_for_plot = [0, diff(processed_signal)]; % Calculate derivative
    if isempty(h_fig_derivative) || ~isvalid(h_fig_derivative)
        h_fig_derivative = figure('Name', 'Live Signal Derivative for Slope Threshold Tuning');
    else
        figure(h_fig_derivative); % Make active
    end
    clf; % Clear current figure for new plot
    plot(t_plot, -signal_derivative_for_plot, 'b', 'LineWidth', 1.5); % Plot negative derivative for positive spikes
    hold on;
    yline(FAULT_DETECTION_SLOPE_THRESHOLD, 'g--', 'LineWidth', 1.5, 'Label', 'Slope Threshold');
    title(sprintf('Iteration %d: Negative Derivative - Tune Slope Threshold (Current: %.2f)', iteration, FAULT_DETECTION_SLOPE_THRESHOLD));
    xlabel('Time (s)');
    ylabel('Negative Derivative Amplitude');
    grid on;
    hold off;
    % --- END LIVE PLOTS ---
    
    % --- MANUAL INPUT FOR REAL GROUND TRUTH & DATA SAVING ---
    fprintf('\n--- RECORDING REAL GROUND TRUTH FOR THIS ACQUISITION ---\n');
    true_fault_type_actual_str = '';
    while ~ismember(true_fault_type_actual_str, fault_types_for_demonstration)
        true_fault_type_actual_str = input(sprintf('Enter ACTUAL fault type (%s): ', strjoin(fault_types_for_demonstration, ', ')), 's');
        if ~ismember(true_fault_type_actual_str, fault_types_for_demonstration)
            fprintf(2, 'Invalid fault type. Please choose from: %s\n', strjoin(fault_types_for_demonstration, ', '));
        end
    end
    true_fault_type_actual = true_fault_type_actual_str;
    
    if strcmp(true_fault_type_actual, 'Clean')
        true_fault_severity_actual = 0;
        true_fault_location_m_actual = 0;
    else
        valid_severity = false;
        while ~valid_severity
            true_fault_severity_actual = input('Enter ACTUAL fault severity (0-1, e.g., 0.75): ');
            if isscalar(true_fault_severity_actual) && true_fault_severity_actual >= 0 && true_fault_severity_actual <= 1
                valid_severity = true;
            else
                fprintf(2, 'Invalid severity. Please enter a number between 0 and 1.\n');
            end
        end
        valid_location = false;
        while ~valid_location
            true_fault_location_m_actual = input('Enter ACTUAL fault location in meters (e.g., 5000): ');
            if isscalar(true_fault_location_m_actual) && true_fault_location_m_actual >= 0 && true_fault_location_m_actual <= (FIBER_LENGTH_KM * 1000)
                valid_location = true;
            else
                fprintf(2, 'Invalid location. Please enter a non-negative number within fiber length (%.0f m).\n', FIBER_LENGTH_KM * 1000);
            end
        end
    end
    
    % Create directory if it doesn't exist
    if ~exist(real_data_source_dir, 'dir')
        mkdir(real_data_source_dir);
    end
    timestamp_str = datestr(datetime('now'), 'yyyymmdd_HHMMSS');
    filename = fullfile(real_data_source_dir, sprintf('%s_%s_S%.2f_L%.0fm.mat', ...
        timestamp_str, strrep(true_fault_type_actual, ' ', '_'), true_fault_severity_actual, true_fault_location_m_actual));
    
    save(filename, 'daq_signal_data', 'true_fault_type_actual', 'true_fault_severity_actual', 'true_fault_location_m_actual', 'Fs_real', 'ACQUISITION_DURATION_S');
    fprintf('Data saved to: %s\n', filename);
    fprintf('--------------------------------------------------\n\n');
    current_timestamp = datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss');
    fprintf('[%s] Actual Introduced Fault (Your Recorded Ground Truth): Type: %s, Severity: %.2f, Location: %.2fm\n', ...
            datestr(current_timestamp, 'yyyy-mm-ddTHH:MM:SS'), ...
            true_fault_type_actual, true_fault_severity_actual, true_fault_location_m_actual);
    
    if capture_count < max_captures_for_plot
        is_captured = false;
        for k = 1:length(captured_real_signals)
            if strcmp(captured_real_signals(k).type, true_fault_type_actual)
                if strcmp(true_fault_type_actual, 'Clean') || abs(captured_real_signals(k).severity - true_fault_severity_actual) < 0.15 % Tolerance for "similar" severity
                    is_captured = true; break;
                end
            end
        end
        if ~is_captured
            capture_count = capture_count + 1;
            captured_real_signals(capture_count).type = true_fault_type_actual;
            captured_real_signals(capture_count).severity = true_fault_severity_actual;
            captured_real_signals(capture_count).signal = daq_signal_data_normalized;
            fprintf('Captured Real Signal for Plotting: Type: %s, Severity: %.2f (Slot %d/%d)\n', ...
                    true_fault_type_actual, true_fault_severity_actual, capture_count, max_captures_for_plot);
        end
    end
    
    % --- Fault Detection ---
    % Calls the updated detect_faults.m which has enhanced logic for consolidation.
    [detected_fault_locs, ~] = detect_faults(processed_signal, FAULT_DETECTION_PEAK_THRESHOLD, FAULT_DETECTION_SLOPE_THRESHOLD, Fs_real);
    
    if ~isempty(detected_fault_locs)
        fprintf('  -> Fault(s) detected at location(s) corresponding to indices: %s\n', mat2str(detected_fault_locs));
        
        for i = 1:length(detected_fault_locs)
            % For simplicity, assuming one dominant fault per detection for classification/regression
            % In a multi-fault scenario, you'd need more advanced segmentation and individual processing
            fault_idx = detected_fault_locs(i);
            % Define a window around the detected fault for feature extraction
            window_size_samples = round(0.001 * Fs_real); % Example: 1ms window around the fault
            start_idx = max(1, fault_idx - window_size_samples);
            end_idx = min(length(processed_signal), fault_idx + window_size_samples);
            
            fault_segment = processed_signal(start_idx:end_idx);
            
            if isempty(fault_segment) || length(fault_segment) < 2 
                fprintf(2, 'Warning: Fault segment at index %d is too short or empty for feature extraction. Skipping this detection.\n', fault_idx);
                continue;
            end
            
            % --- Feature Extraction and Scaling for Live Data ---
            % Call the updated extract_features.m (which now returns 20 features)
            features = extract_features(fault_segment, Fs_real);
            
            % IMPORTANT: Scale live features using the mean and std from the TRAINING data!
            % This ensures consistency with how the ML models were trained.
            % Check for features with zero standard deviation to prevent NaNs/Infs
            scaled_live_features = (features - training_features_mean) ./ training_features_std;
            scaled_live_features(isnan(scaled_live_features)) = 0; % Replace NaN with 0 or mean
            scaled_live_features(isinf(scaled_live_features)) = 0; % Replace Inf with 0 or max/min appropriate value
            
            % --- CHCAS (Cascaded Hybrid Classifier-Anomaly System) Logic ---
            % Step 1: Classifier Prediction
            [predicted_class_idx, classification_scores] = predict(faultClassifier, scaled_live_features);
            predicted_fault_type_classifier = fault_types_map{predicted_class_idx}; % Map index to human-readable type
            
            % Step 2: Anomaly Detector Score
            anomaly_score = predict(anomalyDetector, scaled_live_features);
            
            % Step 3: CHCAS Decision Logic
            final_reported_type = '';
            final_reported_severity_level = ''; % e.g., 'Normal', 'Minor', 'Moderate', 'Severe'
            final_reported_severity_value = 0;  % Numerical severity (0-1)
            
            if strcmp(predicted_fault_type_classifier, 'Clean')
                % Classifier says 'Clean' -> Defer to Anomaly Detector
                if anomaly_score <= CHCAS_NORMAL_THRESHOLD
                    final_reported_type = 'No Fault';
                    final_reported_severity_level = 'Normal';
                    final_reported_severity_value = 0;
                    fprintf('  -> CHCAS: Confirmed No Fault (Classifier: Clean, Anomaly Score: %.4f).\n', anomaly_score);
                else % Anomaly detected, even if classifier says Clean
                    final_reported_type = 'Unknown Anomaly';
                    % Map anomaly score to severity
                    if anomaly_score > CHCAS_SEVERITY_THRESHOLD_2
                        final_reported_severity_level = 'Severe (Anomaly)';
                    elseif anomaly_score > CHCAS_SEVERITY_THRESHOLD_1
                        final_reported_severity_level = 'Moderate (Anomaly)';
                    else
                        final_reported_severity_level = 'Minor (Anomaly)';
                    end
                    % For unknown anomalies, severity value can be directly from anomaly score or mapped
                    final_reported_severity_value = max(0, min(1, anomaly_score / CHCAS_SEVERITY_THRESHOLD_2)); % Example mapping to 0-1
                    fprintf('  -> CHCAS: Detected Unknown Anomaly (Classifier: Clean, Anomaly Score: %.4f, Severity: %s).\n', anomaly_score, final_reported_severity_level);
                end
            else % Classifier predicts a specific fault type (e.g., 'Fiber Break', 'Bend Loss')
                % Classifier says a specific fault -> Trust classifier type, use regressor for severity
                predicted_severity_regressor = predict(severityRegressor, scaled_live_features);
                predicted_severity_regressor = max(0, min(1, predicted_severity_regressor)); % Ensure bounds 0-1
                
                final_reported_type = predicted_fault_type_classifier;
                final_reported_severity_value = predicted_severity_regressor;
                
                % Map regressor severity to levels
                if predicted_severity_regressor >= 0.7
                    final_reported_severity_level = 'Severe';
                elseif predicted_severity_regressor >= 0.4
                    final_reported_severity_level = 'Moderate';
                else
                    final_reported_severity_level = 'Minor';
                end
                
                % Optional: Re-evaluate if anomaly score contradicts high confidence classification
                % This part could be further refined if anomaly score strongly indicates "normal"
                % while classifier is very confident in a fault. For now, we trust classifier.
                
                fprintf('  -> CHCAS: Classified as %s (Score: %.4f), Regressed Severity: %.2f (%s).\n', ...
                    final_reported_type, max(classification_scores), final_reported_severity_value, final_reported_severity_level);
            end
            
            % --- Location Mapping (using true_fault_location_m_actual for simplicity in demo) ---
            % In a real system, you'd calculate location from reflection time-of-flight.
            % For this demo, let's use a dummy calculation or the recorded actual.
            % Example: simple linear mapping based on time index (replace with your ToF logic)
            detected_distance_m = (fault_idx / length(processed_signal)) * (FIBER_LENGTH_KM * 1000);
            
            % --- Geographical Coordinates Mapping ---
            % This uses a simplified flat Earth approximation. For precise results over long distances,
            % you'd use geodesic calculations (e.g., 'distVincenty', 'reckon' from Mapping Toolbox).
            % Assuming fiber runs in a straight line from START_LAT, START_LON at FIBER_BEARING_DEG
            [fault_lat, fault_lon] = reckon(START_LAT, START_LON, detected_distance_m, FIBER_BEARING_DEG);
            
            fprintf('  -> Estimated Fault Location: %.2f meters (%.4f, %.4f Lat/Lon)\n', detected_distance_m, fault_lat, fault_lon);
            
            % --- Email Notification Logic (based on CHCAS output) ---
            if final_reported_severity_value >= EMAIL_NOTIFICATION_THRESHOLD
                fprintf('  -> Sending email notification: %s (Severity: %s, Value: %.2f) at %.2fm.\n', ...
                    final_reported_type, final_reported_severity_level, final_reported_severity_value, detected_distance_m);
                % Example: send_notification_email('recipient@example.com', final_reported_type, final_reported_severity_level, detected_distance_m, current_timestamp);
            else
                fprintf('  -> Severity (%.2f) below email threshold (%.2f). No email sent.\n', final_reported_severity_value, EMAIL_NOTIFICATION_THRESHOLD);
            end
            
            % --- Live Metrics Tracking ---
            % This part needs careful thought for live evaluation against ground truth.
            % In a live system, you don't have true_fault_type_actual readily available.
            % For this demo, we'll use it to evaluate prediction accuracy.
            if strcmp(final_reported_type, true_fault_type_actual) || (strcmp(final_reported_type, 'No Fault') && strcmp(true_fault_type_actual, 'Clean'))
                correct_classifications = correct_classifications + 1;
            else
                fprintf(2, '  -> MISCLASSIFICATION: Predicted %s (Severity %s) vs. Actual %s (Severity %.2f)\n', ...
                    final_reported_type, final_reported_severity_level, true_fault_type_actual, true_fault_severity_actual);
            end
            
            % Only track severity error for known fault types (where severity is defined 0-1)
            if ~strcmp(true_fault_type_actual, 'Clean') && ~strcmp(final_reported_type, 'Unknown Anomaly') && ~strcmp(final_reported_type, 'No Fault')
                total_severity_errors = [total_severity_errors; (final_reported_severity_value - true_fault_severity_actual)^2]; %#ok<AGROW>
            end
        end % End for each detected fault location
    else
        % No fault detected by the initial peak/slope method
        % Now, we still run the anomaly detector on the *whole signal* if no specific fault peaks were found.
        % This is a crucial CHCAS extension for subtle anomalies.
        % For simplicity, we can extract features from the whole signal if no local peak was found.
        % A more sophisticated approach might involve sliding windows for anomaly detection.
        
        fprintf('  -> No explicit fault peak/slope detected by primary method.\n');
        
        if ~isempty(anomalyDetector) && ~isa(anomalyDetector, 'double')
             % Extract features from the whole processed signal for anomaly detection
            features_full_signal = extract_features(processed_signal, Fs_real);
            scaled_features_full_signal = (features_full_signal - training_features_mean) ./ training_features_std;
            scaled_features_full_signal(isnan(scaled_features_full_signal)) = 0;
            scaled_features_full_signal(isinf(scaled_features_full_signal)) = 0;
            
            anomaly_score_full_signal = predict(anomalyDetector, scaled_features_full_signal);
            
            if anomaly_score_full_signal > CHCAS_NORMAL_THRESHOLD % Only if it's above the clean threshold
                % It's an anomaly, but the classifier couldn't identify a type
                final_reported_type = 'Subtle Unknown Anomaly (No Peak)';
                if anomaly_score_full_signal > CHCAS_SEVERITY_THRESHOLD_2
                    final_reported_severity_level = 'Severe (Anomaly)';
                elseif anomaly_score_full_signal > CHCAS_SEVERITY_THRESHOLD_1
                    final_reported_severity_level = 'Moderate (Anomaly)';
                else
                    final_reported_severity_level = 'Minor (Anomaly)';
                end
                final_reported_severity_value = max(0, min(1, anomaly_score_full_signal / CHCAS_SEVERITY_THRESHOLD_2));
                
                fprintf('  -> CHCAS: Detected %s (Anomaly Score: %.4f) for whole signal.\n', ...
                    final_reported_type, anomaly_score_full_signal);
                
                % For subtle anomalies, we don't have a precise location from detect_faults.
                % You might report 'Whole Fiber' or 'Unlocalized Anomaly'.
                detected_distance_m = NaN; % No specific localized distance
                
                if final_reported_severity_value >= EMAIL_NOTIFICATION_THRESHOLD
                    fprintf('  -> Sending email notification for subtle anomaly: %s (Severity: %s, Value: %.2f).\n', ...
                        final_reported_type, final_reported_severity_level, final_reported_severity_value);
                else
                    fprintf('  -> Subtle anomaly severity (%.2f) below email threshold (%.2f). No email sent.\n', final_reported_severity_value, EMAIL_NOTIFICATION_THRESHOLD);
                end
            else
                 fprintf('  -> CHCAS: Confirmed No Fault (Anomaly Score: %.4f for whole signal).\n', anomaly_score_full_signal);
                 % If actual was a fault, but nothing detected, it's a False Negative
                 if ~strcmp(true_fault_type_actual, 'Clean')
                     fprintf(2, '  -> FALSE NEGATIVE: Actual %s but no fault/anomaly detected.\n', true_fault_type_actual);
                 end
            end
        else
            fprintf('  -> No anomaly detector available. Assuming no fault/anomaly if no peak detected.\n');
            if ~strcmp(true_fault_type_actual, 'Clean')
                fprintf(2, '  -> FALSE NEGATIVE: Actual %s but no fault detected (Anomaly detector not active).\n', true_fault_type_actual);
            end
        end
    end
    
    % --- End of Iteration Summary ---
    fprintf('--- End of Iteration %d Summary ---\n', iteration);
    fprintf('  Total Signals Acquired: %d\n', total_acquired_signals);
    fprintf('  Total Faults Localized (by peak/slope): %d\n', total_detected_faults);
    fprintf('--------------------------------------\n\n');
end % End of live acquisition loop

% --- Final Summary of Live Run (Post-loop) ---
fprintf('\n--- Live Run Final Summary ---\n');
fprintf('Total Acquisition Iterations: %d\n', NUM_ITERATIONS);
fprintf('Overall Classification Accuracy (against recorded ground truth): %.2f%%\n', (correct_classifications / total_detected_faults) * 100);
if ~isempty(total_severity_errors)
    final_rmse_severity = sqrt(mean(total_severity_errors));
    fprintf('Overall Severity Regression RMSE (for non-Clean/Unknown): %.4f\n', final_rmse_severity);
else
    fprintf('No non-Clean/Unknown faults detected to calculate severity RMSE.\n');
end

% --- Plot Captured Real Signals ---
if ~isempty(captured_real_signals)
    fprintf('\n--- Plotting Captured Real Fault Signals ---\n');
    plot_idx = 1;
    figure('Name', 'Captured Real Signals');
    num_plots = min(length(captured_real_signals), 6); % Plot up to 6 unique captures
    for k = 1:num_plots
        subplot(ceil(num_plots/2), 2, k);
        plot(captured_real_signals(plot_idx).signal, 'LineWidth', 1.2);
        title(sprintf('%s (Sev: %.2f)', captured_real_signals(plot_idx).type, captured_real_signals(plot_idx).severity));
        xlabel('Sample Index');
        ylabel('Normalized Amplitude');
        grid on;
        plot_idx = plot_idx + 1;
    end
    sgtitle('Sample of Captured Real Fault Signals');
end

fprintf('\nFiber Optic Fault Detection System Simulation Complete.\n');

% Close DAQ session if still open
if exist('s', 'var') && isvalid(s)
    s.release();
    fprintf('DAQ session released.\n');
end

end % End of main function

% --- Helper Functions (Expected to be in 'helpers' subfolder) ---
% function features = extract_features(signal, Fs)
% function [detected_locs, feature_flags] = detect_faults(processed_signal, peak_thresh, slope_thresh, Fs)
% function [classifier, regressor, anomaly_detector, fault_map, class_metrics, regress_metrics, mean_features, std_features] = train_and_evaluate_models(...)
% function send_notification_email(...) % Placeholder if you integrate email sending
% -----------------------------------------------------------------