classdef present_and_measure_test < matlab.unittest.TestCase
    
    properties
        App  % Add this property declaration
    end
    
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
        
        function launchApp(testCase)
            testCase.App = adapt_aep;
            testCase.addTeardown(@delete, testCase.App);
            drawnow;
        end
    end
    
    methods (Test)
        function test_output_dimensions(testCase)
            n_trials = 20;
            ex = create_mock_ex();
            ex.info.stimulus.frequency_hz = 100;
            ex.info.stimulus.amplitude_spl = 170; % set at 170 dB for mock_data scaling of stimulus_block to start from 1
            ex.info.adaptive.trials_per_block = n_trials;
            signal_scaling = 1;
            noise_scaling = 0.25;
            n_channels = size(ex.info.recording.DAC_input_channel_names,2);
            ex = make_experiment_tone_burst(ex);
            ex = stim_block_creation(ex);
            [ex, mock_data] = create_mock_data(ex,signal_scaling,noise_scaling);
            ex.mock_data = mock_data;
            ex = present_and_measure(ex, testCase.App);  % Use testCase.App
            n_samples = size(ex.mock_data,2);
            
            testCase.verifySize(ex.raw(1).hydrophone, [n_trials, n_samples]);
            testCase.verifySize(ex.raw(1).loopback, [n_trials, n_samples]);
            testCase.verifySize(ex.raw(1).electrodes, [n_trials, n_samples, n_channels-2]);
        end
        
        function test_main_frequency(testCase)
            ex = create_mock_ex();
            fs = ex.info.recording.sampling_rate_hz;
            ex.info.stimulus.frequency_hz = 100;
            ex.info.stimulus.amplitude_spl = 170;
            ex = make_experiment_tone_burst(ex);
            ex = stim_block_creation(ex);
            signal_scaling = 0:0.1:1;
            noise_scaling = 0.1:0.1:1;
            
            isnr = 0;
            for isignal = 1:length(signal_scaling)
                cur_signal_scaling = signal_scaling(isignal);
                for inoise = 1:length(noise_scaling)
                    isnr = isnr + 1;
                    cur_noise_scaling = noise_scaling(inoise);
                    [ex, mock_data] = create_mock_data(ex,cur_signal_scaling, cur_noise_scaling);
                    ex.mock_data = mock_data;
                    ex = present_and_measure(ex, testCase.App);
                    selected_sig = ex.raw(1).electrodes(1,:,1);
                    [N, freq_vec, fft_vals] = calc_fft(selected_sig, fs);
                    [max_val,max_idx] = max(fft_vals); % Select max point (i.e., 2f response) in fft output
                    noise_floor = true(1,length(fft_vals)); % Define noise_floor as all other points other than 2f +/- 1 samples above and below
                    exclusion_idx = max_idx-1:max_idx+1; % Where the 2f response is (1 sample buffer)
                    noise_floor(exclusion_idx) = 0;
                    df_snr(isnr) = max_val/mean(fft_vals(noise_floor));
                    snr_vec(isnr) = 20*log(cur_signal_scaling/cur_noise_scaling);
                    max_freq = freq_vec(max_idx);

                    if signal_scaling(isignal) == 1 & noise_scaling(inoise) == 0.1
                        testCase.verifyEqual(max_freq, ex.info.stimulus.frequency_hz, 'AbsTol', fs/N);
                    end
                end
            end
            figure;
            [snr_vec_sorted, snr_vec_sorted_idx] = sort(snr_vec);
            df_snr_sorted = df_snr(snr_vec_sorted_idx);
            plot(snr_vec_sorted,df_snr_sorted,'o-')
            title('2f response relative amplitude')
            xlabel('SNR (dB)')
            ylabel('2f response relative amplitude value')
        end
        
        function testPlotsExist(testCase)
            ex = create_mock_ex();
            signal_scaling = 1;
            noise_scaling = 0.25;
            ex = make_experiment_tone_burst(ex);
            ex = stim_block_creation(ex);
            [ex, mock_data] = create_mock_data(ex,signal_scaling,noise_scaling);
            ex.mock_data = mock_data;
            ex = present_and_measure(ex, testCase.App);  % Use testCase.App
            drawnow;
            
            testCase.verifyNotEmpty(testCase.App.UIAxes_hydrophone.Children);
            
            electrode_axes = {testCase.App.UIAxes_ch1, testCase.App.UIAxes_ch2, testCase.App.UIAxes_ch3, testCase.App.UIAxes_ch4};
            for ch = 1:ex.info.channels.n_channels
                testCase.verifyNotEmpty(electrode_axes{ch}.Children);
            end
        end
    end
end