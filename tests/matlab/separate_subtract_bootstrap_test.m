classdef separate_subtract_bootstrap_test < matlab.unittest.TestCase
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
            testCase.ex = stim_block_creation(testCase.ex);
        end

    end

    methods (Test)
        % Test methods

        function identify_present_response(testCase)
            [testCase.ex, mock_data] = create_mock_data(testCase.ex, 1, 0.25);
            testCase.ex.mock_data = mock_data;
            testCase.ex = present_and_measure(testCase.ex, testCase.App);
            testCase.ex = preprocess_signal(testCase.ex, testCase.App);

            % Run script
            testCase.ex = separate_subtract_bootstrap(testCase.ex,testCase.App);

            testCase.verifyEqual(testCase.ex.decision(1).resp_found,1)
        end

        %% SIMLUATION CODE
        % function identify_response_with_modeling(testCase)
        %     mad_criteria = testCase.ex.info.analysis.mad_criteria;
        %     sig_int = linspace(0,0.01,3);
        %     noise_int = 0.5;
        %     % noise_int = linspace(0.1,1,length(sig_int));
        %     completed_one_round = 0;
        % 
        %     for i = 1:length(sig_int)
        %         for ii = 1:length(noise_int)
        %             if i == 1 && ii == 1
        %                 iamp = 1;
        %             else
        %                 iamp = testCase.ex.counter.iamp;
        %             end
        %             while testCase.ex.decision(iamp).resp_found == 0 && testCase.ex.trial_count(iamp) < testCase.ex.info.adaptive.max_trials
        %                 if completed_one_round
        %                     testCase.ex.counter.iblock = testCase.ex.counter.iblock+1;
        %                 end
        %                 [testCase.ex, mock_data] = create_mock_data(testCase.ex, sig_int(i), noise_int(ii));
        %                 testCase.ex.mock_data = mock_data;
        %                 testCase.ex = present_and_measure(testCase.ex, testCase.App);
        %                 testCase.ex = preprocess_signal(testCase.ex, testCase.App);
        % 
        %                 testCase.ex = separate_subtract_bootstrap(testCase.ex,testCase.App);
        %                 fprintf('\nSignal_ratio: %1.2f\nNoise_ratio: %1.2f\nResponse found?: %1.0f\n',sig_int(i), noise_int(ii), testCase.ex.decision(1).resp_found)
        % 
        %                 if sig_int(i) == 0
        %                     testCase.verifyEqual(testCase.ex.decision(1).resp_found,0)
        % 
        %                 elseif sig_int(i) == 1
        %                     testCase.verifyEqual(testCase.ex.decision(1).resp_found,1)
        %                 end
        %                 completed_one_round = 1;
        %             end
        % 
        %             % Assign to trackers
        %             if testCase.ex.decision(iamp).resp_found == 0
        %                 testCase.ex.model.doub_freq_diff_vec = [testCase.ex.model.doub_freq_diff_vec {testCase.ex.model.doub_freq_diff_vec_temp}];
        %                 testCase.ex.model.doub_freq_dur_vec = [testCase.ex.model.doub_freq_dur_vec {testCase.ex.model.doub_freq_dur_vec_temp}];
        %                 testCase.ex.model.noise_floor = [testCase.ex.model.noise_floor {testCase.ex.model.noise_floor_temp}];
        %             end
        % 
        %             cur_sig(i,ii) = sig_int(i);
        %             cur_reps_needed(i,ii) = testCase.ex.trial_count(iamp) ;
        %             cur_noise(i,ii) = noise_int(ii);
        %             resp_result(i,ii) = testCase.ex.decision(end).resp_found;
        % 
        %             % Reset block
        %             testCase.ex = setup_block(testCase.ex);
        %             testCase.ex.counter.iblock = 0; % reset for next SNR
        %             completed_one_round = 0;
        %             testCase.ex.counter.iamp = testCase.ex.counter.iamp+1;
        %             testCase.ex = stim_block_creation(testCase.ex);
        %         end
        %     end
        % 
        %     figure;
        %     mean_2f_values = cellfun(@mean, testCase.ex.model.doub_freq_diff_vec);
        %     sig_flat = reshape(cur_sig', [], 1);
        %     noise_flat = reshape(cur_noise', [], 1);
        %     scatter(1:length(mean_2f_values), mean_2f_values, 20 + 60*noise_flat, sig_flat, 'filled');
        %     colorbar;
        %     noise_floor_medians = cellfun(@median, testCase.ex.model.noise_floor);
        %     noise_floor_mads = cellfun(@mad, testCase.ex.model.noise_floor);
        %     thres_criterias = noise_floor_medians + noise_floor_mads*1.4826*4;
        %     [~,idx] = min(thres_criterias);
        %     select_noise_floor = testCase.ex.model.noise_floor{idx};
        %     noise_floor_median = median(select_noise_floor);
        %     noise_floor_mad = mad(select_noise_floor);
        %     hold on;
        %     x_fill = [0, length(mean_2f_values), length(mean_2f_values), 0];
        %     y_fill = [noise_floor_median - mad_criteria*1.4826*noise_floor_mad, noise_floor_median - mad_criteria*1.4826*noise_floor_mad, ...
        %         noise_floor_median + mad_criteria*1.4826*noise_floor_mad, noise_floor_median + mad_criteria*1.4826*noise_floor_mad];
        %     fill(x_fill, y_fill, tableau_10('purple'), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        %     yline(noise_floor_median, 'k--');
        %     ylabel(colorbar, 'Signal level');
        %     grid on;
        %     title('2f diff Amplitude for each SNR')
        %     hold off;
        % 
        %     figure;
        %     heatmap(noise_int,sig_int,cur_reps_needed);
        %     xlabel('Noise level')
        %     ylabel('Signal level')
        %     title('Trials needed to detect response')

        % end
    end


end

