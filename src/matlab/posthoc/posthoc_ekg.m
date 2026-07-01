% posthoc_ekg
addpath(genpath('\\wsl.localhost\ubuntu\home\aoih\adapt_aep\src\matlab'))

% Assign vars
subjid_vec = {16};
stim_freq = 110;
stim_amp = [];
file_type = 'raw_data';
fs = 14700;

% EKG signal vars
minDist = fs*.5;
min_peak_height = 2;

for isubj = 1:length(subjid_vec)
    ekg_fig = figure;
    for iname = 1:size(my_names{:},2)
        N_batches = size(grand_ex_save{iname,isubj}.health,2);
        for ibatch = 1:N_batches
            tiledlayout(4,1,'TileSpacing','tight','Padding','tight');

            % Get signal
            cur_sig = grand_ex_save{iname,isubj}.health(ibatch).electrodes_microV;
            cur_time_stamp = grand_ex_save{iname,isubj}.health(ibatch).time_stamp;
            sig_len_s = length(cur_sig)/fs;

            % Plot
            nexttile
            plot((0:length(cur_sig)-1)./fs,cur_sig);
            title('Raw')

            % Smooth signal
            cur_sig_smooth = smoothdata(cur_sig, 'movmean', 500);
            nexttile
            plot((0:length(cur_sig)-1)./14700,cur_sig_smooth,'LineWidth',2); hold off;
            title('Smoothed')

            
            % Filter signal
            cur_sig_filt = bandpassfilter(cur_sig_smooth,5,15,4,fs);
            nexttile
            plot((0:length(cur_sig)-1)./14700,cur_sig_filt,'LineWidth',2); hold off;
            title('Filtered')
            linkaxes

            % Square signal
            cur_sig_sq= cur_sig_filt.^2;
            nexttile
            plot((0:length(cur_sig)-1)./14700,cur_sig_sq,'LineWidth',2); hold off;
            title('Squared')
            

            peak_threshold = max(2, prctile(cur_sig,95));

            % Measure spikes per second
            [pks, locs] = findpeaks(cur_sig, 'MinPeakHeight', peak_threshold, 'MinPeakDistance', minDist);
            num_spikes = numel(pks);
            ekg_rate(ibatch*iname) = (num_spikes/sig_len_s)*60;
            ekg_timestamp(ibatch*iname) = cur_time_stamp;
            close all

        end
    end
end
[sort_time, sort_idx] = sort(ekg_timestamp);
sort_rate = ekg_rate(sort_idx);

valid = ~isnat(sort_time);
sort_times = sort_time(valid);
sort_rate  = sort_rate(valid);

figure;
plot(sort_times, sort_rate, '-o','LineWidth',2)
ylim([0,100])
xlabel('Time')
ylabel('EKG rate')
title(sprintf('Subject %d EKG Rate', subjid))
grid on


