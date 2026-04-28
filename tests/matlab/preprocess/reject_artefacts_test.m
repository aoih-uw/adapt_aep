classdef reject_artefacts_test < matlab.unittest.TestCase
    properties
        ex
        fs
        App
    end
    
    methods (TestClassSetup)
        % Shared setup for the entire test class
        function add_src_to_path(testCase)
            % Define repo root
            repoRoot = '\\wsl$\ubuntu\home\aoih\adapt_aep';
            % Build full paths
            srcPath = fullfile(repoRoot, 'src', 'matlab');
            helpersPath = fullfile(repoRoot, 'tests', 'matlab', 'helpers');
            % Add paths
            addpath(genpath(srcPath))
            addpath(helpersPath)
            % Clean up
            testCase.addTeardown(@() rmpath(genpath(srcPath)));
            testCase.addTeardown(@() rmpath(helpersPath));
        end
    end
    
    methods (TestMethodSetup)
        % Setup for each test
        function set_up_ex(testCase)
            testCase.ex = create_mock_ex();
            testCase.fs = testCase.ex.info.recording.sampling_rate_hz;
            testCase.ex.info.stimulus.frequency_hz = 100;
            testCase.ex.info.stimulus.amplitude_spl = 170;
            testCase.ex = make_experiment_tone_burst(testCase.ex);
        end

        function launchApp(testCase)
            testCase.App = adapt_aep;
            testCase.addTeardown(@delete, testCase.App);
            drawnow;
        end
    end
    
    methods (Test)
        % Test methods
        function artefact_trials_correctly_removed(testCase)
            testCase.ex = stim_block_creation(testCase.ex);
            N_channels = testCase.ex.info.channels.n_channels;
            rejection_threshold_sd = testCase.ex.info.signal_quality.rejection_threshold_sd;
            testCase.ex.info.signal_quality.rejection_threshold_mV = 100;
            [ex, mock_data] = create_mock_data(testCase.ex, 1, 0.5);
            testCase.ex.mock_data = mock_data;
            testCase.ex = present_and_measure(testCase.ex, testCase.App);
            responses = testCase.ex.raw(1).electrodes;
            
            % Corrupt 2 trials from each channel
            phase_vec = testCase.ex.block(1).phase_vec;
            pos_corrupt = find(phase_vec == 1, 1, 'first');
            neg_corrupt = find(phase_vec == -1, 1, 'first');
            trials_to_corrupt = [pos_corrupt neg_corrupt];
            for ichan = 1:N_channels
            responses(trials_to_corrupt,:,ichan) = ...
                responses(trials_to_corrupt,:,ichan) + randn(length(trials_to_corrupt),size(responses,2))*50;
            end

            testCase.ex.raw(1).electrodes = responses;

            % Calculate expected rejected artefacts
            responses_flattened = reshape(responses, [], size(responses,2));
            responses_rms = rms(responses_flattened, 2);
            responses_median = median(responses_rms,1);
            responses_mad = median(abs(responses_median-responses_rms));
            rej_thresh_val = responses_median + rejection_threshold_sd * responses_mad * 1.4826;
            expected_kept_trials = sum(responses_rms < rej_thresh_val);

            % Run script
            testCase.ex = reject_artefacts(testCase.ex,testCase.App);
            actual_kept_trials = size(testCase.ex.kept.trials,1);

            testCase.verifyEqual(actual_kept_trials, expected_kept_trials);
        end

        function equal_phases_kept(testCase)
            for iblock_it = 0:9
            testCase.ex.counter.iblock = iblock_it;
            testCase.ex = stim_block_creation(testCase.ex);
            iblock = testCase.ex.counter.iblock;
            N_channels = testCase.ex.info.channels.n_channels;
            rejection_threshold_sd = testCase.ex.info.signal_quality.rejection_threshold_sd;
            testCase.ex.info.signal_quality.rejection_threshold_mV = 100;
            [ex, mock_data] = create_mock_data(testCase.ex, 1, 0.5);
            testCase.ex.mock_data = mock_data;
            testCase.ex = present_and_measure(testCase.ex, testCase.App);
            responses = testCase.ex.raw(1).electrodes;

            % Corrupt 2 trials from each channel
            phase_vec = testCase.ex.block(1).phase_vec;
            pos_corrupt = find(phase_vec == 1, 1, 'first');
            neg_corrupt = find(phase_vec == -1, 1, 'first');
            trials_to_corrupt = [pos_corrupt neg_corrupt];
            for ichan = 1:N_channels
                responses(trials_to_corrupt,:,ichan) = ...
                    responses(trials_to_corrupt,:,ichan) + randn(length(trials_to_corrupt),size(responses,2))*50;
            end

            testCase.ex.raw(iblock).electrodes = responses;
            
            % Run script and check that the phases sum to 0
            testCase.ex = reject_artefacts(testCase.ex,testCase.App);
            end
            testCase.verifyEqual(sum(testCase.ex.kept.phases), 0);
        end

        function crazy_large_values_dialog_works(testCase)
            testCase.ex = stim_block_creation(testCase.ex);
            N_channels = testCase.ex.info.channels.n_channels;
            rejection_threshold_sd = testCase.ex.info.signal_quality.rejection_threshold_sd;
            [ex, mock_data] = create_mock_data(testCase.ex, 1, 0.5);
            testCase.ex.mock_data = mock_data;
            testCase.ex = present_and_measure(testCase.ex, testCase.App);
            responses = testCase.ex.raw(1).electrodes;
            
            % Corrupt 2 trials from each channel
            phase_vec = testCase.ex.block(1).phase_vec;
            pos_corrupt = find(phase_vec == 1, 1, 'first');
            neg_corrupt = find(phase_vec == -1, 1, 'first');
            trials_to_corrupt = [pos_corrupt neg_corrupt];
            for ichan = 1:N_channels
            responses(trials_to_corrupt,:,ichan) = ...
                responses(trials_to_corrupt,:,ichan) + randn(length(trials_to_corrupt),size(responses,2))*50;
            end

            testCase.ex.raw(1).electrodes = responses;

            % Mock the warning dialog to prevent blocking
            testCase.addTeardown(@() set(0, 'DefaultFigureVisible', 'on'));
            set(0, 'DefaultFigureVisible', 'off');  % Suppress dialog

            % Run function - should trigger warning without error
            testCase.verifyWarningFree(@() reject_artefacts(testCase.ex));
        end

        function check_output_dimensions_multi_iblock(testCase)
            block_iterations = 10;
            for iamp = 1:10
                for iblock_it = 0:block_iterations-1
                    testCase.ex.counter.iamp = iamp;
                    testCase.ex.counter.iblock = iblock_it;
                    testCase.ex = stim_block_creation(testCase.ex);
                    iblock = testCase.ex.counter.iblock;
                    N_channels = testCase.ex.info.channels.n_channels;
                    trials_per_block = testCase.ex.info.adaptive.trials_per_block;
                    testCase.ex.info.signal_quality.rejection_threshold_mV = 100;
                    [testCase.ex, mock_data] = create_mock_data(testCase.ex, 1, 0.5);
                    testCase.ex.mock_data = mock_data;
                    testCase.ex = present_and_measure(testCase.ex, testCase.App);
                    responses = testCase.ex.raw(1).electrodes;

                    % Corrupt 2 trials from each channel
                    phase_vec = testCase.ex.block(1).phase_vec;
                    pos_corrupt = find(phase_vec == 1, 1, 'first');
                    neg_corrupt = find(phase_vec == -1, 1, 'first');
                    trials_to_corrupt = [pos_corrupt neg_corrupt];
                    for ichan = 1:N_channels
                        responses(trials_to_corrupt,:,ichan) = ...
                            responses(trials_to_corrupt,:,ichan) + randn(length(trials_to_corrupt),size(responses,2))*50;
                    end

                    testCase.ex.raw(iblock).electrodes = responses;

                    % Run script and check that the phases sum to 0
                    testCase.ex = reject_artefacts(testCase.ex,testCase.App);
                end

                % rel_reject_threshold
                expected_size = [1 block_iterations];
                actual_size = size([testCase.ex.preprocess(iamp).rel_reject_threshold{:}]);
                testCase.verifyEqual(expected_size,actual_size)

                % N_trials_presented
                expected_size = [1 block_iterations];
                actual_size = size([testCase.ex.preprocess(iamp).N_trials_presented{:}]);
                testCase.verifyEqual(expected_size,actual_size)

                % reject_rate
                expected_size = [1 block_iterations];
                actual_size = size([testCase.ex.preprocess(iamp).reject_rate{:}]);
                testCase.verifyEqual(expected_size,actual_size)

                % Correct rejection rate?
                expected_reject_rate = length(trials_to_corrupt)/trials_per_block;
                actual_reject_rate = testCase.ex.preprocess(iamp).reject_rate{end};
                testCase.verifyEqual(expected_reject_rate,actual_reject_rate)
                
                % 'Kept' variables
                total_rows = (block_iterations*trials_per_block*N_channels);
                expected_size = total_rows - (total_rows*expected_reject_rate);

                % kept_trials
                actual_size = size(testCase.ex.kept.trials,1);
                testCase.verifyEqual(expected_size,actual_size)

                % kept_phases
                actual_size = size(testCase.ex.kept.phases,1);
                testCase.verifyEqual(expected_size,actual_size)

                % kept_jitter
                actual_size = size(testCase.ex.kept.jitter,1);
                testCase.verifyEqual(expected_size,actual_size)

                % kept_trials_channels
                actual_size = size(testCase.ex.kept.channels,1);
                testCase.verifyEqual(expected_size,actual_size)

                % Reset ex structure for new iamp
                testCase.ex.raw = testCase.ex.raw(1);
                testCase.ex.raw.hydrophone = NaN;
                testCase.ex.raw.electrodes = NaN;
                testCase.ex.raw.time_stamp = NaN;

                testCase.ex.block = struct();
                testCase.ex.block(1).water_temp_C = NaN;
                testCase.ex.block(1).jitter = NaN;
                testCase.ex.block(1).phase_vec = NaN;
                testCase.ex.block(1).stimulus_block = NaN;
            end
        end

        function GUI_properly_updated(testCase)
            testCase.ex = stim_block_creation(testCase.ex);
            N_channels = testCase.ex.info.channels.n_channels;
            testCase.ex.info.signal_quality.rejection_threshold_mV = 100;
            [testCase.ex, mock_data] = create_mock_data(testCase.ex, 1, 0.5);
            testCase.ex.mock_data = mock_data;
            testCase.ex = present_and_measure(testCase.ex, testCase.App);
            responses = testCase.ex.raw(1).electrodes;

            % Corrupt 2 trials from each channel to create a known reject rate
            phase_vec = testCase.ex.block(1).phase_vec;
            pos_corrupt = find(phase_vec == 1, 1, 'first');
            neg_corrupt = find(phase_vec == -1, 1, 'first');
            trials_to_corrupt = [pos_corrupt neg_corrupt];
            for ichan = 1:N_channels
                responses(trials_to_corrupt,:,ichan) = ...
                    responses(trials_to_corrupt,:,ichan) + randn(length(trials_to_corrupt),size(responses,2))*50;
            end

            testCase.ex.raw(1).electrodes = responses;

            % Run reject_artefacts
            testCase.ex = reject_artefacts(testCase.ex, testCase.App);

            % Get expected reject rate
            expected_reject_rate = testCase.ex.preprocess(1).reject_rate{end};
            expected_text = sprintf('%.1f%%', expected_reject_rate * 100);

            % Verify GUI label was updated correctly
            actual_text = testCase.App.Label_rejection_rate.Text;
            testCase.verifyEqual(actual_text, expected_text);
        end

    end
end