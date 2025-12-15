function [FFT_block_data, ex]  = collectFFTBlock(FFTBlock_stimuli,...
    FFTBlock_stimuli_dur, jitterdur, itrial, ifreq, iamp, ifft, rec_params, channel_names, ex, Nchan,fs,FFTBlock_stimuli_component_dur,mylatency,longestVectorPossible_samps)
% Goal: To record from the 4 channel electrodes, convert signal from digital
% values to microVolts, and parse of the response into discrete portions
% (prestim, stimresp, and poststimresp periods) and save into output variables
% mysig = [jitter_silence | prestim_baseline | stimulus_period | poststim_period | latency_sample];

%% Validation of input variables
if isempty(FFTBlock_stimuli)
    error('FFTBlock_stimuli cannot be empty');
end

if isempty(FFTBlock_stimuli_dur)
    error('FFTBlock_stimuli_dur cannot be empty');
end

if isempty(jitterdur)
    error('jitterdur cannot be empty');
end

% Get number of stimuli for consistent validation
num_stimuli_check = length(FFTBlock_stimuli);

% Check that the number of stimuli matches the number of jitter durations
if length(jitterdur) ~= num_stimuli_check
    error('Number of jitter durations (%d) must match number of stimuli (%d)', ...
        length(jitterdur), num_stimuli_check);
end

% Validate that FFTBlock_stimuli_dur matches number of stimuli
if length(FFTBlock_stimuli_dur) ~= num_stimuli_check
    error('FFTBlock_stimuli_dur length (%d) must match number of stimuli (%d)', ...
        length(FFTBlock_stimuli_dur), num_stimuli_check);
end

% Validate that FFTBlock_stimuli_component_dur matches number of stimuli
if length(FFTBlock_stimuli_component_dur) ~= num_stimuli_check
    error('FFTBlock_stimuli_component_dur length (%d) must match number of stimuli (%d)', ...
        length(FFTBlock_stimuli_component_dur), num_stimuli_check);
end

% Validate mylatency
if isempty(mylatency) || ~isnumeric(mylatency) || any(mylatency < 0)
    error('mylatency must be a non-negative numeric value');
end

% Validate sampling frequency
if isempty(fs) || ~isnumeric(fs) || fs <= 0
    error('fs (sampling frequency) must be a positive numeric value');
end

% Validate channel_names matches Nchan
if isempty(channel_names) || length(channel_names) ~= Nchan
    error('channel_names length (%d) must match Nchan (%d)', ...
        length(channel_names), Nchan);
end

% Validate indexing parameters
if isempty(itrial) || ~isnumeric(itrial) || itrial <= 0 || mod(itrial, 1) ~= 0
    error('itrial must be a positive integer');
end

if isempty(ifreq) || ~isnumeric(ifreq) || ifreq <= 0 || mod(ifreq, 1) ~= 0
    error('ifreq must be a positive integer');
end

if isempty(iamp) || ~isnumeric(iamp) || iamp <= 0 || mod(iamp, 1) ~= 0
    error('iamp must be a positive integer');
end

if isempty(ifft) || ~isnumeric(ifft) || ifft <= 0 || mod(ifft, 1) ~= 0
    error('ifft must be a positive integer');
end

% Validate ex structure exists and has proper dimensions
if isempty(ex) || size(ex, 1) < ifreq || size(ex, 2) < iamp
    error('ex structure dimensions [%dx%d] insufficient for indices [%d,%d]', ...
        size(ex, 1), size(ex, 2), ifreq, iamp);
end

fprintf('Additional parameter validation passed\n');

%% Validate rec_params structure
if ~isfield(rec_params, 'AEP_scalefact')
    error('rec_params must contain AEP_scalefact field');
end

fprintf('Input validation passed: %d stimuli, durations [%d-%d] samples\n', ...
    length(FFTBlock_stimuli), min(FFTBlock_stimuli_dur), max(FFTBlock_stimuli_dur));

