function ex = count_mixed_trials(ex,app)
%% Count which trials in the testing schedule have been presented and plot these counts to a heatmap
% test_schedule: rows = n total trials to test, columns stimuli_type, stimulus_amplitude, n_trials_needed, unique_idx
% Assign variables
persistent mag_2f
test_schedule = ex.info.mixed.test_schedule;
ischedule = ex.counter.ischedule;
if ischedule == 1
    mag_2f = nan(1, size(test_schedule,1));
end
uniq_stimuli = ex.info.mixed.uniq_stimuli;
N_unique_stimuli = ex.info.mixed.N_unique_stimuli;
target_freq = ex.info.stimulus.frequency_hz * 2;
target_freq_range = ex.info.stimulus.range_2f_hz;
fs = ex.info.recording.sampling_rate_hz;
channel_names = ex.info.channels.names;
valid_channels = find(~strcmp(channel_names, 'EKG'));
analysis_channel = ex.info.channels.analysis_channel;
analysis_channel_idx = find(strcmp(channel_names(valid_channels),analysis_channel));
iblock = ex.counter.iblock;
latency_samples = ex.info.recording.latency_samples;
period_length_samples = length(ex.info.stimulus.waveform);
ramp_duration_ms = ex.info.stimulus.ramp_duration_ms;
ramp_duration_samples = round(ramp_duration_ms/1000*fs);
trim_stim_pre_dur_ms = ex.info.stimulus.trim_stim_pre_dur_ms;
stimulus_type_idx = ex.info.mixed.test_schedule(ischedule,1);

% Clear axes
delete(findobj(app.UIAxes_funfetti, 'Type', 'text'));

% Setup variables
N_trials_needed = ex.info.mixed.uniq_stimuli(:,3);
N_trials_collected = ex.info.mixed.trial_counter;
completion_mat = N_trials_collected ./ N_trials_needed;

%% Plot live fft
plot_live_fft(ex,iblock,fs,app);

%% Plot heatmap
% Reshape completion_mat into 2D: rows = stim_type, cols = amplitude
stim_types = unique(uniq_stimuli(:,1));
amplitudes = unique(uniq_stimuli(:,2));

% Generate 2d heatmap
heat_2d = zeros(length(stim_types), length(amplitudes));
for i = 1:N_unique_stimuli
    my_r = find(stim_types == uniq_stimuli(i,1));
    my_c = find(amplitudes == uniq_stimuli(i,2));
    heat_2d(my_r, my_c) = min(completion_mat(i),1);
end

% Draw the 2d heatmap
imagesc(app.UIAxes_funfetti,heat_2d);
xlim(app.UIAxes_funfetti,[0.5, length(amplitudes)+0.5]);
ylim(app.UIAxes_funfetti,[0.5, length(stim_types)+0.5]);

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
        % Extract stim ON portion for 2f mag calculation
        if  strcmp(ex.info.mixed.stim_name{stimulus_type_idx}, 'trim')
            [stim_ON , ~] = extract_stim_ON_OFF( ...
                cur_sig, 0, fs, ...
                latency_samples, period_length_samples, ramp_duration_samples,...
                trim_stim_pre_dur_ms,...
                cur_jitter);
        elseif strcmp(ex.info.mixed.stim_name{stimulus_type_idx}, 'ONOFF')
            [stim_ON , ~] = extract_stim_ON_OFF( ...
                cur_sig, 1, fs, ...
                latency_samples, period_length_samples, ramp_duration_samples,...
                [],...
                cur_jitter);
        end
        [~, freq_vec, fft_vals] = calc_fft(stim_ON, fs);
        [bin_2f(it), ~] = find_fft_bins(target_freq,target_freq_range, fft_vals, freq_vec);
    end
    mag_2f(ischedule) = mean(bin_2f,1,'omitnan');
end

hold(app.UIAxes_funfetti,'on')
ymax = max(mag_2f);

for i = 1:N_unique_stimuli
    trace = mag_2f(test_schedule(1:ischedule, 4) == i); 
    if isempty(trace), continue; end
    my_r = find(stim_types == uniq_stimuli(i,1));
    my_c = find(amplitudes == uniq_stimuli(i,2));
    x = linspace(my_c-0.4, my_c+0.4, numel(trace));
    plot(app.UIAxes_funfetti, x, (my_r+0.4) - (trace/ymax)*0.6, '-o', ...
        'Color',tableau_10('grey'), 'MarkerSize',2, 'LineWidth',1);
end
hold(app.UIAxes_funfetti,'off')

% Add text in each cell
for my_r = 1:length(stim_types)
    for my_c = 1:length(amplitudes)
        text(app.UIAxes_funfetti,my_c, my_r, sprintf('%1.1f%%', heat_2d(my_r,my_c)*100), ...
            'HorizontalAlignment','center', 'VerticalAlignment','middle', 'FontSize', 11);
    end
end

n = 256; blue = tableau_10('blue');
colormap(app.UIAxes_funfetti,[linspace(1,blue(1),n)', linspace(1,blue(2),n)', linspace(1,blue(3),n)']);
clim(app.UIAxes_funfetti, [0 1]);
xticks(app.UIAxes_funfetti,1:length(amplitudes)); xticklabels(app.UIAxes_funfetti,amplitudes);
yticks(app.UIAxes_funfetti,(1:length(stim_types))); yticklabels(app.UIAxes_funfetti,ex.info.mixed.stim_name(stim_types));
title(app.UIAxes_funfetti,'Mixed Stimuli Experiment Progress')
ylabel(app.UIAxes_funfetti,'Stimuil type')
xlabel(app.UIAxes_funfetti,'Amplitude (dB SPL)')
