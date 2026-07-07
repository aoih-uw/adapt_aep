function ex = select_experiment_stim_params(ex)
%% This function assigns the tone burst full amplitude and on/off ramp duration. 
% Ensures that the full amplitude duration has the minimum number of samples needed for a 
% 5 Hz minimum frequency resolution in the fft. 
% Also rounds up sample numbers for the full amplitude portion and on/off ramps to the 
% next nearest full cycle for the current stimulus frequency
% Only round at the very end 

%% Stimulus parameters 7/6
% Full amplitude duration = 6 cycles or next nearest full cycle based on minimum samples 
% needed for 5 Hz frequency resolution, whichever is larger
% fft

% Ramp duration = 6 cycles or 50 ms rounded to the next full cycle, whichever has more samples
% Determine full amplitude duration
fs = ex.info.recording.sampling_rate_hz;
stim_freq = ex.info.stimulus.frequency_hz;
period_s = 1/stim_freq;
period_samps = period_s*fs;

% Full amp duration
full_amp_cycles = ex.info.stimulus.full_amplitude_cycle_num; % Minimum full amplitude duration ms is 20ms following Mooney et al. 2010
cur_full_amp_dur_samps = period_s*full_amp_cycles*fs;
desired_freq_res = 5; %fs/N = 5
min_req_samples = ceil(fs/desired_freq_res);
cur_full_samp = max(cur_full_amp_dur_samps, min_req_samples); 
full_samp = round(ceil(cur_full_samp/period_samps)*period_samps); % Round up to nearest cycle
ex.info.stimulus.full_amplitude_duration_ms = full_samp/fs*1e3;

% Ramp cycle duration
ramp_cycles = ex.info.stimulus.ramp_duration_cycles;
cur_ramp_samples = period_s*ramp_cycles*fs;
cur_ramp_samples = max(cur_ramp_samples, 50/1e3*fs); % 50 ms into samples
ramp_duration_samples = round(ceil(cur_ramp_samples/period_samps)*period_samps); % Round up to nearest cycle
ex.info.stimulus.ramp_duration_ms = ramp_duration_samples/fs*1e3;