%% Validate downsample factor
if ~isfield(rec_params, 'downsample_factor')
    error('rec_params must contain downsample_factor field');
end

if ~isnumeric(rec_params.downsample_factor) || rec_params.downsample_factor <= 0 || ...
   mod(rec_params.downsample_factor, 1) ~= 0
    error('downsample_factor must be a positive integer');
end

fprintf('Downsampling validation passed: factor = %d\n', rec_params.downsample_factor);

%% Variable initialization
voltScaleFactor = rec_params.AEP_scalefact; % This is to change digital val -> volts

wholestim_dur = FFTBlock_stimuli_dur; % Duration of the whole stimulus including jitter and 3 periods
perperiod_dur = FFTBlock_stimuli_component_dur; % Duration of single period (prestim, stim, poststim)
latency_dur = ones(1,length(FFTBlock_stimuli_dur))*length(mylatency);

electrode_channel_offset = 2; % Electrodes are on channel 5,6,7,8
%% Calculate downsampled timing parameters
downsample_factor = rec_params.downsample_factor;

% Calculate individual downsampled durations for each stimulus
jitterdur_ds = round(jitterdur / downsample_factor);
perperiod_dur_ds = round(perperiod_dur / downsample_factor);
wholestim_dur_ds = round(wholestim_dur / downsample_factor); % FFTBlock_stimuli_dur contains the whole set including jitter, latency padding, and the 3 periods
latency_dur_ds = round(latency_dur / downsample_factor); 

%% Fix zero jitter durations (Step 1)
% Find indices where jitter duration became zero after downsampling
zero_jitter_indices = find(jitterdur_ds == 0);

if ~isempty(zero_jitter_indices)
    fprintf('Found %d stimuli with zero jitter duration after downsampling\n', length(zero_jitter_indices));
    fprintf('Affected stimuli indices: %s\n', mat2str(zero_jitter_indices));
    
    % Set zero jitter durations to minimum of 1 sample
    jitterdur_ds(zero_jitter_indices) = 1;
    
    fprintf('Set jitter duration to 1 sample for affected stimuli\n');
else
    fprintf('No zero jitter durations found after downsampling\n');
end

%% Recalculate wholestim_dur_ds for affected stimuli (Step 2)
if ~isempty(zero_jitter_indices)
    % Recalculate total duration for stimuli with corrected jitter
    for idx = zero_jitter_indices
        wholestim_dur_ds(idx) = jitterdur_ds(idx) + (perperiod_dur_ds(idx) * 3) + latency_dur_ds(idx);
    end
    
    fprintf('Recalculated wholestim_dur_ds for %d affected stimuli\n', length(zero_jitter_indices));
    fprintf('New duration range: [%d - %d] samples\n', min(wholestim_dur_ds), max(wholestim_dur_ds));
end

%% Validate each stimulus duration individually (Step 3 - Updated)
% Warn if any downsampled duration is zero (should not happen after Step 1 correction)
if any(jitterdur_ds == 0) || any(perperiod_dur_ds == 0) || any(wholestim_dur_ds == 0)
    warning('Some downsampled durations are still zero after correction - check downsample factor');
end

% Check that what the whole stimulus duration we calculated is what we expect...
% (This validation now uses the corrected jitter durations from Steps 1 & 2)
for i = 1:length(wholestim_dur_ds)
    expected_total = jitterdur_ds(i) + (perperiod_dur_ds(i) * 3) + latency_dur_ds(i);
    if expected_total ~= wholestim_dur_ds(i)
        error('Duration mismatch for stimulus %d: expected %d, got %d', ...
            i, expected_total, wholestim_dur_ds(i));
    end
end

% Validate that downsampled durations are reasonable (should pass after correction)
if any(wholestim_dur_ds < 1) || any(perperiod_dur_ds < 1) || any(jitterdur_ds < 1)
    error('Some downsampled stimulus durations too small');
end

% This check should now pass since we set minimum jitter duration to 1
if any(jitterdur_ds < 0)
    error('Downsampled jitter durations contain negative values');
end

