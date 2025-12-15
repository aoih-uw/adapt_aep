function [tone_waveforms, window] = makeTones(stim_params, frequencies, fs)
%% Make a ramped tone for each frequency listed in generateFreqArray

% Full amplitude portion
fullamp_ms = stim_params.stim_dur_fullamp;
fullamp_samps = (fullamp_ms/1000)*fs;

% Ramps
ramp_proportion = stim_params.stim_ramp_proportion;
ramp_ms = fullamp_ms*ramp_proportion;
ramp_samps = (ramp_ms/1000)*fs;

% Create window
winup = cos(linspace(-pi/2,0,ramp_samps)).^2;
windown = cos(linspace(0,pi/2,ramp_samps)).^2;
window = [winup ones(1, fullamp_samps) windown];

% Total
totalstim_dur = length(window)/fs;
timebase = linspace(0,totalstim_dur,length(window));

% Initialize tone waveforms
tone_waveforms = zeros(length(frequencies), length(window));

for ifreq = 1:length(frequencies)
    currentFreq = frequencies(ifreq);
    tone_waveforms(ifreq,:) = sin(2*pi*(currentFreq*timebase)).*window;
end