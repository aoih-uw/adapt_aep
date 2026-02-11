classdef filter_signals_test < matlab.unittest.TestCase
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
            testCase.ex = apply_channel_weights(testCase.ex);
        end

    end

    methods (Test)
        % Test methods

        function verify_no_energy_below_passband(testCase)
            testCase.ex.info.signal_quality.pass_band_hz = 100;
            testCase.ex = filter_signals(testCase.ex);
            kept_trials_filtered = testCase.ex.kept.trials_filtered
            [N, freq_vec, fft_vals] = calc_fft()
            testCase.verifyFail("Unimplemented test");
        end

        function check_output_dimensions(testCase)
            testCase.verifyFail("Unimplemented test");
        end
    end

end