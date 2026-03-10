function [detected_fault_locs, detected_fault_values] = detect_faults(...
    signal, peak_threshold_static, prominence_threshold, min_peak_distance_samples, Fs, max_num_faults)

signal = signal(:)';

detected_fault_locs = [];
detected_fault_values = [];

BLIND_ZONE_DURATION_SEC = 20e-6;
BLIND_ZONE_SAMPLES = round(BLIND_ZONE_DURATION_SEC * Fs);

if BLIND_ZONE_SAMPLES >= length(signal)
    warning('Blind zone duration is too long for the signal length. No signal left to analyze in detect_faults.');
    return;
end

signal(1:BLIND_ZONE_SAMPLES) = 0;

if min_peak_distance_samples >= length(signal) - 1
    warning('MinPeakDistance (%.2f) is too large for signal length (%d) in detect_faults. Adjusting to max allowed.', ...
        min_peak_distance_samples, length(signal));
    min_peak_distance_samples = max(1, length(signal) - 2);
end

min_peak_distance_samples = round(min_peak_distance_samples);
if min_peak_distance_samples < 1
    min_peak_distance_samples = 1;
end

[pks, locs, ~, proms] = findpeaks(signal, ...
    'MinPeakHeight', peak_threshold_static, ...
    'MinPeakProminence', prominence_threshold, ...
    'MinPeakDistance', min_peak_distance_samples);

if isempty(locs)
    return;
end

valid_locs_indices = (locs >= 1 & locs <= length(signal));
detected_fault_locs = locs(valid_locs_indices);

detected_fault_locs = sort(detected_fault_locs, 'ascend');

if ~isempty(detected_fault_locs)
    detected_fault_values = signal(detected_fault_locs);
else
    detected_fault_values = [];
end

detected_fault_locs = detected_fault_locs(:);
detected_fault_values = detected_fault_values(:);

end
