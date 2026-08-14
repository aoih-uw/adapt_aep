function [full_amp_duration_ms, ramp_duration_ms] = ...
    select_experiment_stim_params(fs, stim_freq, period_s, period_samps, ramp_cycles, desired_freq_res)
%% This function assigns the tone burst full amplitude and on/off ramp duration. 
% Ensures that the full amplitude duration has the minimum number of samples needed for a 
% 5 Hz minimum frequency resolution in the fft. 
% Also rounds up sample numbers for the full amplitude portion and on/off ramps to the 
% next nearest full cycle for the current stimulus frequency
% Only round at the very end 

%% Stimulus parameters 7/6
% Full amplitude duration is the number of samples needed to achieve 5 Hz
% sampling resolution rounded to the next whole phase

% Ramp cycle duration = minimum 50 ms or 6 cycles

% Full amp duration
if mod(stim_freq,desired_freq_res) == 0 % Ensure the freq_res bin falls right on stim_freq
    full_samp = ceil(fs/desired_freq_res);
    full_samp = round(ceil(full_samp/period_samps)*period_samps); % Round up to nearest cycle
    full_amp_duration_ms = full_samp/fs*1e3;
else
    error('Stimulus frequency must be a multiple of %d', desired_freq_res)
end

% Ramp cycle duration
cur_ramp_samples = period_s*ramp_cycles*fs;
cur_ramp_samples = max(cur_ramp_samples, 50/1e3*fs); % 50 ms into samples
ramp_duration_samples = round(ceil(cur_ramp_samples/period_samps)*period_samps); % Round up to nearest cycle
ramp_duration_ms = ramp_duration_samples/fs*1e3;
