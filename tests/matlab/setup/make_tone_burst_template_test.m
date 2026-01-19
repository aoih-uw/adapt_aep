classdef make_tone_burst_template_test < matlab.unittest.TestCase

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
    end

    methods (Test)
        % Test methods

        function test_expected_stimulus_dur(testCase)
            % Test that total stimulus duration matches expected value
            ex = create_mock_ex();
            ex.info.stimulus.full_amplitude_duration_ms = 100;
            ex.info.stimulus.ramp_duration_ms = 10;
            
            expected_dur_ms = ex.info.stimulus.full_amplitude_duration_ms + ...
                (ex.info.stimulus.ramp_duration_ms*2);

            result = make_tone_burst_template(ex);
         
            actual_dur_ms = result.info.stimulus.total_stimulus_duration_ms;
            
            % Allow small tolerance for rounding error
            testCase.verifyEqual(actual_dur_ms, expected_dur_ms,'RelTol', 0.01);

        end

        function test_expected_ramp_sizes(testCase)
            % Test that ramps have correct number of samples
            ex = create_mock_ex();
            ex.info.stimulus.ramp_duration_ms = 5;
            
            fs = ex.info.recording.sampling_rate_hz;
            expected_sample_length = round((ex.info.stimulus.ramp_duration_ms/1000)*fs);

            result = make_tone_burst_template(ex);
            waveform = result.info.stimulus.waveform;

            % Check ramp-up
            ramp_up = waveform(1:expected_sample_length);
            testCase.verifyEqual(abs(ramp_up(1)),0,'AbsTol',1e-10);
            testCase.verifyGreaterThan(abs(ramp_up(end)),0);

            % Check ramp-down
            ramp_down = waveform(end-expected_sample_length+1:end);
            testCase.verifyGreaterThan(abs(ramp_down(1)),0);
            testCase.verifyEqual(abs(ramp_down(end)),0, 'AbsTol',1e-10);
        end

        function test_stimulus_frequency(testCase)
            % test that the stimulus has the correct center frequency
            ex = create_mock_ex();
            ex.info.stimulus.frequency_hz = 100;

            result = make_tone_burst_template(ex);
            
            waveform = result.info.stimulus.waveform;
            fs = result.info.recording.sampling_rate_hz;
            stim_freq = ex.info.stimulus.frequency_hz;

            N = length(waveform);
            fft_result = abs(fft(waveform));
            freq_vec = (0:N-1) * (fs/N); %# fs/N = Hz per bin, learn the math for this!

            [~, peak_idx] = max(fft_result(1:floor(N/2))); % first half has only positive frequencies (?)
            detect_freq = freq_vec(peak_idx);

            testCase.verifyEqual(detect_freq, stim_freq, 'AbsTol', fs/N); % tolerance within one bin
        end

        function test_output_is_row_vector(testCase)
            % Ensure that the waveform is a row vector
            ex = create_mock_ex();
            result = make_tone_burst_template(ex);

            waveform = result.info.stimulus.waveform;
            testCase.verifyEqual(size(waveform,1),1);
        end

        function test_nyquist_limit_error(testCase)
            % Test that frequency above Nyquist throws error
            ex = create_mock_ex();
            ex.info.recording.sampling_rate_hz = 1000;
            ex.info.stimulus.frequency_hz = 30000;

            testCase.verifyError(@() make_tone_burst_template(ex), 'make_tone_burst_template:NyquistViolation');
        end

        function test_invalid_duration_error(testCase)
            % test that zero duration throws error
            ex = create_mock_ex();
            ex.info.stimulus.full_amplitude_duration_ms = 0;

            testCase.verifyError(@() make_tone_burst_template(ex), 'make_tone_burst_template:InvalidDuration');
        end

        function test_waveform_amplitude(testCase)
            ex = create_mock_ex();
            result = make_tone_burst_template(ex);

            fs = ex.info.recording.sampling_rate_hz;
            ramp_samp = round((ex.info.stimulus.ramp_duration_ms/1000) * fs);
            full_amp_samp = round((ex.info.stimulus.full_amplitude_duration_ms/1000)*fs);

            waveform = result.info.stimulus.waveform;

            % Extract full amplitude portion
            middle_section = waveform(ramp_samp+1:ramp_samp+full_amp_samp);

            testCase.verifyGreaterThan(max(abs(middle_section)), 0.95);
        end
    end

end