fprintf('Downsampled timing validation passed: stimulus durations = [%d - %d] samples, jitter range = [%d, %d] samples\n', ...
    min(wholestim_dur_ds), max(wholestim_dur_ds), min(jitterdur_ds), max(jitterdur_ds));

%% Initialize signal sections
% Get block dimensions
num_stimuli = length(FFTBlock_stimuli);

% Validate that each stimulus matches its specified duration (Step 4 - Updated)
% Note: Using original wholestim_dur for stimulus length validation since stimuli haven't been downsampled yet
for i = 1:num_stimuli
    stim_length = length(FFTBlock_stimuli{i});
    if stim_length ~= wholestim_dur(i)
        error('Stimulus %d waveform length (%d) does not match specified duration (%d)', ...
            i, stim_length, wholestim_dur(i));
    end
end

% Additional validation: Check if any stimuli had corrected jitter durations
if exist('zero_jitter_indices', 'var') && ~isempty(zero_jitter_indices)
    fprintf('Note: %d stimuli had jitter durations corrected from 0 to 1 sample after downsampling\n', ...
        length(zero_jitter_indices));
    fprintf('Affected stimulus indices: %s\n', mat2str(zero_jitter_indices));
end

fprintf('Block setup: %d stimuli, downsampled durations range [%d - %d] samples\n', ...
    num_stimuli, min(wholestim_dur_ds), max(wholestim_dur_ds));

%% Pre allocate arrays (using maximum duration for padding)
% Check that perperiod_dur_ds has the same duration across all
if length(unique(perperiod_dur_ds)) ~= 1
    error('Issue with perperiod_dur_ds, not all same duration listed')
end

prestim_sig = zeros(num_stimuli, perperiod_dur_ds(1), Nchan);
stimresp_sig = zeros(num_stimuli, perperiod_dur_ds(1), Nchan);
poststimresp_sig = zeros(num_stimuli, perperiod_dur_ds(1), Nchan);

fprintf('Pre-allocated arrays (downsampled): [%d x %d]\n', num_stimuli, Nchan);

%% Begin recording
fprintf('Presenting 10 trial block of stimuli...')

for iwave = 1:num_stimuli
    fprintf('Presenting Stimuli %1.0f / %d\n', iwave, num_stimuli)    
    curjitter = jitterdur(iwave);
    curjitter_ds = jitterdur_ds(iwave);
    curstimdur = wholestim_dur_ds(iwave);  % Whole stim dur
    curstimdur_ds = wholestim_dur_ds(iwave);  % Get individual downsampled duration
    curperperiod_dur_ds = perperiod_dur_ds(iwave);
    current_wave = FFTBlock_stimuli{iwave};
    current_wave = current_wave(:); % ensure that it is a column vector

    %% Validate current_wave
    if any(isnan(current_wave)) || any(isinf(current_wave))
        error('Invalid stimulus data in wave %d: contains NaN or Inf values', iwave);
    end
    
    % Check amplitude range for safety (prevent speaker/electrode damage)
    max_amplitude = max(abs(current_wave));
    amplitude_threshold = 1.0; % Adjust based on your system's safe range
    if max_amplitude > amplitude_threshold
        error('Stimulus %d amplitude too high (%.3f): exceeds safety threshold (%.3f)', ...
            iwave, max_amplitude, amplitude_threshold);
    end
    
%     % Warn if stimulus is unexpectedly quiet
%     if max_amplitude < 0.001
%         warning('Stimulus %d very quiet (max amplitude: %.6f)', iwave, max_amplitude);
%     end
    
    fprintf('Stimulus %d validated: length=%d samples, max_amplitude=%.4f\n', ...
    iwave, length(current_wave), max_amplitude);
    
