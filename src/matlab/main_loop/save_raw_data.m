function ex = save_raw_data(ex, app, is_autosave)
if nargin < 3, is_autosave = false; end

fprintf('\nSaving current amplitude data...\n');

iblock = ex.counter.iblock;
ihealth = ex.counter.ihealth;
iboot = ex.counter.iboot;
iamp = ex.counter.iamp;
fs = ex.info.recording.sampling_rate_hz;
downsamp_rate = 2;
N_chan = ex.info.channels.n_channels;

% Generate timestamp
ex.info.experiment.exp_time_end = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
ex.info.experiment.exp_duration = char(ex.info.experiment.exp_time_end - ex.info.experiment.exp_time_start);
timestamp_str = char(ex.info.experiment.exp_time_end);

% Find folder
folder = get_subject_folder(ex);

if is_autosave
    filename = sprintf('%s_%ddBSPL_raw_data_AUTOSAVE_%s.mat', ex.info.animal.filename_root, ex.info.stimulus.amplitude_spl, timestamp_str);
else
    filename = sprintf('%s_%ddBSPL_raw_data_%s.mat', ex.info.animal.filename_root, ex.info.stimulus.amplitude_spl, timestamp_str);
end

% Extract only required fields
ex_save = struct();
ex_save.info = ex.info; % Basic experiment parameters
ex_save.counter = ex.counter; % Know how many of each thing we did by the time we finished testing this amplitude
ex_save.block_level_info = ex.block(1:iblock); % Block level info

% Downsample
for iiblock = 1:iblock
    cur = ex.raw(iiblock);
    ex_save.raw_signals(iiblock).hydrophone_ds        = dec_rows(cur.hydrophone_mV,    downsamp_rate);
    ex_save.raw_signals(iiblock).loopback_ds          = dec_rows(cur.loopback,         downsamp_rate);
    ex_save.raw_signals(iiblock).time_stamp_ds        = cur.time_stamp(:,1:downsamp_rate:end);
    ex_save.raw_signals(iiblock).electrodes_microV_ds = dec_rows(cur.electrodes_microV, downsamp_rate);
end

ex_save.ds_fs = fs/downsamp_rate;
ex_save.preprocessing_stats = ex.preprocess(1:iblock); % Preprocessing statistics
ex_save.decision = ex.decision(iamp); % Decisions related to this specific stimulus amplitude and frequency

ex_save.kept = ex.kept; % Save the latest round of preprocessed signals
ex_save.kept = rmfield(ex_save.kept, 'trials'); % Don't need these
ex_save.kept = rmfield(ex_save.kept, 'trials_weighted');

ex_save.health = ex.health(1:ihealth);

ex_save.fft = ex.fft;
ex_save.bootstrap = ex.stats(1:iboot);

% Remove stimulus_block from all block entries
if isfield(ex_save.block_level_info, 'stimulus_block')
    ex_save.block_level_info = rmfield(ex_save.block_level_info, 'stimulus_block');
end

% Save
save(fullfile(folder, filename), 'ex_save');

[y, Fs] = audioread('step.mp3');
sound(y, Fs)

%% Save figures and reset block
if ~is_autosave
    if strcmp(ex.info.experiment.exp_type,'Adaptive')
        save_adaptive_figures(ex,folder)
        delete_autosaves(folder, ex.info.animal.filename_root);
    elseif strcmp(ex.info.experiment.exp_type,'Timed') || strcmp(ex.info.experiment.exp_type,'Static trial count')
        save_timed_static_figures(ex,app,folder)
        delete_autosaves(folder, ex.info.animal.filename_root);
    end
    ex = setup_block(ex);
    ex = setup_analysis(ex);
end

end

function y = dec_rows(x, r)
    n = ceil(size(x,2)/r);
    y = zeros(size(x,1), n, size(x,3));
    for k = 1:size(x,3)
        for i = 1:size(x,1)
            y(i,:,k) = decimate(x(i,:,k), r);
        end
    end
end
