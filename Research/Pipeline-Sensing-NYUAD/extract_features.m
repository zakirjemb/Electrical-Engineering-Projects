function features = extract_features1(signal_segment, Fs)
NUM_FEATURES = 30;
if isempty(signal_segment) || length(signal_segment) < 2
    features = nan(1, NUM_FEATURES);
    warning('Signal segment too short or empty for feature extraction. Returning NaNs.');
    return;
end
signal_segment = signal_segment(:);
f1_max_amp = max(signal_segment);
f2_min_amp = min(signal_segment);
f3_peak2peak = f1_max_amp - f2_min_amp;
f4_range = range(signal_segment);
f5_abs_sum = sum(abs(signal_segment));
[pos_peaks, pos_locs] = findpeaks(signal_segment);
[neg_peaks, neg_locs] = findpeaks(-signal_segment);
f6_num_pos_peaks = length(pos_peaks);
f7_num_neg_peaks = length(neg_peaks);
f8_avg_pos_peak_height = mean(pos_peaks);
f9_avg_neg_peak_height = mean(-neg_peaks);
if isempty(pos_peaks), f8_avg_pos_peak_height = 0; end
if isempty(neg_peaks), f9_avg_neg_peak_height = 0; end
f10_rms = rms(signal_segment);
f11_energy = sum(signal_segment.^2);
f12_power = mean(signal_segment.^2);
f13_mean = mean(signal_segment);
f14_median = median(signal_segment);
f15_std_dev = std(signal_segment);
f16_variance = var(signal_segment);
f17_skewness = skewness(signal_segment);
f18_kurtosis = kurtosis(signal_segment);
L = length(signal_segment);
Y = fft(signal_segment);
P2 = abs(Y / L);
P1 = P2(1:floor(L/2)+1);
P1(2:end-1) = 2*P1(2:end-1);
f = Fs*(0:(L/2))/L;
low_band_idx = f <= Fs/8;
high_band_idx = f >= Fs/4 & f <= Fs/2;
f19_power_low_band = sum(P1(low_band_idx).^2);
f20_power_high_band = sum(P1(high_band_idx).^2);
[~, idx] = max(P1(2:end));
f21_dominant_freq = f(idx + 1);
f22_waveform_length = sum(abs(diff(signal_segment)));
f23_zero_crossings = sum(abs(diff(sign(signal_segment))));
f24_mean_abs_dev = mean(abs(signal_segment - mean(signal_segment)));
f25_approx_entropy = approximateEntropy(signal_segment);
try
    [C, L_wavelet] = wavedec(signal_segment, 3, 'db4');
    A3 = appcoef(C, L_wavelet, 'db4', 3);
    D1 = detcoef(C, L_wavelet, 1);
    D2 = detcoef(C, L_wavelet, 2);
    D3 = detcoef(C, L_wavelet, 3);
    f26_energy_A3 = sum(A3.^2);
    f27_energy_D1 = sum(D1.^2);
    f28_energy_D2 = sum(D2.^2);
    f29_energy_D3 = sum(D3.^2);
    total_energy_wavelet = sum(signal_segment.^2);
    if total_energy_wavelet > 0
        f30_energy_ratio_D1_total = f27_energy_D1 / total_energy_wavelet;
    else
        f30_energy_ratio_D1_total = 0;
    end
catch
    warning('Wavelet feature extraction failed. Returning NaNs for wavelet features.');
    f26_energy_A3 = NaN;
    f27_energy_D1 = NaN;
    f28_energy_D2 = NaN;
    f29_energy_D3 = NaN;
    f30_energy_ratio_D1_total = NaN;
end
if ~isscalar(f19_power_low_band), f19_power_low_band = f19_power_low_band(1); end
if ~isscalar(f20_power_high_band), f20_power_high_band = f20_power_high_band(1); end
if ~isscalar(f21_dominant_freq), f21_dominant_freq = f21_dominant_freq(1); end
if ~isscalar(f22_waveform_length), f22_waveform_length = f22_waveform_length(1); end
if ~isscalar(f23_zero_crossings), f23_zero_crossings = f23_zero_crossings(1); end
if ~isscalar(f24_mean_abs_dev), f24_mean_abs_dev = f24_mean_abs_dev(1); end
if ~isscalar(f25_approx_entropy), f25_approx_entropy = f25_approx_entropy(1); end
if ~isscalar(f26_energy_A3), f26_energy_A3 = f26_energy_A3(1); end
if ~isscalar(f27_energy_D1), f27_energy_D1 = f27_energy_D1(1); end
if ~isscalar(f28_energy_D2), f28_energy_D2 = f28_energy_D2(1); end
if ~isscalar(f29_energy_D3), f29_energy_D3 = f29_energy_D3(1); end
if ~isscalar(f30_energy_ratio_D1_total), f30_energy_ratio_D1_total = f30_energy_ratio_D1_total(1); end
original_25_features = [f1_max_amp, f2_min_amp, f3_peak2peak, f4_range, f5_abs_sum, ...
                        f6_num_pos_peaks, f7_num_neg_peaks, f8_avg_pos_peak_height, f9_avg_neg_peak_height, ...
                        f10_rms, f11_energy, f12_power, ...
                        f13_mean, f14_median, f15_std_dev, f16_variance, f17_skewness, f18_kurtosis, ...
                        f19_power_low_band, f20_power_high_band, f21_dominant_freq, ...
                        f22_waveform_length, f23_zero_crossings, f24_mean_abs_dev, f25_approx_entropy];
wavelet_features = [f26_energy_A3, f27_energy_D1, f28_energy_D2, f29_energy_D3, f30_energy_ratio_D1_total];
features = [original_25_features, wavelet_features];
function ApEn = approximateEntropy(data)
    N = length(data);
    if N < 2
        ApEn = 0;
        return;
    end
    m = 2;
    r = 0.2 * std(data);
    if r == 0
        ApEn = 0;
        return;
    end
    Cm = zeros(1, N - m + 1);
    Cmp1 = zeros(1, N - m);
    for i = 1:(N - m + 1)
        Xi = data(i : i + m - 1);
        count_m = 0;
        for j = 1:(N - m + 1)
            if i == j, continue; end
            Xj = data(j : j + m - 1);
            if max(abs(Xi - Xj)) <= r
                count_m = count_m + 1;
            end
        end
        Cm(i) = count_m / (N - m);
    end
    for i = 1:(N - m)
        Xi = data(i : i + m);
        count_mp1 = 0;
        for j = 1:(N - m)
            if i == j, continue; end
            Xj = data(j : j + m);
            if max(abs(Xi - Xj)) <= r
                count_mp1 = count_mp1 + 1;
            end
        end
        Cmp1(i) = count_mp1 / (N - m -1);
    end
    Cm(Cm == 0) = eps;
    Cmp1(Cmp1 == 0) = eps;
    phi_m = sum(log(Cm)) / (N - m + 1);
    phi_mp1 = sum(log(Cmp1)) / (N - m);
    ApEn = phi_m - phi_mp1;
end
end