%% Rip it
    try
        % Send stimulus and record response
        ipage = playrec('playrec', [current_wave], [1 4], -1, 3:8);
        % Outputs [1 4]: 1 = UW30; 4 = Loopback output
        % 3:8: 3 = hydrophone; 4 = loopback; 5,6,7,8 = Electrodes

        % Wait for recording to complete
        playrec('block', ipage);

        % Get recorded data
        rec_data = double(playrec('getRec', ipage));

        % Clean up the page
        playrec('delPage', ipage);

    catch ME
        % Clean up on error
        try
            playrec('delPage', ipage);
        catch
            % Ignore cleanup errors
        end
        error('Audio recording failed for stimulus %d: %s', iwave, ME.message);
    end
    
    %% Validate recorded data
    if isempty(rec_data)
        error('No data recorded for stimulus %d', iwave);
    end

%     if size(rec_data, 2) < 8
%         error('Insufficient channels recorded for stimulus %d: expected 8, got %d', ...
%             iwave, size(rec_data, 2));
%     end

    %% Convert to microvolts with validation
    try
        rec_data = rec_data .* voltScaleFactor;
        rec_data = rec_data * 1e6;

        % Check for reasonable voltage ranges (basic sanity check)
        if any(abs(rec_data(:)) > 1e6) % More than 1V seems unreasonable for EEG
            warning('Unusually large voltage values detected in stimulus %d (max: %.2f µV)', ...
                iwave, max(abs(rec_data(:))));
        end

    catch ME
        error('Voltage conversion failed for stimulus %d: %s', iwave, ME.message);
    end

    fprintf('Stimulus %d/%d recorded successfully\n', iwave, num_stimuli);

    %% Downsample the recorded data
    try
        rec_data_original = rec_data; % Keep original for debugging if needed
        rec_data = downsample(rec_data, downsample_factor); % Rec_data is now downsampled!
        
        fprintf('Downsampled data from %d to %d samples (factor: %d)\n', ...
            size(rec_data_original, 1), size(rec_data, 1), downsample_factor);
        
        % Validate downsampled data
        if isempty(rec_data)
            error('Downsampling resulted in empty data for stimulus %d', iwave);
        end
        
    catch ME
        error('Downsampling failed for stimulus %d: %s', iwave, ME.message);
    end

    %% Calculate total samples needed for validation (using downsampled values)
    % Expected structure: [jitter_silence | prestim_baseline | stimulus_period | poststim_period | Latency]
    total_samples_needed_ds = curstimdur_ds; % curstimdur_ds includes all of the expected structure samples

    % Validate total recorded data length
    if size(rec_data, 1) ~= total_samples_needed_ds
        error('Downsampled rec_data error. Sample mismatch between expected down sampled number. %d. Need %d samples, got %d', ...
            iwave, total_samples_needed_ds, size(rec_data, 1));
    end
    
    %% Save hydrophone data
    ex{ifreq, iamp}.hydrophone{ifft,iwave} = rec_data(:,1);

    %% PROCESS EACH CHANNEL (WAVEFORMS ORGANIZED BY ROW)
    for ich = 1:Nchan
        realchan = ich + electrode_channel_offset; % The true channel from the DAC (channels 5-8)

        % Validate channel index
        if realchan > size(rec_data, 2)
            error('Channel index %d exceeds available channels (%d) for stimulus %d', ...
                realchan, size(rec_data, 2), iwave);
        end

        % Extract channel data and ensure it's a row vector
        channel_data = rec_data(:, realchan);
        channel_data = channel_data(:).'; % Force row vector

        % Validate channel data
        if any(isnan(channel_data)) || any(isinf(channel_data))
            error('Invalid data in stimulus %d, channel %d: contains NaN or Inf', iwave, ich);
        end

        %% Calculate segment boundaries with bounds checking
        % Structure: [jitter_silence | prestim_baseline | stimulus_period | poststim_period | Latency]
        % Note: Only the 3 periods (prestim, stim, poststim) are segmented; jitter and latency are accounted for but not processed
        try
            %% Pre-stimulus baseline period (after jitter, before stimulus)
            jitter_end = curjitter_ds;
            prestim_start = jitter_end + 1;
            prestim_end = prestim_start + curperperiod_dur_ds - 1;

            % Validate
            if prestim_end > length(channel_data)
                error('Pre-stimulus segment extends beyond data for stimulus %d, channel %d', iwave, ich);
            end
            
            if prestim_start <= jitter_end
                error('Prestim segment overlaps with jitter for stimulus %d, channel %d', iwave, ich);
            end
            
            % Extract data and pad with zeros if needed
            prestim_data = channel_data(prestim_start:prestim_end);
            prestim_sig(iwave, 1:length(prestim_data), ich) = prestim_data;
            
            %% During stimulus period (neural response during stimulus presentation)
            stimresp_start = prestim_end + 1;
            stimresp_end = stimresp_start + curperperiod_dur_ds - 1;

            if stimresp_end > length(channel_data)
                error('Stimulus response segment extends beyond data for stimulus %d, channel %d', iwave, ich);
            end
            
            if stimresp_start <= prestim_end
                error('Stimulus response segment overlaps with prestim for stimulus %d, channel %d', iwave, ich);
            end
            
            % Extract data
            stimresp_data = channel_data(stimresp_start:stimresp_end);
            stimresp_sig(iwave, 1:length(stimresp_data), ich) = stimresp_data;

            %% Post-stimulus period (neural response after stimulus ends)
            poststim_start = stimresp_end + 1;
            poststim_end = poststim_start + curperperiod_dur_ds - 1;

            % Validate
            if poststim_end > length(channel_data)
                error('Post-stimulus segment extends beyond data for stimulus %d, channel %d', iwave, ich);
            end
            
            if poststim_start <= stimresp_end
                error('Poststim segment overlaps with stimulus response for stimulus %d, channel %d', iwave, ich);
            end
            
            % Extract data
            poststim_data = channel_data(poststim_start:poststim_end);
            poststimresp_sig(iwave, 1:length(poststim_data), ich) = poststim_data;

            %% Debug 
            %Print segment boundaries for first stimulus and channel
            if iwave == 1 && ich == 1
                fprintf('Segment boundaries (downsampled): jitter=1:%d, prestim=%d:%d, stim=%d:%d, poststim=%d:%d\n', ...
                    curjitter_ds, prestim_start, prestim_end, stimresp_start, stimresp_end, poststim_start, poststim_end);
            end
            
            % Validate that we account for all expected samples
            expected_total_samples = curjitter_ds + (curperperiod_dur_ds * 3) + latency_dur_ds(iwave);
            if length(channel_data) ~= expected_total_samples
                error('Data length mismatch for stimulus %d, channel %d: expected %d, got %d', ...
                    iwave, ich, expected_total_samples, length(channel_data));
            end
            
            % Make sure each segment is of the expected duration
            if length(prestim_data) ~= curperperiod_dur_ds || length(stimresp_data) ~= curperperiod_dur_ds ...
                    || length(poststim_data) ~= curperperiod_dur_ds 
                error ('Unexpected length for segemented data')
            end
            
            % Debug output for first stimulus/channel
            if iwave == 1 && ich == 1
                fprintf('Segment validation: jitter=1:%d, prestim=%d:%d, stim=%d:%d, poststim=%d:%d, latency=%d:%d\n', ...
                    jitter_end, prestim_start, prestim_end, stimresp_start, stimresp_end, ...
                    poststim_start, poststim_end);
                fprintf('Total samples: %d, Expected: %d\n', length(channel_data), expected_total_samples);
            end

        catch ME
            error('Data segmentation failed for stimulus %d, channel %d: %s', iwave, ich, ME.message);
        end
    end

    % Log progress every few stimuli
    if mod(iwave, 5) == 0 || iwave == num_stimuli
        fprintf('Processed %d/%d stimuli\n', iwave, num_stimuli);
    end
