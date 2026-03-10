%% Doppler Radar Speed Measurement using Arduino + MATLAB
% Author: Zakir & ChatGPT (Boss Engineering Team 😎)
clear; clc; close all;

% -------- USER SETTINGS --------
port = "COM3";           % <-- Change to your Arduino port
baud = 115200;           % Must match Arduino Serial.begin()
Fs = 1000;               % Sampling frequency (Hz)
windowTime = 1;          % Time window for FFT (seconds)
fc = 10.525e9;           % HB100 carrier frequency (Hz)
c = 3e8;                 % Speed of light (m/s)
% --------------------------------

samplesPerWindow = Fs * windowTime;
s = serialport(port, baud);
flush(s);
disp("📡 Connected to Arduino. Starting data capture...");

timeBuffer = zeros(1, samplesPerWindow);
i = 1;

figure('Name','Radar Doppler Speed Detection','NumberTitle','off');

while true
    % --- Read data from serial ---
    if s.NumBytesAvailable > 0
        line = readline(s);
        val = str2double(line);
        if ~isnan(val)
            timeBuffer(i) = val;
            i = i + 1;
        end
    end

    % --- Once buffer is filled, process ---
    if i > samplesPerWindow
        i = 1;
        sig = timeBuffer - mean(timeBuffer); % remove DC
        
        % Time axis
        t = (0:length(sig)-1) / Fs;
        
        % FFT
        N = length(sig);
        Y = fft(sig .* hann(N)');
        f = (0:N-1)*(Fs/N);
        P2 = abs(Y/N);
        P1 = P2(1:floor(N/2));
        f1 = f(1:floor(N/2));
        
        % Find Doppler peak frequency
        [~, idx] = max(P1(2:end));
        fd = f1(idx+1); % skip DC bin
        
        % Calculate speed
        v = (fd * c) / (2 * fc);
        v_kmh = v * 3.6;
        
        % --- Plot ---
        subplot(2,1,1);
        plot(t, sig, 'b');
        xlabel('Time (s)');
        ylabel('Amplitude');
        title('Time-Domain Signal');
        grid on;
        
        subplot(2,1,2);
        plot(f1, P1, 'r');
        xlabel('Frequency (Hz)');
        ylabel('|FFT|');
        title(sprintf('FFT Spectrum — f_d = %.2f Hz → v = %.2f m/s (%.2f km/h)', fd, v, v_kmh));
        grid on;
        xlim([0 500]); % adjust for your expected range
        
        drawnow;
    end
end
