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
            pass_band = 100;
            testCase.ex.info.signal_quality.pass_band_hz = pass_band;
            
            % Add low frequency drift to one trial
            kept_trials_weighted = testCase.ex.kept.trials_weighted;
            random_trial = randperm(size(kept_trials_weighted,1),1);
            selected_trial = kept_trials_weighted(random_trial,:);

            t = (0:size(selected_trial,2)-1)/testCase.fs; % t is in s so don't use samples!
            low_freqs = [1:95];
            for ifreqs = 1:length(low_freqs)
                current_freq = low_freqs(ifreqs);
                low_freq_drift(ifreqs,:) = sin(t*2*pi*current_freq)*(randn(1)+1);
            end

            combined_drift = sum(low_freq_drift,1);
            selected_trial = combined_drift + selected_trial;
            
            % Put it back into weighted
            kept_trials_weighted(random_trial,:) = selected_trial;
            
            % Calculate fft before filtering
            [~, freq_vec_pre, fft_vals_pre] = calc_fft(kept_trials_weighted(random_trial,:),testCase.fs);

            testCase.ex = filter_signals(testCase.ex);
            kept_trials_filtered = testCase.ex.kept.trials_filtered;
            
            % Calculate fft post filtering
            [~, freq_vec_post, fft_vals_post] = calc_fft(kept_trials_filtered(random_trial,:),testCase.fs);
            
            freq_bin_mask = freq_vec_pre < pass_band;
            pre_selected = fft_vals_pre(freq_bin_mask);
            post_selected = fft_vals_post(freq_bin_mask);

            % For good measure, check that freq_vecs are the same
            testCase.verifyTrue(all(freq_vec_post == freq_vec_pre))
            
            % Make sure there is 99% attenuation below passband
            testCase.verifyLessThanOrEqual(post_selected,pre_selected*0.01); % at least 99% attenuation
        end

        function check_output_dimensions(testCase)
            kept_trials_weighted = testCase.ex.kept.trials_weighted;
            expected_size = size(kept_trials_weighted);
            
            % Run script
            testCase.ex = filter_signals(testCase.ex);
            kept_trials_filtered = testCase.ex.kept.trials_filtered;
            actual_size = size(kept_trials_filtered);

            testCase.verifyEqual(actual_size,expected_size);
        end
    end

end