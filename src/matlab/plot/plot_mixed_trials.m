function ex = plot_mixed_trials(ex,app)
%% Count which trials in the testing schedule have been presented and plot these counts to a heatmap
% test_schedule: rows = blocks to test, columns = freq, stim_type, stim_amp, n_trials_needed, unique_idx, completed
% Only plots electrode data
% Plots on funfetti axes

% Assign variables
persistent mag_2f

% Get counter info
test_schedule = ex.info.mixed.test_schedule;
ischedule = ex.counter.ischedule;
if ischedule == 1
    mag_2f = nan(1, size(test_schedule,1));
end
iblock = ex.counter.iblock;
ax = app.UIAxes_funfetti;

% Extract recording info
fs = ex.info.DAC.sampling_rate_hz;

% Channels
channel_names = ex.info.electrodes.names{:}; 
valid_electrodes = find(~ismember(channel_names, {'EKG','X','Y','Z','Hydrophone','Loopback'}));
analysis_channel = ex.info.electrodes.analysis_channel;
analysis_channel_idx = find(ismember(channel_names(valid_electrodes),analysis_channel));
latency_samples = ex.info.DAC.latency_samples;

% Get uniq info
uniq_stimuli = ex.info.mixed.uniq_stimuli;
N_unique_stimuli = ex.info.mixed.N_unique_stimuli;

% Get current frequency idx
freq_idx = get_current_freq_idx(ex);
stim_freq = ex.info.stimulus(freq_idx).frequency_hz;

% Extract from ex.info.stimulus
target_freq = ex.info.stimulus(freq_idx).frequency_hz * 2;
target_freq_range = ex.info.stimulus(freq_idx).range_2f_hz;
period_length_samples = length(ex.info.stimulus(freq_idx).waveform);
ramp_duration_ms = ex.info.stimulus(freq_idx).ramp_duration_ms;
ramp_duration_samples = round(ramp_duration_ms/1000*fs);

% Clear axes
delete(findobj(ax, 'Type', 'text'));

% Setup variables
N_trials_needed = ex.info.mixed.uniq_stimuli(:,4);
N_trials_collected = ex.info.mixed.trial_counter;
completion_mat = N_trials_collected ./ N_trials_needed;

%% Plot heatmap
% Reshape completion_mat into 2D: rows = stim_type, cols = amplitude
freq_types = unique(uniq_stimuli(:,1));
amplitudes = unique(uniq_stimuli(:,3));

% Generate 2d heatmap
heat_2d = nan(length(freq_types), length(amplitudes));
for i = 1:N_unique_stimuli
    my_r = find(freq_types == uniq_stimuli(i,1));
    my_c = find(amplitudes == uniq_stimuli(i,3));
    heat_2d(my_r, my_c) = min(completion_mat(i),1);
end

% Draw the 2d heatmap
h_img = imagesc(ax, heat_2d);
set(h_img, 'AlphaData', ~isnan(heat_2d));
xlim(ax,[0.5, length(amplitudes)+0.5]);
ylim(ax,[0.5, length(freq_types)+0.5]);

%% Overlay 2f magnitude trace per cell
if isnan(mag_2f(ischedule))
    sig = ex.kept.trials(:,:,analysis_channel_idx); % Only plot valid set of trials
    jitter_vec = ex.kept.jitter;
    phase_vec = ex.kept.phases; % Double check here that it is indeed balanced

    % Ensure equal phases included in average
    if sum(phase_vec) ~= 0
        keyboard
    end

    % Preallocate
    bin_2f = zeros(size(sig,1),1);
    for it = 1:size(sig,1)
        cur_sig = sig(it,:);
        cur_jitter = jitter_vec(it);
        
        % Extract stim ON and OFF periods in ONOFF mode
        [stim_ON , ~] = extract_stim_ON_OFF( ...
            cur_sig, 1, fs, ...
            latency_samples, period_length_samples, ramp_duration_samples,...
            [],...
            cur_jitter);
        
        [~, freq_vec, fft_vals] = calc_fft(stim_ON, fs);
        [bin_2f(it), ~] = find_fft_bins(target_freq,target_freq_range, fft_vals, freq_vec);
    end
    mag_2f(ischedule) = mean(bin_2f,1,'omitnan');
end

hold(ax,'on')
ymax = max(mag_2f);

for i = 1:N_unique_stimuli
    trace = mag_2f(test_schedule(1:ischedule, 5) == i); 
    if isempty(trace), continue; end
    my_r = find(freq_types == uniq_stimuli(i,1));
    my_c = find(amplitudes == uniq_stimuli(i,3));
    x = linspace(my_c-0.4, my_c+0.4, numel(trace));
    plot(ax, x, (my_r+0.4) - (trace/ymax)*0.6, '-o', ...
        'Color',tableau_10('grey'), 'MarkerSize',2, 'LineWidth',1);
end
hold(ax,'off')

% Add text in each cell
for my_r = 1:length(freq_types)
    for my_c = 1:length(amplitudes)
        if ~isnan(heat_2d(my_r, my_c))
            text(ax, my_c, my_r, sprintf('%1.1f%%', heat_2d(my_r,my_c)*100), ...
                'HorizontalAlignment','center', 'VerticalAlignment','middle', 'FontSize', 11);
        end
    end
end

% Formatting
n = 256; blue = tableau_10('blue');
colormap(ax,[linspace(1,blue(1),n)', linspace(1,blue(2),n)', linspace(1,blue(3),n)']);
clim(ax, [0 1]);
xticks(ax,1:length(amplitudes)); xticklabels(ax,amplitudes);
yticks(ax,(1:length(freq_types))); yticklabels(ax, freq_types);
grid(ax,'off')
title(ax,'Mixed freqs Experiment Progress')
ylabel(ax,'Stimulus Frequency (Hz)')
xlabel(ax,'Amplitude (dB SPL)')
