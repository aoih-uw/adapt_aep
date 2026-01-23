classdef present_and_measure_test < matlab.unittest.TestCase

    methods (TestMethodSetup)
        function add_src_to_path(testCase)
            repoRoot = '\\wsl$\ubuntu\home\aoih\adapt_aep';
            srcPath = fullfile(repoRoot, 'src', 'matlab');
            helpersPath = fullfile(repoRoot, 'tests', 'matlab', 'helpers');

            addpath(genpath(srcPath))
            addpath(helpersPath)

            testCase.addTeardown(@() rmpath(genpath(srcPath)));
            testCase.addTeardown(@() rmpath(helpersPath));
        end
    end

    methods (Test)
        % Test methods
        function test_output_dimensions(testCase)
            n_trials = 20;
            ex = create_mock_ex();
            ex.counter.iblock = 1;
            ex.info.stimulus.frequency_hz = 100; % will be treated as double freq. response here...
            ex.info.stimulus.amplitude_spl = 140;
            ex.info.adaptive.trials_per_block = n_trials;
            snr_dB = 0;
            n_channels = size(ex.info.recording.DAC_input_channel_names,2);

            mock_data = create_mock_data(ex,snr_dB);
            ex.mock_data = mock_data;
            ex = present_and_measure(ex);
            n_samples = size(ex.mock_data,2);

            % Verify output dimensions
            testCase.verifySize(ex.raw(1).hydrophone, [n_trials, n_samples]);
            testCase.verifySize(ex.raw(1).loopback, [n_trials, n_samples]);
            testCase.verifySize(ex.raw(1).electrodes, [n_trials, n_samples, n_channels-2]);
        end

        function test_main_frequency(testCase)
            ex = create_mock_ex();
            fs = ex.info.recording.sampling_rate_hz;
            ex.counter.iblock = 1;
            ex.info.stimulus.frequency_hz = 100; % will be treated as double freq. response here...
            ex.info.stimulus.amplitude_spl = 140;
            snr_dB = [-15 -10 -5 0 5 10 15];

            max_val_snr_vec = zeros(1,length(snr_dB));

            for isnr = 1:length(snr_dB)
                mock_data = create_mock_data(ex,snr_dB(isnr));
                ex.mock_data = mock_data;
                ex = present_and_measure(ex);

                selected_sig = ex.raw(1).electrodes(1,:,1);

                [N, freq_vec, fft_vals] = calc_fft(selected_sig, fs);

                [max_val,max_idx] = max(fft_vals);
                noise_floor = true(1,length(fft_vals));
                exclusion_idx = max_idx-5:max_idx+5;
                noise_floor(exclusion_idx) = 0;
                max_val_snr_vec(isnr) = max_val/mean(fft_vals(noise_floor));
                max_freq = freq_vec(max_idx);

                figure()
                plot(freq_vec,fft_vals);
                hold on;
                xline(max_freq)

                testCase.verifyEqual(max_freq,ex.info.stimulus.frequency_hz, 'AbsTol', fs/N); % Tolerance is 1 bin
            end
            figure()
            plot(snr_dB, max_val_snr_vec,'o-')
        end
    end

end