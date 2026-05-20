function find_optimal_stimulus
% Initialize
addpath(genpath('C:\Users\AEP\Desktop\adapt_aep\src\matlab'))
ex = setup_ex();
ex.info.animal.subject_ID = 1;
ex.info.animal.sex = 'F';
ex.info.stimulus.type = 'Tone Burst';
ex.info.adaptive.response_feature = 'Double Frequency';
ex.info.adaptive.max_trials = 300;
ex = setup_hardware(ex);
target_freq_range = ex.info.analysis.range_2f_hz;
test_cycles = 1;
fs = 44100;
% Select which frequencies and durations to test
freqs_hz = 1000:10:1100; 
num_cycles = 6;
if test_cycles
    ramp_cycles = 6;
else
    ramp_ms = [20 60 100 140 180 220];
end

full_amp_ms = num_cycles'./freqs_hz*1000; % Calculate the outer product (row = num cycles, column = freq)
score_mean = NaN(length(num_cycles), length(ramp_cycles), length(freqs_hz));

% Prep plots
fig_f = figure; tiledlayout('flow','TileSpacing','tight','Padding','tight');
fig_t = figure; tiledlayout('flow','TileSpacing','tight','Padding','tight');

for ifreq = 1:length(freqs_hz)
    ex.info.stimulus.frequency_hz = freqs_hz(ifreq);
    cur_freq = ex.info.stimulus.frequency_hz;
    for idur = 1:length(num_cycles)
        desired_freq_res = 5; %fs/N = 5
        min_req_samples = ceil(fs/desired_freq_res);
        ex.info.stimulus.full_amplitude_duration_ms = max(full_amp_ms(idur,ifreq),min_req_samples/fs*1e3);
        for iramp = 1:length(ramp_cycles)
            if test_cycles
                cur_ramp_cycles = ramp_cycles(iramp);
                ramp_durs_ms(ifreq,idur,iramp) = (1/cur_freq)*cur_ramp_cycles*1e3;
                ex.info.stimulus.ramp_duration_ms = max(50, ramp_durs_ms(ifreq,idur,iramp));
            else
                ex.info.stimulus.ramp_duration_ms = ramp_cycles(iramp);
            end

            ex.info.animal.filename_root = sprintf('%s_%d_%gHz', ...
                ex.info.animal.species_name, ...
                ex.info.animal.subject_ID, ...
                ex.info.stimulus.frequency_hz);
            
            ex = make_stimulus_template(ex);

            % Run the calibration app
            calibration_app = calibrate_stimulus();

            % Initialize it with ex
            calibration_app.initializeWithEx(ex);

            t = timer('StartDelay', 0.1, 'TimerFcn', @(varargin) calibration_app.runCalibrate());            start(t);
            uiwait(calibration_app.UIFigure);  % now listening before button fires
            delete(t);

            % Get the updated ex back
            ex = calibration_app.ex;

            % Clean up
            delete(calibration_app)

            % Post Stim ON portion
            wave_samps = length(ex.info.stimulus.waveform);
            pre_samps = fs*0.1;
            post_stim_ON_idx = wave_samps+pre_samps+2118; % 2118 is latency

            % Analyze data
            if ex.info.calibration.check_passed
                time_vec = ex.info.calibration.time_vector;
                time_sig = ex.info.calibration.time_sig;
                post_stim_ON_sig = time_sig(1,post_stim_ON_idx:end);
                post_stim_ON_rms(ifreq,iramp,idur) = rms(post_stim_ON_sig);

                freq_vec = ex.info.calibration.freq_vec;
                selected_idx = freq_vec > 1 & freq_vec < 5000;
                freq_vec = freq_vec(selected_idx);
                fft_vals = ex.info.calibration.fft_vals(selected_idx);
                
                figure(fig_f); nexttile; plot(freq_vec, fft_vals); title(sprintf('%g Hz', cur_freq)); xlabel('Frequency (Hz)'); ylabel('Magnitude');
                linkaxes
                xlim([0,1000])
                figure(fig_t); nexttile; plot(time_vec, time_sig); title(sprintf('%g Hz', cur_freq)); xlabel('Time (s)'); ylabel('Amplitude');
                linkaxes
                
                score_mean(idur,iramp,ifreq) = calculate_fft_snr(fft_vals, freq_vec, cur_freq, target_freq_range, 0, 0);
            else
                figure(fig_t); nexttile; title(sprintf('%g Hz (failed)', cur_freq));
                linkaxes
                figure(fig_f); nexttile; title(sprintf('%g Hz (failed)', cur_freq));
                linkaxes
            end

        end
    end
end

cd('C:\Users\AEP\Desktop\adapt_aep\data\tank_acoustics')

% Build filename suffix from freqs_hz (e.g. "40_5_60")
freq_start = freqs_hz(1);
freq_step  = freqs_hz(2) - freqs_hz(1);
freq_stop  = freqs_hz(end);
suffix = sprintf('%g_%g_%g', freq_start, freq_step, freq_stop);

% Save time-domain and FFT figures from the sweep
savefig(fig_t, sprintf('time_%s.fig', suffix));
savefig(fig_f, sprintf('fft_%s.fig',  suffix));

% Plot ringing data
fig_ring = figure;
plot(freqs_hz, squeeze(post_stim_ON_rms), 'o-', 'LineWidth', 2);
title('Post Stim ON RMS: A measure of ringing');
xlabel('Stimulus frequency (Hz)'); ylabel('RMS amplitude mV');
savefig(fig_ring, sprintf('ring_%s.fig', suffix));

% Plot rms data
fig_snr = figure;
plot(freqs_hz, squeeze(score_mean), 'o-', 'LineWidth', 2);
title('SNR'); xlabel('Stimulus frequency (Hz)'); ylabel('SNR (dB)');
savefig(fig_snr, sprintf('snr_%s.fig', suffix));

% %% Plot data
% figure;
% tiledlayout(1,3)
% for ifreq = 1:length(freqs_hz)
%     for idur = 1:length(num_cycles)
%         if test_cycles
%             xvec = squeeze(ramp_durs_ms(ifreq,idur,:));
%         else
%             xvec = ramp_ms;
%         end
%         nexttile
%         plot(xvec ,score_mean(:,:,ifreq),'o-')
%         hold on;
%         xlabel('Ramp (ms)');
%         ylabel('SNR (dB)');
%         yscale('log')
%         title(string(freqs_hz(ifreq)+string(' Hz')))
%         grid on;
%     end
% end
% 
% linkaxes
% 
% end
