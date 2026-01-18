function tone_burst = generate_tone_burst(fs, stim_freq, full_amp_dur_ms, ramp_dur_ms)
ms_to_s = 1000; % conversion factor

% Samples
full_amp_dur_s = full_amp_dur_ms/ms_to_s;
full_amp_samp = round(full_amp_dur_s*fs);
ramp_dur_s = ramp_dur_ms/ms_to_s;
ramp_samp = round(ramp_dur_s*fs);

% Check if sample numbers are reasonable
if full_amp_samp < 1 || ramp_samp < 1
    error('make_tone_burst:InvalidDuration', ...
        'Tone burst sample number less than 1, check stimulus duration values')
end

% Create window
win_up = cos(linspace(-pi/2,0,ramp_samp)).^2;
win_down = cos(linspace(0,pi/2,ramp_samp)).^2;
window = [win_up ones(1,full_amp_samp) win_down];

% Generate tone burst
time_vec = (0:length(window)-1)/fs;
tone_burst = sin(2*pi*(stim_freq*time_vec)).*window;
tone_burst = tone_burst(:).';   % force row vector