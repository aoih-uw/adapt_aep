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
            testCase.ex = make_stim_block(testCase.ex);
        end

    end

    methods (Test)
        % Test methods

        function identify_present_response(testCase)
            [testCase.ex, mock_data] = create_mock_data(testCase.ex, 1, 0.25);
            testCase.ex.mock_data = mock_data;
            testCase.ex = present_and_measure(testCase.ex, testCase.App);
            testCase.ex = reject_artefacts(testCase.ex,testCase.App);
            testCase.ex = apply_channel_weights(testCase.ex);
            testCase.ex = filter_signals(testCase.ex);

            % Run script
            testCase.ex = separate_subtract_bootstrap(testCase.ex,testCase.App);

            testCase.verifyEqual(testCase.ex.decision(1).resp_found,1)
        end

        function identify_response_with_modeling(testCase)
            sig_int = linspace(0,.1,2);
            noise_int = linspace(0.1,1,length(sig_int));
            completed_one_round = 0;
            for i = 1:length(sig_int)
                for ii = 1:length(noise_int)
                    if i == 1 && ii == 1
                        iamp = 1;
                    else
                        iamp = testCase.ex.counter.iamp;
                    end
                    while testCase.ex.decision(iamp).resp_found == 0 && testCase.ex.trial_count(iamp) < testCase.ex.info.adaptive.max_trials
                        if completed_one_round
                            testCase.ex.counter.iblock = testCase.ex.counter.iblock+1;
                        end

                        [testCase.ex, mock_data] = create_mock_data(testCase.ex, sig_int(i), noise_int(ii));
                        testCase.ex.mock_data = mock_data;
                        testCase.ex = present_and_measure(testCase.ex, testCase.App);
                        testCase.ex = reject_artefacts(testCase.ex,testCase.App);
                        testCase.ex = apply_channel_weights(testCase.ex);
                        testCase.ex = filter_signals(testCase.ex);

                        % Run script only if have at least 40 trials
                        if testCase.ex.trial_count(iamp) >= testCase.ex.info.adaptive.min_trials_needed_for_analysis
                            testCase.ex = separate_subtract_bootstrap(testCase.ex,testCase.App);
                            fprintf('\nSignal_ratio: %1.2f\nNoise_ratio: %1.2f\nResponse found?: %1.0f\n',sig_int(i), noise_int(ii), testCase.ex.decision(1).resp_found)

                            if sig_int(i) == 0
                                testCase.verifyEqual(testCase.ex.decision(1).resp_found,0)

                            elseif sig_int(i) == 1
                                testCase.verifyEqual(testCase.ex.decision(1).resp_found,1)
                            end
                        end
                        completed_one_round = 1;
                    end

                    % Assign to trackers
                    if testCase.ex.decision(iamp).resp_found == 0
                        testCase.ex.model.doub_freq_resp_mV = [testCase.ex.model.doub_freq_resp_mV {testCase.ex.model.doub_freq_resp_mV_temp}];
                    end

                    tmp_data = testCase.ex.model.doub_freq_resp_mV{iamp};
                    tmp_median = median(tmp_data);
                    tmp_mad = median(abs(tmp_data-tmp_median));
                    cur_median(i,ii) = tmp_median;
                    cur_mad(i,ii) = tmp_mad;
                    
                    cur_sig(i,ii) = sig_int(i);
                    cur_reps_needed(i,ii) = testCase.ex.trial_count(iamp) ;
                    cur_noise(i,ii) = noise_int(ii);
                    resp_result(i,ii) = testCase.ex.decision(end).resp_found;

                    % Reset block
                    testCase.ex = setup_block(testCase.ex);
                    testCase.ex.counter.iblock = 0; % reset for next SNR
                    completed_one_round = 0;
                    testCase.ex.counter.iamp = testCase.ex.counter.iamp+1;
                    testCase.ex = make_stim_block(testCase.ex);
                end
            end
            figure;
            heatmap(noise_int,sig_int,cur_reps_needed);
            xlabel('Noise level')
            ylabel('Signal level')
            title('Trials needed to detect response')

            figure;
            heatmap(noise_int,sig_int,cur_median);
            xlabel('Noise level')
            ylabel('Signal level')
            title('Median 2f amplitude')

            figure;
            heatmap(noise_int,sig_int,cur_mad);
            xlabel('Noise level')
            ylabel('Signal level')
            title('Median Absolute Deviation (MAD) 2f amplitude')
        end

    end


end

