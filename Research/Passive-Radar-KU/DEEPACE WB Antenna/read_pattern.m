
clear;
clc;
close;

curr_freq = '9p0GHz';
filename_config = horzcat('config.txt');
config_data = readmatrix(filename_config);

step=config_data(8,2);
numscan=config_data(10,2);

filename = horzcat('Eplane_', curr_freq, '.txt');
data = readmatrix(filename);

scan_pt = data(:,1);
Pwr = data(:,3);
degrees=0:step:(numscan)*step;

figure (1)
plot(scan_pt, Pwr)
xlabel("Scan Points")
ylabel("Power (dBm)")

figure (2)
plot(degrees, Pwr)
xlabel("Scan Angle (degrees)")
ylabel("Power (dBm)")

%%

rho_data = Pwr;
rho_p1 = rho_data - max(rho_data);
% rho_p2 = rho_p1;
theta = deg2rad(degrees);

figure (3)

p = polarplot(theta,rho_p1);
p(1).LineWidth = 2; p(1).Color = 'black';
% p(2).LineWidth = 2; p(2).Color = 'black';

% legend('Simulation', 'Measurement', 'NumColumns', 1,...
%          'Color', 'none', 'EdgeColor', 'none')

rlim([(min(rho_p1)) 0])
rlim([-20 0]);
ax = gca;
ax.ThetaDir = 'clockwise';
ax.ThetaZeroLocation = 'top';
ax.FontSize = 12;
ax.FontWeight = 'bold';
ax.RAxisLocation = 0;



% theta=degrees;


% r=dgrees*costheta
%% 
Frequency = [1.8, 2.4, 3, 5, 6, 9];
Gain_HPlane = [1.364261014, 1.17639838, 1.99299851, -2.226513994, -3.842601533, -11.39033894];
Gain_EPlane = [1.871661014, 2.28754838, 1.84064851, -3.779613994, -3.286151533, -8.495488943];

figure;

% Subplot (a) - H-Plane
subplot(1, 2, 1);
plot(Frequency, Gain_HPlane, '-o');
xlabel("Frequency (GHz)");
ylabel("Gain (dB)");
title("(a) Gain for H-Plane");
grid on;

% Subplot (b) - E-Plane
subplot(1, 2, 2);
plot(Frequency, Gain_EPlane, '-s');
xlabel("Frequency (GHz)");
ylabel("Gain (dB)");
title("(b) Gain for E-Plane");
grid on;

