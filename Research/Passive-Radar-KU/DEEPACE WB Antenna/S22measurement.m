clear;
clc;
close;
data = readtable('SAV-QR_Port2.csv');

freq = data.Freq_Hz;
s22_db = data.S22_DB;
s22_deg = data.S22_DEG;

figure;
subplot(2,1,1);
plot(freq, s22_db);
xlabel('Frequency (Hz)');
ylabel('S22 (dB)');
title('S22 Magnitude');

subplot(2,1,2);
plot(freq, s22_deg);
xlabel('Frequency (Hz)');
ylabel('S22 Phase (Degrees)');
title('S22 Phase');
