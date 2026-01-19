classdef present_and_measure_test < matlab.unittest.TestCase
    properties % Variables that can be used between functions in this test case
        mock_data
        mock_dir
    end

    methods (TestMethodSetup)
        function setup_mock_present_sound(testCase)
            testCase.mock_dir = tempname;
            mkdir(testCase.mock_dir);
            mock_file = fullfile(testCase.mock_dir, 'present_sound.m');
            fid = fopen(mock_file, 'w');
            fprintf(fid, 'function rec_data_mV = present_sound(~, ~, ~, ~)\n');
            fprintf(fid, '  global MOCK_DATA;\n');
            fprintf(fid, '  rec_data_mV = MOCK_DATA;\n');
            fprintf(fid, 'end\n');
            fclose(fid);
            addpath(testCase.mock_dir, '-begin');
        end

        function add_src_to_path(testCase)
            repoRoot = '\\wsl$\ubuntu\home\aoih\adapt_aep';
            srcPath = fullfile(repoRoot, 'src', 'matlab');
            helpersPath = fullfile(repoRoot, 'tests', 'matlab', 'helpers');

            addpath(genpath(srcPath))
            addpath(helpersPath)

            % Ensure mock is on top
            addpath(testCase.mock_dir, '-begin');

            % Clear any cached version of present_sound
            clear present_sound present_and_measure

            % Force MATLAB to refresh its path cache
            rehash path

            testCase.addTeardown(@() rmpath(genpath(srcPath)));
            testCase.addTeardown(@() rmpath(helpersPath));
        end
    end

    methods (TestMethodTeardown)
        function cleanupMock(testCase)
            rmpath(testCase.mock_dir);
            rmdir(testCase.mock_dir, 's');
        end
    end


    methods (Test)
        % Test methods

        function test_output_dimensions(testCase)
            global MOCK_DATA;
            % DEBUG: Check which present_sound will be called
            which present_sound

            % Clear cached function
            clear present_sound

            testCase.addTeardown(@() clear('global', 'MOCK_DATA'));
            ex = create_mock_ex();
            ex.counter.iblock = 1;
            ex.info.stimulus.frequency_hz = 100; % will be treated as double freq. response here...
            ex.info.stimulus.amplitude_spl = 140;
            ex.info.adaptive.trials_per_block = 20;
            snr_dB = 0;

            MOCK_DATA = create_mock_data(ex,snr_dB);

            % TEST: Call mock directly to verify it works
            test_result = present_sound([], [], [], []);
            disp('Mock test result size:');
            disp(size(test_result));

            ex = present_and_measure(ex);

            % Verify output dimensions
            testCase.verifySize(ex.raw(1).hydrophone, [n_trials, n_samples]);
            testCase.verifySize(ex.raw(1).loopback, [n_trials, n_samples]);
            testCase.verifySize(ex.raw(1).electrodes, [n_trials, n_samples, n_channels-2]);
        end
    end

end