cd 'C:\Users\Aoi Hunsaker\OneDrive - UW\Desktop\Matlab tutorial'
% Plot time domain signal
load('aep_response.mat')
figure; 
plot(x_vec,y_vec)
xlabel('Time (s)')
ylabel('Amplitude (\muV)')
title('Time domain signal')

% Indicate stim ON portion
xline(0.077)
xline(0.36)

% Practice indexing
% See how many samples are in y_vec
length(y_vec)
start_idx = 3364;
end_idx = 16051;

% Trim signal
trim_y_vec = y_vec(start_idx:end_idx);
% Colon includes all intermediate idx values

% Plot trim signal
figure;
plot(trim_y_vec)
xlabel('Time (s)')
ylabel('Amplitude (\muV)')
title('Time domain signal (trimmed)')

% Calculate frequency domain signal
[N, x_vec, y_vec] = calc_fft(trim_y_vec,44100);
figure;
plot(x_vec,y_vec)
xlim([0 300])
xlabel('Frequency (Hz)')
ylabel('Amplitude (\muV)')
title('Frequency domain signal')