end

%% Save to output FFT_block_data
FFT_block_data = struct();
FFT_block_data.prestim_sig = prestim_sig;
FFT_block_data.stimresp_sig = stimresp_sig;
FFT_block_data.poststimresp_sig = poststimresp_sig;

% Add comprehensive metadata for downstream functions
FFT_block_data.metadata.num_stimuli = num_stimuli;
FFT_block_data.metadata.signal_durations = wholestim_dur_ds;  % Array of individual durations
FFT_block_data.metadata.signal_durations_original = wholestim_dur;  % Array of original durations
FFT_block_data.metadata.signal_duration_original_max = max(wholestim_dur);  % Maximum original duration
FFT_block_data.metadata.num_channels = Nchan;
FFT_block_data.metadata.frequency_index = ifreq;
FFT_block_data.metadata.amplitude_index = iamp;
FFT_block_data.metadata.fft_block_number = ifft;
FFT_block_data.metadata.channel_names = channel_names;
FFT_block_data.metadata.collection_time = datestr(now);
FFT_block_data.metadata.downsample_factor = downsample_factor;
FFT_block_data.metadata.original_fs = fs;
FFT_block_data.metadata.downsampled_fs = fs / downsample_factor;

fprintf('Downsampling: [%d-%d] → [%d-%d] samples (factor: %d)\n', ...
    min(wholestim_dur), max(wholestim_dur), min(wholestim_dur_ds), max(wholestim_dur_ds), ...
    downsample_factor);

