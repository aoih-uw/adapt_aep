% posthoc_ekg
cd 'F:\2026\Research\May Midshipman\2026_06_02\porichthys_notatus_16_20260602'
addpath(genpath('\\wsl.localhost\ubuntu\home\aoih\adapt_aep\src\matlab'))

% Assign vars
subjid_vec = {16};
stim_freq = 110;
stim_amp = [];
file_type = 'raw_data';
fs = 44100/3;

% EKG signal vars
minDist = fs*.5;
min_peak_height = 2;

for isubj = 1:length(subjid_vec)
    % Get filename
    subjid = subjid_vec{isubj};
    my_names = get_file_names(subjid, stim_freq, stim_amp, file_type);

    % Gather EKG data
    grand_ekg_sigs = [];
    grand_time_stamps = [];
    for iname = 1:length(my_names)
        current_file = my_names{iname};
        [ex, cur_freq, cur_amp] = load_my_file(current_file, iname, my_names);
        freq_vec(iname) = cur_freq;
        amp_vec(iname) = cur_amp;
        n_batches = size(ex.health,2);

        for ibatch = 1:n_batches
            ekg_sigs{ibatch} = ex.health(ibatch).electrodes_microV;
            time_stamps(ibatch) = ex.health(ibatch).time_stamp;
        end

        grand_ekg_sigs{iname} = ekg_sigs;
        grand_time_stamps{iname} = time_stamps;
    end

    db = 1;

    % Select which data points to include
    total_n_sigs = length(grand_ekg_sigs{iname});
    to_exclude = [7,8];
    to_include = 1:total_n_sigs;
    for i = 1:length(to_exclude)
        cur_exc = to_exclude(i);
        to_include(cur_exc) = [];
    end
    

    ekg_fig = figure;
    tiledlayout('flow','TileSpacing','tight','Padding','tight');
    for iname = 1:length(my_names)
        ekg_sigs = grand_ekg_sigs{iname};
        time_stamps = grand_time_stamps{iname};
        for isig = 1:length(ekg_sigs)
            cur_sig = ekg_sigs{isig};
            cur_time_stamp = time_stamps(isig);
            sig_len_s = length(cur_sig)/fs;
            cur_sig = smoothdata(cur_sig, 'movmean', 500);
            peak_threshold = max(2, prctile(cur_sig,95));

            % Measure spikes per second
            [pks, locs] = findpeaks(cur_sig, 'MinPeakHeight', peak_threshold, 'MinPeakDistance', minDist);
            num_spikes = numel(pks);
            ekg_rate(isig*iname) = (num_spikes/sig_len_s)*60;
            ekg_timestamp(isig*iname) = cur_time_stamp;


            % Plop
            if length(my_names)*length(ekg_sigs) >=30
                if mod(iname*isig, 10) == 0
                    nexttile
                    t = (0:length(cur_sig)-1) / fs;
                    plot(t, squeeze(cur_sig(1,:,1)), 'k-', 'LineWidth', 0.5);
                    hold on;
                    plot(t(locs), pks, 'rv', 'MarkerFaceColor', 'r');
                    xlabel('Time (s)'); ylabel('EKG (\muV)');
                    title(datestr(time_stamps(isig), 'HH:MM:SS'))
                    grid on; xlim([0 t(end)]); drawnow;
                end

            else
                nexttile
                t = (0:length(cur_sig)-1) / fs;
                plot(t, squeeze(cur_sig(1,:,1)), 'k-', 'LineWidth', 0.5);
                hold on;
                plot(t(locs), pks, 'rv', 'MarkerFaceColor', 'r');
                xlabel('Time (s)'); ylabel('EKG (\muV)');
                title(datestr(time_stamps(isig), 'HH:MM:SS'))
                grid on; xlim([0 t(end)]); drawnow;
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

end