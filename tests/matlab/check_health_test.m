classdef check_health_test < matlab.unittest.TestCase
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
            testCase.ex = make_experiment_tone_burst(testCase.ex);
            testCase.ex = stim_block_creation(testCase.ex);
        end

    end

    methods (Test)
        % Test methods
        function healthy_response(testCase)
            health_dir = fullfile('\\wsl$\ubuntu\home\aoih\adapt_aep', 'data', 'health');
            filename = fullfile(health_dir, [testCase.ex.info.health.filename_root '_health_baseline.mat']);
            if isfile(filename)
                delete(filename);
            end
            [testCase.ex, mock_data] = create_mock_data(testCase.ex, 1, 0.25);
            testCase.ex.mock_data = mock_data;
            testCase.ex = check_health(testCase.ex, testCase.App);
            testCase.verifyEqual('good',testCase.ex.health(1).status)
        end

        function unhealthy_response(testCase)
            baseline_2f_mag = 1;
            health_dir = fullfile('\\wsl$\ubuntu\home\aoih\adapt_aep', 'data', 'health');
            filename = fullfile(health_dir, [testCase.ex.info.health.filename_root '_health_baseline.mat']);
            if isfile(filename)
                delete(filename);
                save(filename, 'baseline_2f_mag')
            end
            [testCase.ex, mock_data] = create_mock_data(testCase.ex, 0, 0.25);
            testCase.ex.mock_data = mock_data;
            testCase.ex = check_health(testCase.ex, testCase.App);
            testCase.verifyEqual('poor',testCase.ex.health(1).status)
        end

        function multiple_health_checks(testCase)
            health_dir = fullfile('\\wsl$\ubuntu\home\aoih\adapt_aep', 'data', 'health');
            filename = fullfile(health_dir, [testCase.ex.info.health.filename_root '_health_baseline.mat']);
            if isfile(filename)
                delete(filename);
            end
            health_sigs = linspace(1,0.5,5);
            for itry = 1:length(health_sigs)
                cur_health = health_sigs(itry);
                [testCase.ex, mock_data] = create_mock_data(testCase.ex, cur_health, 0.25);
                testCase.ex.mock_data = mock_data;
                testCase.ex = check_health(testCase.ex, testCase.App);
            end
        end
    end

end