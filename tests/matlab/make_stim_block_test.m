classdef make_stim_block_test < matlab.unittest.TestCase

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
        function check_correct_trial_num(testCase)
            ex = create_mock_ex();
            ex.info.adaptive.trials_per_block = 40;
            expected_rows = ex.info.adaptive.trials_per_block;

            % Necessary for code to run
            ex.info.recording.latency_samples = 100;
            ex.info.stimulus.correction_factor_sf = 1;

            ex = make_tone_burst(ex);
            result = make_stim_block(ex);

            [actual_rows, ~] = size(result.block(1).stimulus_block);

            testCase.verifyEqual(actual_rows, expected_rows);
        end


        function check_trial_waveform_frequency(testCase)
            % check that the orginal waveform center frequency has not changed
            ex = create_mock_ex();
            fs = ex.info.recording.sampling_rate_hz;

            % Necessary for code to run
            ex.info.recording.latency_samples = 100;
            ex.info.stimulus.correction_factor_sf = 1;
            ex.info.stimulus.frequency_hz = 200;

            ex = make_tone_burst(ex);
            result = make_stim_block(ex);
            stimulus = result.block(1).stimulus_block(1,:);

            [N, freq_vec, fft_vals] = calc_fft(stimulus,fs);

            [~, peak_idx] = max(fft_vals);
            plot(freq_vec,fft_vals)
            hold on;
            xline(freq_vec(peak_idx))

            peak_freq = freq_vec(peak_idx);
            testCase.verifyEqual(peak_freq, ex.info.stimulus.frequency_hz, 'AbsTol', fs/N);

        end

        function check_trial_scaled_amplitude(testCase)
            % check that the amplitude of the trial signals are properly
            % scaled
            ex = create_mock_ex();

            % Necessary for code to run
            ex.info.recording.latency_samples = 100;
            ex.info.stimulus.correction_factor_sf = .5;
            ex.info.stimulus.frequency_hz = 200;
            ex.info.stimulus.amplitude_spl = 130;

            ex = make_tone_burst(ex);
            result = make_stim_block(ex);
            stimulus = result.block(1).stimulus_block(1,:);

            expected_scaling = apply_stim_amp_scaling(ex.info.stimulus.amplitude_spl, ...
                ex.info.stimulus.correction_factor_sf, ex.info.stimulus.waveform);

            expected_amplitude = rms(expected_scaling);
            actual_amplitude = rms(stimulus);

            testCase.verifyEqual(actual_amplitude, expected_amplitude, 'AbsTol', 0.01);
        end

        function check_60_cycle_selection(testCase)
            % were the points selected sufficiently random, and the number
            % of points selected the same as the number of trials?
            ex = create_mock_ex();
            ex.info.adaptive.trials_per_block = 40;
            expected_rows = ex.info.adaptive.trials_per_block;
            fs = ex.info.recording.sampling_rate_hz;

            % Necessary for code to run
            ex.info.recording.latency_samples = 100;
            ex.info.stimulus.correction_factor_sf = 1;

            ex = make_tone_burst(ex);
            result = make_stim_block(ex);
            jitter_samples = result.block(1).jitter;

            % Check the number of rows
            [actual_rows, ~] = size(jitter_samples);
            testCase.verifyEqual(actual_rows, expected_rows, 'AbsTol', 0.01);

            % Check 2: All values within valid range (1 to one 60Hz cycle)
            max_jitter_sample = 1/60*fs;
            testCase.verifyGreaterThan(min(jitter_samples),0)
            testCase.verifyLessThanOrEqual(max(jitter_samples),max_jitter_sample)

            % Check 3: Are the jitter values sufficiently random?
            testCase.verifyGreaterThan(std(jitter_samples),0)
        end

        function check_even_phase_alt(testCase)
            % Ensure that there are equal numbers of + and - phase signals
            % in the block of trials
            ex = create_mock_ex();
            ex.info.adaptive.trials_per_block = 40;
            expected_split = ex.info.adaptive.trials_per_block/2;

            % Necessary for code to run
            ex.info.recording.latency_samples = 100;
            ex.info.stimulus.correction_factor_sf = 1;

            ex = make_tone_burst(ex);
            result = make_stim_block(ex);
            stimulus_block = result.block(1).stimulus_block;
            jitter_block = result.block(1).jitter;
            waveform_length = length(ex.info.stimulus.waveform);

            % Extract periods
            idx = ones(ex.info.adaptive.trials_per_block,1) + jitter_block + waveform_length*ones(ex.info.adaptive.trials_per_block,1);

            for itrial = 1:height(stimulus_block)
                stimulus_dur{itrial} = stimulus_block(itrial,idx(itrial):idx(itrial)+waveform_length-1);
            end

            for itrial = 1:height(stimulus_block)
                waveform = stimulus_dur{itrial};
                mask(itrial) = waveform(:,2) > 0;
            end

            testCase.verifyEqual(sum(mask), expected_split)
        end


        function check_dur_period_start(testCase)
            % check that the dur period starts where expected
            ex = create_mock_ex();
            ex.info.recording.latency_samples = 100;
            latency = ex.info.recording.latency_samples;
            ex.info.stimulus.correction_factor_sf = 1;

            ex = make_tone_burst(ex);
            result = make_stim_block(ex);

            jitter = result.block(1).jitter(1);
            stimulus = result.block(1).stimulus_block(1,:);
            waveform_length = length(ex.info.stimulus.waveform);

            % Extract periods
            idx = 1;
            stimulus_jitter = stimulus(idx:jitter);
            idx = jitter + 1;
            stimulus_pre = stimulus(idx:idx+waveform_length-1);
            idx = idx + waveform_length;
            stimulus_dur = stimulus(idx:idx+waveform_length-1);
            idx = idx + waveform_length;
            stimulus_pos = stimulus(idx:idx+waveform_length-1);
            idx = idx + waveform_length;
            stimulus_latency = stimulus(idx:idx+latency-1);

            % Ensure that pre, dur, and post have exact same lengths
            testCase.verifyEqual(length(stimulus_pre), waveform_length);
            testCase.verifyEqual(length(stimulus_dur), waveform_length);
            testCase.verifyEqual(length(stimulus_pos), waveform_length);

            % Verify zero periods
            testCase.verifyEqual(sum(abs(stimulus_jitter)), 0);
            testCase.verifyEqual(sum(abs(stimulus_pre)), 0);
            testCase.verifyEqual(sum(abs(stimulus_pos)), 0);
            testCase.verifyEqual(sum(abs(stimulus_latency)), 0);

            % Verify dur has amplitude
            testCase.verifyGreaterThan(sum(abs(stimulus_dur)), 0);

        end

        function check_odd_trials_error(testCase)
            ex = create_mock_ex();
            ex.info.adaptive.trials_per_block = 41;
            ex.info.recording.latency_samples = 100;
            ex.info.stimulus.correction_factor_sf = 1;

            ex = make_tone_burst(ex);

            testCase.verifyError(@() make_stim_block(ex), 'make_stim_block:oddTrials');
        end

    end

end