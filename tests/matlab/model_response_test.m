classdef model_response_test < matlab.unittest.TestCase
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

        function unimplementedTest(testCase)
            sig_int = [1 0.5 0.25 0.01 0.2 0.02 0 0 0 0 0 0 0];
            noise_int = 0.75;
            % noise_int = linspace(0.1,1,length(sig_int));
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

                        testCase.ex = separate_subtract_bootstrap(testCase.ex,testCase.App);
                        fprintf('\nSignal_ratio: %1.2f\nNoise_ratio: %1.2f\nResponse found?: %1.0f\n',sig_int(i), noise_int(ii), testCase.ex.decision(1).resp_found)
                        completed_one_round = 1;
                    end
                    
                    cur_snr = 20*log10(sig_int(i)/noise_int(ii));
                    if cur_snr == -Inf
                        cur_snr =  datasample(-25:-15, 1);
                    end
                    testCase.ex.snr_vec = [testCase.ex.snr_vec  cur_snr];

                    % Assign to trackers
                    if testCase.ex.decision(iamp).resp_found == 0
                        testCase.ex.model.doub_freq_diff_vec = [testCase.ex.model.doub_freq_diff_vec {testCase.ex.model.doub_freq_diff_vec_temp}];
                        testCase.ex.model.noise_floor = [testCase.ex.model.noise_floor {testCase.ex.model.noise_floor_temp}]; % (trials x stimulus amplitude)
                    end

                    %% Model the response
                    if length(testCase.ex.snr_vec) >= 3
                        testCase.ex = model_response(testCase.ex, testCase.App);
                    end

                    %% Reset block
                    testCase.ex = setup_block(testCase.ex);
                    testCase.ex.counter.iblock = 0; % reset for next SNR
                    completed_one_round = 0;
                    testCase.ex.counter.iamp = testCase.ex.counter.iamp+1;
                    testCase.ex = make_stim_block(testCase.ex);
                end
            end
        end
    end

end