function ex = run_adaptiveAEP_fish(args,app)
addpath(genpath('C:\Users\AEP\Desktop\Experiments\adaptiveAEP_2025'));

%   Let's get started
%         _
%   .-*'`    `*-.._.-'/
% < * ))     ,       (
%   `*-._`._(__.--*"`.\

%% Step 1: Set up experiment variables
[exp_params,stim_params,rec_params,adapt_params] = setupvars(args);

%% Step 2: Start writing the diary
c = clock;
datecode = sprintf('%.2d%.2d%.2d_%.2d%.2d', rem(c(1),100), c(2), c(3), c(4), c(5));
cwd = cd;

% Use forward slashes or fullfile for better cross-platform compatibility
cd('C:/Users/AEP/Desktop/Experiments/adaptiveAEP_2025/data');

% Create filename for data
mysavename = sprintf('%s_%s_%s_run%s.mat', ...
    exp_params.fish_ID, ...
    exp_params.experiment, ...
    datecode, ...
    exp_params.run);

% Create separate diary filename (typically .txt or .log)
diary_name = sprintf('%s_%s_%s_run%s_diary.txt', ...
    exp_params.fish_ID, ...
    exp_params.experiment, ...
    datecode, ...
    exp_params.run);

diary(diary_name);
tic
%% INITIALIZATION
%% Step 1: Get calibration data
global calibration_data

% Initialize calibration_data if not already loaded
if isempty(calibration_data)
    try
        % Try to load existing calibration data
        load('calibration_data.mat', 'calibration_data');
        fprintf('Loaded existing calibration data.\n');
    catch
        % If no calibration file exists, prompt user or use defaults
        error('No calibration data found');
    end
end

%% Step 2: Check if all required functions/variables are accessible
% Check if required functions are available
required_functions = {'setupvars', 'generateFreqArray', 'makeTones', ...
    'setupex', 'initializeAudio', 'testLatency', ...
    'calcScalingFactor', 'selectTrackingFreqs', 'initGUIvisuals'};
for i = 1:length(required_functions)
    if ~exist(required_functions{i}, 'file')
        error('Required function %s not found. Check your path.', required_functions{i});
    end
end
%% Step 4: Define the sampling frequency
fs = rec_params.sampfreq;

%% Step 5: Generate frequency array with 1/3 octave steps (1 waveform for each frequency for now)
randomizeCheckBox = stim_params.randomizeCheckBox; 
[frequencies, presentation_order, myorderedfrequencies] = generateFreqArray(stim_params,randomizeCheckBox);

% Display frequencies and presentation order on GUI
% For frequencies - create comma-separated list
app.frequenciesList.Text = sprintf('%.0f, ', myorderedfrequencies);
app.frequenciesList.Text = app.frequenciesList.Text(1:end-2); % Remove trailing comma and space

% VALIDATION: Check that presentation_order indices are valid
if any(presentation_order < 1) || any(presentation_order > length(frequencies))
    error('Invalid presentation_order: contains indices outside the range of frequencies array (1 to %d)', ...
        length(frequencies));
end

% Additional validation: Check for duplicate indices (optional but recommended)
if length(unique(presentation_order)) ~= length(presentation_order)
    warning('presentation_order contains duplicate indices. This may not be intended.');
end

% Log validation success
fprintf('Presentation order validated: %d frequencies will be tested in order [%s]\n', ...
    length(presentation_order), num2str(presentation_order));

%% Step 6: Pre-generate stimulus waveforms (1 waveform for each frequency; ramps applied here)
[tone_waveforms, window] = makeTones(stim_params, frequencies, fs);

%% Step 8: Initialize PlayRec and check audio interface
audioInitSuccess = initializeAudio(fs);
if ~audioInitSuccess
    error('Audio initialization failed. Please check your audio interface and try again.');
end
fprintf('Audio interface initialized successfully.\n');

%% Step 9: Calculate system latency
try
    [mythresh_samp,mylatency_samp] = testLatency(fs);
    fprintf('System latency calculated: threshold = %d samples, latency = %d samples\n', ...
        mythresh_samp, mylatency_samp);
catch
    error('Latency test failed');
end

% Validate latency values
if isempty(mythresh_samp) || isempty(mylatency_samp)
    warning('Invalid latency values detected. Using defaults.');
    mythresh_samp = 0;
end

app.latencyThresholdLabel.Text = string(mythresh_samp);
app.latencySampleLabel.Text = string(mylatency_samp);

%% Step 10: Calculate AEP Scaling factor
[rec_params, ampgain, Vscale, gain_ch1, gain_ch2, gain_ch3, gain_ch4]= calcScalingFactor(rec_params);

% Validate scaling factor results
if isempty(ampgain) || isempty(Vscale)
    error('Scaling factor calculation failed. Check your recording parameters.');
end
fprintf('AEP scaling factors calculated successfully.\n');

%% Step 11: Select frequencies to track in tracker
% selectTrackingFreqs % Works with displayTracker

%% Step 12: Set up ex structure
ex = setupex(frequencies, stim_params, adapt_params);

%% Step 13: Set up channel names
channel_names = {'ch1', 'ch2', 'ch3', 'ch4'};

%% Step 14: Set up response type names
response_names = {'prestim', 'stimresp', 'poststimresp'};

%% Step 15: Set up signal types to track
signals_to_track = {'stimulus_freq','double_freq','sixty_cycle'};

%% Step 14: Initialize GUI visualizations with tracker frequencies
initGUIvisuals

%% Step 16: Initialize maximum trial number for each stimulus type
maxTrialNum = adapt_params.max_stim_presentation;

%% Step 17: Initialize storage for GUI figures
Nchan = rec_params.nchans;

% Use global variable instead of app property
global gui_channel_data;
gui_channel_data = struct();
gui_channel_data.pval_x_data = cell(1, Nchan);
gui_channel_data.pval_y_data = cell(1, Nchan);
gui_channel_data.crit_x_data = cell(1, Nchan);
gui_channel_data.crit_y_data = cell(1, Nchan);

for ich = 1:Nchan
    gui_channel_data.pval_x_data{ich} = [];
    gui_channel_data.pval_y_data{ich} = [];
    gui_channel_data.crit_x_data{ich} = [];
    gui_channel_data.crit_y_data{ich} = [];
end

%% Clear GUI Figures

% if exist('audiogram_fig', 'var') && isvalid(audiogram_fig)
%     close(audiogram_fig);
% end

% Clear channel-specific axes (waveform, FFT, and p-value)
    for ich = 1:4
        % Clear waveform axes
        cla(app.(sprintf('wavAvgFig%d', ich)));
        
        % Clear FFT axes  
        cla(app.(sprintf('fftAvgFig%d', ich)));
        
        % Clear p-value axes
        cla(app.(sprintf('pValTrackerFig%d', ich)));
        
        % Clear accumulated p-value data arrays
        gui_channel_data.pval_x_data{ich} = [];
        gui_channel_data.pval_y_data{ich} = [];
        gui_channel_data.crit_x_data{ich} = [];
        gui_channel_data.crit_y_data{ich} = [];
    end
    
    % Clear single tracker axes
    cla(app.sixtyCycleTrackFig);
    cla(app.stimFreqTrackFig);
    cla(app.doubleFreqTrackFig);

    pause(.25)
    
 %% Step 16: Initialize audiogram figure
% audiogram_fig = figure('Name', 'Audiogram', 'NumberTitle', 'off');
% 
% % Position figure in top right of primary monitor (laptop screen)
% % Get screen size of primary monitor
% screen_size = get(0, 'MonitorPositions');
% primary_monitor = screen_size(1, :); % First row is primary monitor
% primary_width = primary_monitor(3);
% primary_height = primary_monitor(4);
% 
% % Set figure size (adjust as needed)
% fig_width = 400;
% fig_height = 700;
% 
% % Calculate position for top right corner
% fig_x = primary_width - fig_width - 50; % 50px margin from right edge
% fig_y = primary_height - fig_height - 100; % 100px margin from top (accounts for taskbar)
% 
% % Set figure position
% set(audiogram_fig, 'Position', [fig_x, fig_y, fig_width, fig_height]);
% 
% audiogram_axes = axes(audiogram_fig);
% 
% % Set up the axes properties
% xlabel(audiogram_axes, 'Frequency (Hz)');
% ylabel(audiogram_axes, 'Amplitude (dB)');
% title(audiogram_axes, [exp_params.fish_ID, ' Audiogram'], 'Interpreter', 'none');
% 
% % Set axis limits
% xlim(audiogram_axes, [min(stim_params.freqRange) max(stim_params.freqRange)]);
% ylim(audiogram_axes, [stim_params.minAmplitude stim_params.maxAmplitude]);
% 
% % Set custom tick marks every 10 units
% x_ticks = min(stim_params.freqRange):20:max(stim_params.freqRange);
% y_ticks = stim_params.minAmplitude:10:stim_params.maxAmplitude;
% set(audiogram_axes, 'XTick', x_ticks);
% set(audiogram_axes, 'YTick', y_ticks);
% 
% % Flip y-axis so lower amplitudes (better hearing) are at top
% set(audiogram_axes, 'YDir', 'reverse');
% 
% % Enable hold to preserve existing plots
% hold(audiogram_axes, 'on');
% 
% % Optional: Set up grid for better readability
% grid(audiogram_axes, 'on');

%% RUN THE EXPERIMENT

% Validate experiment state before starting
if isempty(frequencies) || isempty(ex) || isempty(tone_waveforms)
    error('Critical experiment variables not properly initialized. Check initialization steps.');
end

fprintf('\n=== EXPERIMENT STARTING ===\n');
fprintf('Frequencies to test: %d\n', length(frequencies));
fprintf('Frequencies with amplitude ranges configured: %d\n', size(ex, 1));
fprintf('Max trials per amplitude: %d\n', maxTrialNum);
fprintf('============================\n');

total_presentations = 0; % Counter for total number of trials presented across whole experiment

try
    %% Outer loop: By Frequency
    for ifreq_index = 1:length(presentation_order)

        %% EDGE CASE VALIDATION: Start of frequency loop
        fprintf('\n=== STARTING FREQUENCY %d/%d ===\n', ifreq_index, length(presentation_order));
        
        ifreq = presentation_order(ifreq_index); %ifreq uses the presentation order
        
        % Get the current frequency index from presentation_order
        % Runtime validation of frequency index (defensive programming)
        if ifreq < 1 || ifreq > length(frequencies)
            error('Runtime error: Invalid frequency index ifreq=%d for frequencies array of length %d', ...
                ifreq, length(frequencies));
        end
        
        current_freq = frequencies(ifreq);        
        app.currentFreqLabel.Text = string(current_freq);
        
        % Start with intial amplitude
        iamp = 1; % Start at the max amplitude
        % Get frequency-specific amplitude range from ex structure
        freq_possible_amplitudes = [];
        for amp_idx = 1:size(ex, 2)
            if ~isempty(ex{ifreq, amp_idx})
                freq_possible_amplitudes(end+1) = ex{ifreq, amp_idx}.amplitude;
            else
                break; % No more amplitudes for this frequency
            end
        end
        
        current_amplitude = freq_possible_amplitudes(iamp);
        blockSize = adapt_params.fft_block_size;
  
        % Validate that this frequency hasn't been tested already (safety check)
        if ifreq_index > 1
            fprintf('Previous frequencies completed: %d\n', ifreq_index - 1);
        end
        
        % Initialize loop_exit_reason for this frequency
        loop_exit_reason = '';

        app.currentAmplitudeLabel.Text = string(current_amplitude);

        % Flag for when we have completed testing this frequency
        frequency_complete = false;

        % Initialize counters for this frequency-amplitude combination
        itrial = 0; % Counter for trials
        app.trialCounterCurrentStim.Text = string(itrial);
        ifft = 0; % Counter for FFT calculations
        app.fftCounter.Text = string(ifft);
        % ispectro = 0; % Counter for spectrogram calculations
        % islope = 0; % Counter for trendline calculations

        % Reset alpha_spent for current stimulus type
        if maxTrialNum < 10
            error('maxTrialNum must be at least 10 for proper alpha_spent allocation');
        end
        alpha_spent = zeros(1, floor(maxTrialNum/10));

        %% Amplitude testing loop - continue until frequency is complete
        while ~frequency_complete && itrial < maxTrialNum
            
            %% Step 1: Create Block of Stimuli 
            try 
                % Create stim set for current FFT Block
                [FFTBlock_stimuli, FFTBlock_stimuli_dur, jitterdur, phaselist, ex, FFTBlock_stimuli_component_dur, mylatency,longestVectorPossible_samps] = ...
                    createStimFFTBlock(ifreq, iamp,...
                    ex, current_amplitude, tone_waveforms, adapt_params, calibration_data, mylatency_samp,fs, blockSize);
            catch ME
                fprintf('ERROR in createStimFFTBlock: %s\n', ME.message);
                fprintf('ifreq=%d, iamp=%d, current_amplitude=%.1f\n', ifreq, iamp, current_amplitude);
                rethrow(ME);
            end

            %% Step 2: Update trial counter and total presentations
            itrial = itrial + adapt_params.fft_block_size;
            app.trialCounterCurrentStim.Text = string(itrial);
            
            total_presentations = total_presentations + adapt_params.fft_block_size;
            app.trialCounterALL.Text = string(total_presentations);

            ifft = ifft + 1;
            app.fftCounter.Text = string(ifft);

            %% Step 3: Collect block of responses
            try
                % Collect trials for FFT analysis and save to ex (i.e., fft block)
                [FFT_block_data, ex]  = collectFFTBlock(FFTBlock_stimuli,...
                    FFTBlock_stimuli_dur, jitterdur, itrial, ifreq, iamp, ifft, rec_params, channel_names, ex, Nchan,fs,FFTBlock_stimuli_component_dur, mylatency,longestVectorPossible_samps);
            catch ME
                fprintf('ERROR in collectFFTBlock: %s\n', ME.message);
                fprintf('itrial=%d, ifreq=%d, iamp=%d, ifft=%d\n', itrial, ifreq, iamp, ifft);
                rethrow(ME);
            end
            
            % Plot hydrophone data GUI
            plot(app.currentWaveformFig,ex{ifreq, iamp}.hydrophone{ifft,end})

            %% Step 4: Calculate running average
            try
                [FFT_block_avgs, ex] = calculateFFTBlock_runavg(FFT_block_data, ifft, Nchan, channel_names, ex, ifreq, iamp);
            catch ME
                fprintf('ERROR in calculateFFTBlock_runavg: %s\n', ME.message);
                fprintf('ifft=%d, ifreq=%d, iamp=%d\n', ifft, ifreq, iamp);
                rethrow(ME);
            end

            %% Step 5: Calculate FFT
            try
                [FFT_block_FFTs, ex] = calculateFFTBlock_FFT(FFT_block_avgs, ifft, Nchan, channel_names, signals_to_track, ex, ifreq, iamp, fs, response_names,current_freq,rec_params);
            catch ME
                fprintf('ERROR in calculateFFTBlock_FFT: %s\n', ME.message);
                fprintf('ifft=%d, ifreq=%d, iamp=%d\n', ifft, ifreq, iamp);
                rethrow(ME);
            end

            % Display progress information
            fprintf('\n=== PROGRESS REPORT ===\n');
            fprintf('Frequency %d/%d: %.1f Hz\n', ifreq_index, length(presentation_order), current_freq);
            fprintf('Amplitude: %.1f dB (%d/%d possible amplitudes)\n', current_amplitude, iamp, length(freq_possible_amplitudes));
            fprintf('Trials at current amplitude: %d\n', itrial);
            fprintf('Total presentations: %d\n', total_presentations);
            fprintf('FFT blocks collected: %d\n', ifft);
            fprintf('=======================\n');

            % Initialize response detection
            any_significant_response = 0;

            %% Step 6: Calculate t-test
            try
            [FFT_block_TTest, any_significant_response, alpha_spent, adapt_params,ex] = ...
                calculateFFTBlock_ttest(ex,ifreq,iamp,ifft, frequencies, current_amplitude, adapt_params, alpha_spent, ...
                    channel_names,FFT_block_FFTs,any_significant_response, maxTrialNum);
            catch ME
                fprintf('ERROR in calculateFFTBlock_ttest: %s\n', ME.message);
                fprintf('ifft=%d, ifreq=%d, iamp=%d\n', ifft, ifreq, iamp);
                rethrow(ME);
            end
            
            % Update GUI
            displayBlock2GUI(app,FFT_block_avgs, FFT_block_FFTs, FFT_block_TTest, Nchan, channel_names, ifft)
            
            % Decision logic
            current_decision = ''; % 'continue_trials', 'next_amplitude', 'next_frequency'
            
            
            if any_significant_response
                %% CASE 1: Response detected
                [audio_y, audio_fs] = audioread('response_detected_sound.mp3');
                sound(audio_y,audio_fs)
                
                fprintf('\n*** RESPONSE DETECTED ***\n');
                fprintf('Frequency: %.1f Hz, Amplitude: %.1f dB\n', current_freq, current_amplitude);
                
                choice = questdlg(['Response detected at frequency ' num2str(current_freq) ' Hz, amplitude ' num2str(current_amplitude) ' dB. ' ...
                    'What would you like to do?'], ...
                    'Response Detected', ...
                    'Collect more trials', ...
                    'Confirm response - test next amplitude', ...
                    'Collect more trials');
                
                % Validate dialog response
                if isempty(choice)
                    % Handle dialog cancellation or failure
                    fprintf('Dialog was cancelled or failed. Defaulting to collect more trials.\n');
                    choice = 'Collect more trials';
                end

                if strcmp(choice, 'Confirm response - test next amplitude')
                    % Mark response for current amplitude
                    ex{ifreq,iamp}.decision = 1;
                    
                    % Check if there are more amplitudes to test BEFORE incrementing
                    if iamp < length(freq_possible_amplitudes)
                        % ATOMIC TRANSACTION: Move to next amplitude
                        try
                            % Step 1: Save current state for potential rollback
                            backup_iamp = iamp;
                            backup_itrial = itrial;
                            backup_ifft = ifft;
                            backup_alpha_spent = alpha_spent;
                            backup_current_amplitude = current_amplitude;
                            
                            % Step 2: Calculate new state values (but don't apply yet)
                            new_iamp = iamp + 1;
                            new_current_amplitude = freq_possible_amplitudes(new_iamp);
                            new_alpha_spent = zeros(1,maxTrialNum/10);
                            new_itrial = 0;
                            new_ifft = 0;
                            
                            % Step 3: Validate all new values before applying ANY changes
                            if new_iamp < 1 || new_iamp > length(freq_possible_amplitudes)
                                error('Amplitude index would be invalid: new_iamp=%d, valid range is 1 to %d', ...
                                    new_iamp, length(freq_possible_amplitudes));
                            end
                            
                            if new_current_amplitude <= 0
                                error('New amplitude would be invalid: %.1f dB', new_current_amplitude);
                            end
                            
                            % Step 4: Apply all changes atomically (all succeed or all fail)
                            iamp = new_iamp;
                            current_amplitude = new_current_amplitude;
                            alpha_spent = new_alpha_spent;
                            itrial = new_itrial;
                            ifft = new_ifft;
                            
                            % Step 5: Update GUI only after internal state is consistent
                            app.trialCounterCurrentStim.Text = string(itrial);
                            app.fftCounter.Text = string(ifft);
                            app.currentAmplitudeLabel.Text = string(current_amplitude);
                            
                            % Step 6: Set decision variables only after everything else succeeds
                            current_decision = 'next_amplitude';
                            loop_exit_reason = 'moved_to_next_amplitude';
                            
                            fprintf('Response confirmed. Testing amplitude %.1f dB.\n', current_amplitude);
                            
                        catch ME
                            % ROLLBACK: Restore previous state if anything failed
                            fprintf('ERROR during amplitude transition: %s\n', ME.message);
                            fprintf('Rolling back to previous state...\n');
                            
                            % Restore all variables to backup values
                            iamp = backup_iamp;
                            itrial = backup_itrial;
                            ifft = backup_ifft;
                            alpha_spent = backup_alpha_spent;
                            current_amplitude = backup_current_amplitude;
                            
                            % Restore GUI to match rolled-back state
                            app.trialCounterCurrentStim.Text = string(itrial);
                            app.fftCounter.Text = string(ifft);
                            app.currentAmplitudeLabel.Text = string(current_amplitude);
                            
                            % Set safe decision
                            current_decision = 'continue_trials';
                            loop_exit_reason = 'amplitude_transition_failed';
                            
                            fprintf('State rolled back successfully. Continuing with current amplitude.\n');
                            
                            % Log the error but don't crash the experiment
                            fprintf('Original error was: %s\n', ME.message);
                        end
                    else
                        % This was the last amplitude - frequency is complete
                        frequency_complete = true;
                        loop_exit_reason = 'all_amplitudes_tested';
                        current_decision = 'next_frequency';
                        fprintf('Response confirmed at final amplitude. All amplitudes tested for frequency %.1f Hz.\n', current_freq);
                    end
                 
                else
                    % Continue collecting trials (default behavior)
                    fprintf('Collecting more trials at current amplitude.\n');
                    current_decision = 'continue_trials';
                end

            else
                %% CASE 2: No response detected
                beep;
                fprintf('\n*** NO RESPONSE DETECTED ***\n');
                fprintf('Frequency: %.1f Hz, Amplitude: %.1f dB\n', current_freq, current_amplitude);

                choice = questdlg(['NO response detected at frequency ' num2str(current_freq) ' Hz, amplitude ' num2str(current_amplitude) ' dB. ' ...
                    'What would you like to do?'], ...
                    'No Response Detected', ...
                    'Collect more trials', ...
                    'Move on to next frequency', ...
                    'Collect more trials');
                
                % Validate dialog response
                if isempty(choice)
                    % Handle dialog cancellation or failure
                    fprintf('Dialog was cancelled or failed. Defaulting to collect more trials.\n');
                    choice = 'Collect more trials';
                end
                
                if strcmp(choice, 'Move on to next frequency')
                    % Mark no response and move on to next frequency
                    ex{ifreq,iamp}.decision = 0;
                    frequency_complete = true;
                    current_decision = 'next_frequency';
                    loop_exit_reason = 'user_skipped_frequency';
                    fprintf('Moving on to next frequency.\n');
                elseif strcmp(choice, 'Collect more trials')
                    % Continue collecting trials (default behavior)
                    current_decision = 'continue_trials';
                    fprintf('Collecting more trials at current amplitude.\n');
                else
                    % Handle unexpected response
                    fprintf('Unexpected dialog response: "%s". Defaulting to collect more trials.\n', string(choice));
                    current_decision = 'continue_trials';
                end
            end

            %% APPLY DECISION
            if strcmp(current_decision, 'continue_trials')
                % Continue collecting trials at current amplitude - no changes needed
                % The while loop will continue to next iteration
            elseif strcmp(current_decision, 'next_frequency')
                % Skip remaining amplitudes and move to next frequency
                frequency_complete = true;
            end
        end
        
        % Check if we exited due to max trials reached
        if itrial >= maxTrialNum && ~frequency_complete
            fprintf('\n*** MAX TRIALS REACHED ***\n');
            fprintf('Frequency: %.1f Hz, Amplitude: %.1f dB\n', current_freq, current_amplitude);
            fprintf('Maximum trials (%d) reached without definitive response.\n', maxTrialNum);
            
            % Mark as no response detected due to max trials
            ex{ifreq,iamp}.decision = 0;
            
            % Set completion flag and reason
            frequency_complete = true;
            loop_exit_reason = 'max_trials_reached';
            current_decision = 'next_frequency';
            
            fprintf('Moving to next frequency due to max trials reached.\n');
        end
        
        % Log why we finished this frequency for debugging
        if ~isempty(loop_exit_reason)
            fprintf('Frequency loop completed due to: %s\n', loop_exit_reason);
        end

        %% Audiogram Plotting
%         [audiogram_fig, audiogram_axes] = displayAudiogram(current_freq, current_amplitude, ...
%             ifreq, iamp, itrial, loop_exit_reason, possible_amplitudes, ex, ...
%             stim_params, exp_params, audiogram_fig, audiogram_axes, ...
%             ifreq_index, presentation_order);
    end  % End of frequency loop

    %% Save 
    % get timestamp
    c = clock;
    datecode = sprintf('%.2d%.2d%.2d',rem(c(1),100),c(2),c(3),c(4),c(5));
    cwd = cd;
    
    cd('C:\Users\AEP\Desktop\Experiments\adaptiveAEP_2025\data');
    
    % apply timestamp
    mysavename = sprintf('%s_%s_%s_%s_run%s.mat',...
        exp_params.fish_ID,...
        exp_params.experiment,...
        datecode,...
        exp_params.run);
    
    fprintf('Saving data...')
    
    % save, report to command line;
    save(mysavename,'ex','exp_params','stim_params','rec_params','adapt_params','-v7.3')
    
    % Save audiogram figure
    figure_savename = sprintf('%s_%s_%s_%s_run%s_audiogram.fig',...
        exp_params.fish_ID,...
        exp_params.experiment,...
        datecode,...
        exp_params.run);
    
%     savefig(audiogram_fig, figure_savename);

    cd(cwd);
    fprintf('Data saved to %s\n',mysavename);

    %% Show that experiment has ended
    fprintf('\n=== EXPERIMENT COMPLETED ===\n');
    fprintf('Total presentations: %d\n', total_presentations);
    fprintf('All frequencies tested successfully!\n');
    fprintf('=============================\n');
 
    toc
    diary off;
catch ME
    % Handle any errors during experiment
    fprintf('\n=== EXPERIMENT ERROR ===\n');
    fprintf('Error: %s\n', ME.message);
    fprintf('Stopped at frequency %d/%d\n', ifreq_index, length(presentation_order));
    fprintf('Total presentations completed: %d\n', total_presentations);
    fprintf('========================\n');

    % Save current state for recovery
        % get timestamp
    c = clock;
    datecode = sprintf('%.2d%.2d%.2d',rem(c(1),100),c(2),c(3),c(4),c(5));
    cwd = cd;
    
    cd('C:\Users\AEP\Desktop\Experiments\adaptiveAEP_2025\data');
    
    % apply timestamp
    mysavename = sprintf('%s_%s_%s_%s_run%s.mat',...
        exp_params.fish_ID,...
        exp_params.experiment,...
        datecode,...
        exp_params.run);
    
    fprintf('Saving data...')
    
    % save, report to command line;
    save(mysavename,'ex','exp_params','stim_params','rec_params','adapt_params','-v7.3')
    
    % Save audiogram figure
    figure_savename = sprintf('%s_%s_%s_%s_run%s_audiogram.fig',...
        exp_params.fish_ID,...
        exp_params.experiment,...
        datecode,...
        exp_params.run);
    
%     savefig(audiogram_fig, figure_savename);

    cd(cwd);
    fprintf('Partial data saved to %s\n',mysavename);
    
    rethrow(ME); % Re-throw error for debugging
    toc
    diary off;
    
end






%   You have made it to the end of V1 of the adaptive code!
%            /`·.¸
%           /¸...¸`:·
%       ¸.·´  ¸   `·.¸.·´)
%      : © ):´;      ¸  {
%       `·.¸ `·  ¸.·´\`·¸)
%           `\\´´\¸.·´

% Below is the frame for the spectrogram based analysis, we will worry
% about this later









%% INTEGRATE POST-PRAGUE
%     %% If we reach this point, no significant response was detected and no user overrides occurred
%     %% Check if we have collected enough trials for spectrogram analysis
%     if itrial >= adapt_params.can_start_spectro
%         % perform spectrogram analysis
%         [waveletResults, FFT_results] = processSpectroBlock[FFT_results]
%
%         % Display spectrogram results onto GUI
%         displaySpectro
%         [ex, spectro_p_value] = checkifResponse_spectro(ex, ifreq, iamp, ispectro,...
%             adapt_params.permutation_count, waveletResults,FFT_results);
%         ispectro = ispectro + 1;
%
%         if spectro_p_value <= adapt_params.pval_threshold
%             % Display user dialog for confirmation
%             beep;
%             user_response = confirmResponseDialog(spectro_p_value, 'Spectrogram');;
%
%             if user_response
%                 % Mark as "Response Present"
%                 ex{ifreq,iamp}.decision = 1;
%
%                 % Move to next amplitude level
%                 iamp = iamp +1;
%
%                 % Check if we have reached the minimum testable amplitude
%                 if iamp > length(possible_amplitudes)
%                     frequency_complete = true;
%                 else
%                     current_amplitude = possible_amplitudes(iamp);
%
%                     % Reset counters for new amplitude
%                     itrial = 0;
%                     ifft = 0;
%                     ispectro = 0;
%                     islope = 0;
%                 end
%                 continue;
%             else
%                 % User rejected ITPC response, ask if user wants more trials
%                 choice = questdlg(['You rejected the ITPC response detection. ' ...
%                     'Would you like to collect more trials at this amplitude?'], ...
%                     'Collect More Trials', 'Yes', 'No', 'Yes');
%                 if isempty(choice) || strcmp(choice, 'No')
%                     % User doesn't want more trials - move to next frequency
%                     frequency_complete = true;
%                     fprintf('User rejected ITPC detection. Moving to next frequency.\n');
%                 else
%                     % User wants more trials at current amplitude
%                     fprintf('Collecting more trials at frequency %.1f Hz, amplitude %.1f dB.\n', ...
%                         current_frequency, current_amplitude);
%                 end
%                 continue;
%             end
%         end
%
%         %% Check if we have enough Spectrogram p-values to evaluate a trendline
%         if ispectro > 0
%             % get the correct spectro spectro_p_value across all channels
%             has_enough_values = false;
%
%             for ch = 1:4
%                 channel_field = ['ch' num2str(ch)];
%
%                 % Skip channels without proper data_structure
%                 if ~isfield(ex{ifreq,iamp}.electrodes,channel_field) || ...
%                         ~isfield(ex{ifreq, iamp}.electrodes.(channel_field), 'spectro_pval') || ...
%                         isempty(ex{ifreq, iamp}.electrodes.(channel_field).spectro_pval)
%                     continue;
%                 end
%
%                 % Check if this channel has enough spectro p values
%                 if length(ex{ifreq, iamp}.electrodes.(channel_field).spectro_pval) >= adapt_params.permutation_N_pval_min
%                     has_enough_values = true;
%                     break;
%                 end
%             end
%
%             if has_enough_values
%                 % Fit trendline to p-values
%                 [trendline_slope, slope_criterion] = evaluateTrendline(ex, ifreq, iamp, ...
%                     islope, adapt_params.pval_threshold, maxTrialNum);
%                 islope = islope +1;
%
%                 % Check if trendline slope suggests no progress toward significance
%                 if trendline_slope > slope_criterion
%                     % Display dialog for user confirmation with detailed information
%                     beep;
%                     user_response = confirmNoResponseDialog_spectro(trendline_slope, slope_criterion, ...
%                         current_frequency, current_amplitude);
%                     if user_response
%                         % User confirmed no response
%                         fprintf('User confirmed NO RESPONSE at frequency %.1f Hz, amplitude %.1f dB.\n', ...
%                             current_frequency, current_amplitude);
%
%                         % Mark as "NO RESPONSE"
%                         ex{ifreq, iamp}.decision = 0;
%
%                         % Move to next frequency
%                         frequency_complete = true;
%                         continue;
%
%                     else
%                         % User wants to continue collecting data despite unfavorable trendline
%                         fprintf(['User chose to continue collecting data at frequency %.1f Hz, ' ...
%                             'amplitude %.1f dB despite unfavorable trendline.\n'], ...
%                             current_frequency, current_amplitude);
%
%                         % Ask if user wants to try a different approach
%                         choice = questdlg(['Would you like to try a different approach?'], ...
%                             'Next Action', 'Continue as is', 'Higher Amplitude', 'Continue as is');
%
%                         if strcmp(choice, 'Higher Amplitude') && iamp > 1
%                             % Try higher amplitude
%                             iamp = iamp - 1;
%                             current_amplitude = possible_amplitudes(iamp);
%
%                             % Reset counters for the new amplitude
%                             itrial = 0;
%                             ifft = 0;
%                             ispectro = 0;
%                             islope = 0;
%
%                             fprintf('Trying again at higher amplitude: %.1f dB\n', current_amplitude);
%
%                         else
%                             % Continue with current settings
%                             fprintf('Continuing data collection with current settings.\n');
%                         end
%                         continue;
%                     end
%
%                 elseif trendline_slope < slope_criterion % The trend line is negative
%                     %#%# create user dialogue to confirm that you would
%                     %like to label this current stimulus as a positive
%                     %response
%                 else
%                     % Trendline shows progress toward significance
%                     fprintf(['Trendline shows progress toward significance (slope = %.4f, criterion = %.4f). ' ...
%                         'Continuing data collection.\n'], trendline_slope, slope_criterion);
%
%                 end
%             end
%         end
%     end