%% Save to ex structure
% Keep track how the number of trials
if ~isfield(ex{ifreq, iamp}, 'trialnum') || isempty(ex{ifreq, iamp}.trialnum)
    ex{ifreq, iamp}.trialnum = (itrial-num_stimuli+1):itrial;
else
    ex{ifreq, iamp}.trialnum = [ex{ifreq, iamp}.trialnum, (itrial-num_stimuli+1):itrial];
end

for ich = 1:Nchan
    curchan_name = channel_names{ich};

    % Initialize signal fields as cell arrays if they are empty []
    if isempty(ex{ifreq, iamp}.electrodes.(curchan_name).signals.prestim_sig)
        ex{ifreq, iamp}.electrodes.(curchan_name).signals.prestim_sig = {};
    end
    if isempty(ex{ifreq, iamp}.electrodes.(curchan_name).signals.stimresp_sig)
        ex{ifreq, iamp}.electrodes.(curchan_name).signals.stimresp_sig = {};
    end
    if isempty(ex{ifreq, iamp}.electrodes.(curchan_name).signals.poststimresp_sig)
        ex{ifreq, iamp}.electrodes.(curchan_name).signals.poststimresp_sig = {};
    end

    % Store signal data in cell arrays
    ex{ifreq, iamp}.electrodes.(curchan_name).signals.prestim_sig{ifft} = prestim_sig(:,:,ich);
    ex{ifreq, iamp}.electrodes.(curchan_name).signals.stimresp_sig{ifft} = stimresp_sig(:,:,ich);
    ex{ifreq, iamp}.electrodes.(curchan_name).signals.poststimresp_sig{ifft} = poststimresp_sig(:,:,ich);

    fprintf('Stored FFT block %d data for %s\n', ifft, curchan_name);

    % Initialize N fields as arrays if they are empty []
    if isempty(ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.prestim.N)
        ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.prestim.N = [];
    end
    if isempty(ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.stimresp.N)
        ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.stimresp.N = [];
    end
    if isempty(ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.poststimresp.N)
        ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.poststimresp.N = [];
    end

    % Store trial counts in regular arrays (extend array if needed)
    ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.prestim.N(ifft) = num_stimuli;
    ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.stimresp.N(ifft) = num_stimuli;
    ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.poststimresp.N(ifft) = num_stimuli;

    % Calculate cumulative trials for this channel
    cumulative_trials = sum(ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.prestim.N);
    % Validation: All signal types should have same trial counts
    prestim_trials = ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.prestim.N(ifft);
    stimresp_trials = ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.stimresp.N(ifft);
    poststim_trials = ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.poststimresp.N(ifft);

    if prestim_trials ~= stimresp_trials || stimresp_trials ~= poststim_trials
        warning('Trial count mismatch for %s, FFT block %d: prestim=%d, stimresp=%d, poststim=%d', ...
            curchan_name, ifft, prestim_trials, stimresp_trials, poststim_trials);
    end

    fprintf('Trial counts for %s, block %d: %d trials (cumulative: %d)\n', ...
        curchan_name, ifft, num_stimuli, cumulative_trials);
