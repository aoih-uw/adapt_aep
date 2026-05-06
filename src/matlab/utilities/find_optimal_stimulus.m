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
test_cycles = 0;

% Select which frequencies and durations to test
freqs_hz = [40 100 400];
num_cycles = 6;
if test_cycles
    ramp_cycles = [1 2 3 4 5 6];
else
    ramp_ms = [20 60 100 140 180 220];
end

full_amp_ms = num_cycles'./freqs_hz*1000; % Calculate the outer product (row = num cycles, column = freq)

for ifreq = 1:length(freqs_hz)
    ex.info.stimulus.frequency_hz = freqs_hz(ifreq);
    cur_freq = ex.info.stimulus.frequency_hz;
    for idur = 1:length(num_cycles)
        ex.info.stimulus.full_amplitude_duration_ms = full_amp_ms(idur,ifreq);
        for iramp = 1:length(ramp_ms)
            if test_cycles
                cur_ramp_cycles = ramp_cycles(iramp);
                ramp_durs_ms(ifreq,idur,iramp) = (1/cur_freq)*cur_ramp_cycles*1e3;
                ex.info.stimulus.ramp_duration_ms = ramp_durs_ms(ifreq,idur,iramp);
            else
                ex.info.stimulus.ramp_duration_ms = ramp_ms(iramp);
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

            % Analyze data
            % Get stimulus frequency amplitude
            freq_vec = ex.info.calibration.freq_vec;
            % Define a region
            selected_idx = freq_vec > 1 & freq_vec < cur_freq*3;
            freq_vec = freq_vec(selected_idx);
            fft_vals = ex.info.calibration.fft_vals(selected_idx); % mean already calculated
            
            my_snr = calculate_fft_snr(fft_vals,freq_vec, cur_freq, target_freq_range,0);
            
            score_median(idur,iramp,ifreq) = my_snr;

        end
    end
end

%% Plot data
figure;
tiledlayout(1,3)
for ifreq = 1:length(freqs_hz)
    for idur = 1:length(num_cycles)
        if test_cycles
            xvec = squeeze(ramp_durs_ms(ifreq,idur,:));
        else
            xvec = ramp_ms;
        end
        nexttile
        plot(xvec ,score_median(:,:,ifreq),'o-')
        hold on;
        xlabel('Ramp (ms)');
        ylabel('SNR (dB)');
        yscale('log')
        title(string(freqs_hz(ifreq)+string(' Hz')))
        grid on;
    end
end

linkaxes

end
