classdef make_tone_burst_test < matlab.unittest.TestCase

    methods (TestClassSetup)
        % Shared setup for the entire test class
        function add_src_to_path(testCase)

            srcPath = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'src');
            addpath(genpath(srcPath));
            
            % Add helpers folder to path
            helpersPath = fullfile(fileparts(mfilename('fullpath')), 'helpers');
            addpath(helpersPath);

        end
    end

    methods (TestMethodSetup)
        % Setup for each test
    end

    methods (Test)
        % Test methods

        function test_expected_stimulus_dur(testCase)
            % Test that total stimulus duration matches expected value
            ex = create_mock_ex();
            result = make_tone_burst(ex);

            % Calculate expected duration
            % Allow small tolerance for rounding error
            testCase.verifyEqual(actual_dur_ms, expected_dur_ms,'RelTol', 0.01);

        end

        function test_expected_ramp_sizes(testCase)
            % Test that ramps have correct number of samples
            ex = create_mock_ex();
            result = make_tone_burst(ex);

            % Check ramp-up
            % Check ramp-down
        end

        function test_stimulus_frequency(testCase)
            ex = create_mock_ex();
            

        function unimplementedTest(testCase)
            testCase.verifyFail("Unimplemented test");
        end
    end

end