end

%% FINAL VALIDATION AND CLEANUP
% Validate that all channels have consistent data for this FFT block
trial_counts = zeros(1, Nchan);
signal_sizes = zeros(Nchan, 3);  % [prestim, stimresp, poststim] sizes

for check_ch = 1:Nchan
    check_channel_name = channel_names{check_ch};
    
    % Validate that the channel structure exists
    if ~isfield(ex{ifreq, iamp}.electrodes, check_channel_name)
        error('Channel %s not found in ex structure after storage', check_channel_name);
    end
    
    % Check trial counts
    trial_counts(check_ch) = ex{ifreq, iamp}.electrodes.(check_channel_name).running_stats.prestim.N(ifft);
    
    % Check signal array sizes
    signal_sizes(check_ch, 1) = size(ex{ifreq, iamp}.electrodes.(check_channel_name).signals.prestim_sig{ifft}, 1);
    signal_sizes(check_ch, 2) = size(ex{ifreq, iamp}.electrodes.(check_channel_name).signals.stimresp_sig{ifft}, 1);
    signal_sizes(check_ch, 3) = size(ex{ifreq, iamp}.electrodes.(check_channel_name).signals.poststimresp_sig{ifft}, 1);
end

% Validate trial count consistency across channels
if length(unique(trial_counts)) > 1
    error('Inconsistent trial counts across channels for FFT block %d: %s', ...
        ifft, mat2str(trial_counts));
end

% Validate signal size consistency across channels
if size(unique(signal_sizes, 'rows'), 1) > 1
    error('Inconsistent signal sizes across channels for FFT block %d', ifft);
end

% Validate that FFT block data matches ex structure (downsampled dimensions)
if size(FFT_block_data.prestim_sig, 1) ~= num_stimuli || ...
   size(FFT_block_data.stimresp_sig, 1) ~= num_stimuli || ...
   size(FFT_block_data.poststimresp_sig, 1) ~= num_stimuli
    error('FFT_block_data size mismatch: expected %d trials, got [%d, %d, %d]', ...
        num_stimuli, size(FFT_block_data.prestim_sig, 1), ...
        size(FFT_block_data.stimresp_sig, 1), size(FFT_block_data.poststimresp_sig, 1));
end

% Validate downsampled signal dimensions (should match maximum padded size)
expected_samples = perperiod_dur_ds(1);
if size(FFT_block_data.prestim_sig, 2) ~= expected_samples || ...
   size(FFT_block_data.stimresp_sig, 2) ~= expected_samples || ...
   size(FFT_block_data.poststimresp_sig, 2) ~= expected_samples
    error('FFT_block_data downsampled dimension mismatch: expected %d samples (padded), got [%d, %d, %d]', ...
        expected_samples, size(FFT_block_data.prestim_sig, 2), ...
        size(FFT_block_data.stimresp_sig, 2), size(FFT_block_data.poststimresp_sig, 2));
end

%% SUCCESS SUMMARY
fprintf('\n=== FFT BLOCK %d COLLECTION COMPLETE ===\n', ifft);
fprintf('Frequency index: %d, Amplitude index: %d\n', ifreq, iamp);
fprintf('Trials collected: %d\n', num_stimuli);
fprintf('All %d channels validated successfully\n', Nchan);
fprintf('Downsampled data stored in ex structure and FFT_block_data\n');
fprintf('Signal structure: [jitter_silence | prestim_baseline | stimulus_period | poststim_period]\n');
fprintf('========================================\n');

% Final check that ex structure is ready for next processing steps
total_trials_so_far = length(ex{ifreq, iamp}.trialnum);
fprintf('Total trials for this condition: %d\n', total_trials_so_far);

end