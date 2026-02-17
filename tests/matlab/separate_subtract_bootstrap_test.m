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
            mock_data = create_mock_data(testCase.ex, 1, 0.25);
            testCase.ex.mock_data = mock_data;
            testCase.ex = present_and_measure(testCase.ex, testCase.App);
            testCase.ex = reject_artefacts(testCase.ex,testCase.App);
            testCase.ex = apply_channel_weights(testCase.ex);
            testCase.ex = filter_signals(testCase.ex);

            % Run script
            testCase.ex = separate_subtract_bootstrap(testCase.ex,testCase.App);

            testCase.verifyEqual(testCase.ex.decision(1).resp_found,1)
        end

        function identify_response(testCase)
            sig_int = linspace(0,0.2,15);
            noise_int = linspace(0.1,1,length(sig_int));
            for i = 1:length(sig_int)
                for ii = 1:length(noise_int)
                    while testCase.ex.decision(1).resp_found == 0 || testCase.ex.trial_count(end) > testCase.ex.info.adaptive.max_trials
                        mock_data = create_mock_data(testCase.ex, sig_int(i), noise_int(ii));
                        testCase.ex.mock_data = mock_data;
                        testCase.ex = present_and_measure(testCase.ex, testCase.App);
                        testCase.ex = reject_artefacts(testCase.ex,testCase.App);
                        testCase.ex = apply_channel_weights(testCase.ex);
                        testCase.ex = filter_signals(testCase.ex);

                        % Run script
                        testCase.ex = separate_subtract_bootstrap(testCase.ex,testCase.App);
                        fprintf('\nSignal_ratio: %1.2f\nNoise_ratio: %1.2f\nResponse found?: %1.0f\n',sig_int(i), noise_int(ii), testCase.ex.decision(1).resp_found)

                        if sig_int(i) == 0
                            testCase.verifyEqual(testCase.ex.decision(1).resp_found,0)
                            
                        elseif sig_int(i) == 1
                            testCase.verifyEqual(testCase.ex.decision(1).resp_found,1)
                        end

                        testCase.ex.counter.iblock = testCase.ex.counter.iblock + 1;
                    end
                        cur_sig(i,ii) = sig_int(i);
                        cur_reps_needed(i,ii) = testCase.ex.counter.iblock*testCase.ex.info.adaptive.trials_per_block;
                        cur_noise(i,ii) = noise_int(ii);
                        resp_result(i,ii) = testCase.ex.decision(1).resp_found;
                        % Reset block
                        ex = setup_block(ex);
                        testCase.ex.counter.iblock = 1; % reset for next SNR
                        testCase.ex.counter.iamp = testCase.ex.counter.iamp+1;
                end
            end
            heatmap(noise_int,sig_int,resp_result);
            xlabel('Noise level')
            ylabel('Signal level')
        end

end


    end

