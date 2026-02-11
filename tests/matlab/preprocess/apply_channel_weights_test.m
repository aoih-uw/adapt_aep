classdef apply_channel_weights_test < matlab.unittest.TestCase
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
        function launchApp(testCase)
            testCase.App = adapt_aep;
            testCase.addTeardown(@delete, testCase.App);
            drawnow;
        end

        function set_up_ex(testCase)
            testCase.ex = create_mock_ex();
            testCase.fs = testCase.ex.info.recording.sampling_rate_hz;
            testCase.ex.info.stimulus.frequency_hz = 100;
            testCase.ex.info.stimulus.amplitude_spl = 170;
            testCase.ex = make_tone_burst_template(testCase.ex);
            testCase.ex = make_stim_block(testCase.ex);
            mock_data = create_mock_data(testCase.ex, 1, 0.5);
            testCase.ex.mock_data = mock_data;
            testCase.ex = present_and_measure(testCase.ex, testCase.App);
            testCase.ex = reject_artefacts(testCase.ex,testCase.App);
        end

    end

    methods (Test)
        % Test methods

        function correct_weights_applied(testCase)
            N_channels = testCase.ex.info.channels.n_channels;
            channel_vec = testCase.ex.kept.channels;
            kept_trials = testCase.ex.kept.trials;

            % Set expected variances
            variances = [1 2 3 4];
            inverse_variance = 1./variances;
            normal_inverse_var = inverse_variance/sum(inverse_variance);
            idx = 1;
            for ichan = 1:N_channels
                channel_idx = channel_vec == ichan;
                current_sigs = kept_trials(channel_idx,:);
                mean_sig = mean(current_sigs,1,'omitnan'); % First across trials
                var_sig = var(current_sigs,0,1,'omitnan'); % First across trials
                mean_mean_sig = mean(mean_sig); % Then across columns
                mean_var_sig = mean(var_sig); % Then across columns
                target_var = variances(ichan);
                kept_trials(idx:idx+sum(channel_idx)-1,:) = (current_sigs - mean_mean_sig) * sqrt(target_var / mean_var_sig) + mean_mean_sig; %# understand this math!
                idx = idx+sum(channel_idx);
            end

            % Get variances after alteration
            for ichan = 1:N_channels
                channel_idx = channel_vec == ichan;
                current_sigs = kept_trials(channel_idx,:);
                var_sig = var(current_sigs,0,1,'omitnan'); % First across trials
                mean_var_sig(ichan) = mean(var_sig);
            end

            % Run script
            testCase.ex.kept.trials = kept_trials;
            testCase.ex = apply_channel_weights(testCase.ex);
            channel_weight_vec = testCase.ex.kept.weight_vec;

            % Get variances after weighting
            for ichan = 1:N_channels
                channel_idx = channel_vec == ichan;
                current_sigs = testCase.ex.kept.trials_weighted(channel_idx,:);
                var_sig = var(current_sigs,0,1,'omitnan'); % First across trials
                mean_var_sig_weighted(ichan) = mean(var_sig);
            end

            expected_weights = mean_var_sig_weighted./ mean_var_sig;

            % Check
            testCase.verifyEqual(channel_weight_vec,normal_inverse_var,'AbsTol', 0.01)
            testCase.verifyEqual(sum(channel_weight_vec),1,'AbsTol', 0.01)
            testCase.verifyEqual(channel_weight_vec.^2,expected_weights,'AbsTol', 0.01)
        end

        function check_output_dimensions(testCase)
            expected_size = size(testCase.ex.kept.trials);
            testCase.ex = apply_channel_weights(testCase.ex);
            output_size = size(testCase.ex.kept.trials_weighted);
            testCase.verifyEqual(output_size,expected_size)
        end
    end

end