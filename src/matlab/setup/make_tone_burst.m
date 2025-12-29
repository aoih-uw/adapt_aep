function ex = make_tone_burst(ex)
% Make a ramped tone burst for selected frequency

ms_to_s = 1000; % conversion factor

% Extract data from ex
fs = ex.info.recording.sampling_rate_hz;
stim_freq = ex.info.stimulus.frequency_hz;
full_amp_dur_ms = ex.info.stimulus.full_amplitude_duration_ms;
ramp_dur_ms = ex.info.stimulus.ramp_duration_ms;

% Nyquist check
if stim_freq >= fs/2
    error('Stimulus frequency must be below Nyquist limit (fs/2 = %.1f Hz)', fs/2)
end

% Samples
full_amp_dur_s = full_amp_dur_ms/ms_to_s;
full_amp_samp = round(full_amp_dur_s*fs);
ramp_dur_s = ramp_dur_ms/ms_to_s;
ramp_samp = round(ramp_dur_s*fs);

% Check if sample numbers are reasonable
if full_amp_samp < 1 || ramp_samp < 1
    error('Tone burst sample number less than 1, check stimulus duration values')
end

% Create window
win_up = cos(linspace(-pi/2,0,ramp_samp)).^2;
win_down = cos(linspace(0,pi/2,ramp_samp)).^2;
window = [win_up ones(1,full_amp_samp) win_down];

% Generate tone burst
time_vec = (0:length(window)-1)/fs;
tone_burst = sin(2*pi*(stim_freq*time_vec)).*window;
tone_burst = tone_burst(:).';   % force row vector

ex.info.stimulus.total_stimulus_duration_ms = (length(tone_burst)/fs)*ms_to_s;
ex.info.stimulus.waveform = tone_burst;