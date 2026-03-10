
try
    data_table = readtable('analog.xlsx');
    disp('Data loaded successfully.');
catch ME
    if strcmp(ME.identifier, 'MATLAB:readtable:FileNotFound')
        error('File not found. Please check the file name and location.');
    else
        rethrow(ME);
    end
end

% Extract time and amplitude
time = data_table.Time;
signal = data_table.Amplitude;

% --- Step 2: Plot Time Domain Signal ---
Fs = 1 / mean(diff(time));  % Sampling frequency estimate
fprintf('Estimated Sampling Rate: %.2f Hz\n', Fs);

figure;
plot(time, signal);
xlabel('Time (s)');
ylabel('Amplitude (V)');
title('Time-Domain Signal');
grid on;

% --- Step 3: Plot Frequency Domain (FFT) ---
L = length(signal);
Y = fft(signal);

P2 = abs(Y / L);        % Two-sided spectrum
P1 = P2(1:L/2+1);      % Single-sided spectrum
P1(2:end-1) = 2 * P1(2:end-1);

f = Fs * (0:(L/2)) / L; % Frequency vector

figure;
plot(f, P1);
xlabel('Frequency (Hz)');
ylabel('|Amplitude|');
title('Frequency Spectrum (FFT)');
grid on;
