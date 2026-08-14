function calibrate_DAC_conversion
addpath(genpath('C:\Users\AEP\Desktop\adapt_aep\src\matlab'))

fs = 44100;
tone_burst = generate_tone_burst(fs, 100, 10*1e3, 120);
base_level = calculate_base_level(140);
stimulus = tone_burst.*base_level;

input_channels = [3:8];
output_channels = [1 4];
electrode_idx = 3:6;
hydrophone_idx = 1;
electrode_voltage_scaling_factor_V = 5.1045;
hydrophone_voltage_scaling_factor_V = 5.1045;

%% Init DAC
% Reset playrec if it is already initialized to start fresh
if playrec('isInitialised')
    playrec('reset');
end

% Get a list of connected devices
my_devices = playrec('getDevices');
if length(my_devices) > 1
    my_devices(2:end) = []; % remove all other devices
end

% Check to make sure that Fireface is online
if ~strcmp(my_devices.name, 'ASIO Fireface USB') % check that this is the only device initizlised
    if isempty(strfind(my_devices.name, 'Fireface'))
        errordlg('The Fireface is not recognized. Is it plugged in? Is it on?');
        error('The Fireface is not recognized. Check to make sure that it is plugged in and turned on');
    end
    if isempty(strfind(my_devices.name, 'ASIO'))
        errordlg('The Fireface is recognized, but it appears an older version of PlayRec was called.');
        error('The Fireface is recognized, but it appears an older version of PlayRec was called.');
    end
end

% Initialize!
playrec('init', fs, 0, 0, 8, 8);

%% Rip it
[rec_data_mV] = present_sound(stimulus, ...
    input_channels, output_channels, ...
    electrode_idx, hydrophone_idx, ...
    electrode_voltage_scaling_factor_V, ...
    hydrophone_voltage_scaling_factor_V);

%% Get hydrophone signals
hydro_sigs = squeeze(rec_data_mV(:,:,1));
my_rms = rms(hydro_sigs);
correction = 110/my_rms

