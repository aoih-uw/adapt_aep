function [FFTBlock_stimuli, FFTBlock_stimuli_dur, jitterdur, phaselist, ex, FFTBlock_stimuli_component_dur,mylatency,longestVectorPossible_samps] = createStimFFTBlock(ifreq, iamp,...
                ex, current_amplitude, tone_waveforms, adapt_params, calibration_data, mylatency_samp,fs,blockSize)

% Goal: To create a list of 10 waveforms of identical frequencies and amplitudes, but different jitter periods
% Amplitude scaling and latency applied here
% Prestim signal window length = tone_waveforms waveform length;
% Poststim pause as well same length as tone waveforms waveform length

% Total number of waveforms in block
totalwaves = blockSize;

% Set up jitter values to try to capture random phases of 60 Hz noise
period60Hz = 1/60;
cyclePoints = ceil(linspace(0,period60Hz,500)*fs); % 500 is arbitrary...
addacycle = period60Hz*fs;
cyclePoints = cyclePoints+(addacycle);
selectedPoints = randperm(500,totalwaves);
selectedCyclePoints = cyclePoints(selectedPoints);

% Prestim Signal Window
prestim_sig = zeros(1, length(tone_waveforms(ifreq,:)));

% Stimulus
mywaveform = tone_waveforms(ifreq,:);

% Post stimulus window
poststim_pause = zeros(1, length(tone_waveforms(ifreq,:)));

% Latency
mylatency = zeros(1,ceil(mylatency_samp));

% Longest possible vector
maxJitter = max(cyclePoints);
longestVectorPossible_samps = maxJitter + length(prestim_sig) + length(mywaveform) + length(poststim_pause) + length(mylatency);

% Alternating phase vector
positive_phase = ones(totalwaves/2,1);
negative_phase = positive_phase*-1;
ROV = randperm(totalwaves);
phaselist = [positive_phase negative_phase];
phaselist = phaselist(ROV);

for i = 1:totalwaves

    % Jitter
    currentCyclePoint = selectedCyclePoints(i);
    jitter = zeros(1,currentCyclePoint);

    % Total
    mysig = [jitter prestim_sig mywaveform poststim_pause mylatency];

    % Apply phase inversion
    mysig = mysig*phaselist(i);

    % Apply scaling
    % Note: Level is relative to 1 (max output), which should
    % give 170 dB (system is set to output 130 dB at 0.1). 
        % Isn't 130 at 0.01?

    % Adjust amplitude for current amplitude
    baselev = 10^((current_amplitude-170)/20); %#%#%#%#%#%#%#%#%#%#%#
    % now apply scaling factor based on calibration data
    mylev = baselev.*calibration_data.correction_factors_sf(ifreq);
    % now scale amplitude of sine
    mysig = mylev.*mysig;

    FFTBlock_stimuli{i} = mysig;
    FFTBlock_stimuli_dur(i) = length(mysig);
    FFTBlock_stimuli_component_dur(i) = length(prestim_sig);
end

% Save outputs to ex
% Handle cell array concatenation for waveforms
if isempty(ex{ifreq, iamp}.stimuli_waveforms)
    ex{ifreq, iamp}.stimuli_waveforms = FFTBlock_stimuli(:);
else
    ex{ifreq, iamp}.stimuli_waveforms = [ex{ifreq, iamp}.stimuli_waveforms; FFTBlock_stimuli(:)];
end

% Handle numeric array concatenation for durations
if isempty(ex{ifreq, iamp}.stimuli_durations)
    ex{ifreq, iamp}.stimuli_durations = FFTBlock_stimuli_dur(:);
else
    ex{ifreq, iamp}.stimuli_durations = [ex{ifreq, iamp}.stimuli_durations; FFTBlock_stimuli_dur(:)];
end

% Handle numeric array concatenation for phase pattern
if isempty(ex{ifreq, iamp}.stimuli_phasepattern)
    ex{ifreq, iamp}.stimuli_phasepattern = phaselist(:);
else
    ex{ifreq, iamp}.stimuli_phasepattern = [ex{ifreq, iamp}.stimuli_phasepattern; phaselist(:)];
end

% Handle numeric array concatenation for jitter duration
if isempty(ex{ifreq, iamp}.stimuli_jitterdur)
    ex{ifreq, iamp}.stimuli_jitterdur = selectedCyclePoints(:);
else
    ex{ifreq, iamp}.stimuli_jitterdur = [ex{ifreq, iamp}.stimuli_jitterdur; selectedCyclePoints(:)];
end

jitterdur = selectedCyclePoints;

