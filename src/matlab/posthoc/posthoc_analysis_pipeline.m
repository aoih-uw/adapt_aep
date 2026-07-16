% Posthoc analysis pipeline
% Initialize
clearvars
addpath(genpath('\\wsl.localhost\ubuntu\home\aoih\adapt_aep\src\matlab'))
base_dir = 'F:\2026\Research\July Midshipman';
cd(base_dir)

subjid = 23;
stim_freq = 100;
stim_amp = [];
my_chans = [2,3,4]; % 2 = 2mm, 3 = 4mm, 4 = subcut
target_freq_range =  3; % for fft bin finding calculations
isubj = 1;

%% Benzo
amp_vec = 140;
stim_type_vec = {'trim'};

% Load data
grand_ex_save = ...
    posthoc_load_my_file(subjid,file_type,stim_freq,stim_amp);

% Plot funfetti
posthoc_funfetti

%% Mixed stimuli
amp_vec = 95:3:140;
stim_type_vec = {'trim', 'ONOFF'};
file_type = 'mixed_stimuli';

% Load data
grand_ex_save = ...
    posthoc_load_my_file(subjid,file_type,stim_freq,[]);

% Organize data
posthoc_organize_data

% % Inspect signals for artefacts
% posthoc_inspect_signals

% Generate waterfall plots on averaged data
posthoc_waterfall

% 1024 analysis
posthoc_1024_trial

% Simulated adaptive method
posthoc_adaptive_simulation

% Inspect EKG signals
posthoc_ekg