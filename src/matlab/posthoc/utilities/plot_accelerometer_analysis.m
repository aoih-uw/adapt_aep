%% plot_accelerometer_analysis
% Preallocate
ON_1f = NaN(max_trials,1,numel(stim_freqs),numel(largest_amp_vec),numel(my_chans));
OFF_1f = NaN(max_trials,1,numel(stim_freqs),numel(largest_amp_vec),numel(my_chans));

%% Plot donuts...dB RMS
figure;
names = ['Z'; 'Y'; 'X'];
my_colors = [tableau_10('red'); tableau_10('green'); tableau_10('purple')];
amp_idx = find(largest_amp_vec == max(stim_amps{ifreq}));
cur_data = squeeze(accel_dB_per_dim(:,:,amp_idx,:)); % n_trials,freq_idx, amp_idx, xyz dim)
cur_data = 10.^(cur_data./20).*1e-6; % convert back to linear units for this, dBs wont add up to a whole like you want since it compresses the numbers
% RMS now we are back to m per s squared, make sure to multiply the 1e-6!!!
cur_data = squeeze(mean(cur_data,1,'omitnan'));
hold on;
b = bar(cur_data,'stacked');
alphas = [1 0.3 0.05];   % X, Y, Z (Z is the darkest)
for k = 1:numel(b)
    b(k).FaceColor = 'flat';
    b(k).CData = my_colors;   % row i = color of bar i
    b(k).FaceAlpha = alphas(k);
end
legend(names,'box','off')
title('Acceleration per dimension and stimulus frequency')
xlabel('Stimulus Frequency (Hz)')
ylabel('Acceleration (m/s^2)')
xticks(1:3)
xticklabels({'55', '100', '410'})

%% Plot dB Comparisons and Impedance
figure;
tiledlayout(1,3,'TileSpacing','tight','Padding','tight');
colororder([tableau_10('blue'); tableau_10('orange')])

% Plot Hydrophone Amplitudes
nexttile
hold on
cur_accel = accel_dB_all(:,:,end);
% n_trials x frequencies, layer different groups row-wise
x = [repmat(1:numel(stim_freqs),size(hydro_dB,1),1); repmat(1:numel(stim_freqs),size(cur_accel,1),1)];
y = [hydro_dB ; cur_accel];
g = [repmat("Hydrophone", size(hydro_dB)); repmat("Accelerometer", size(cur_accel))];
% Flatten with :
boxchart(x(:), y(:),'GroupByColor',g(:))
title('Hydrophone and Accelerometer (Vector Normalized) Amplitude')
xticks(1:numel(stim_freqs))
xticklabels(string(stim_freqs))
xlabel('Frequency (Hz)')
ylabel('dB RMS')

% Plot Impedance across Frequency
colororder([tableau_10('red'); tableau_10('blue'); tableau_10('orange')])

% RMS
nexttile
hold on
for ifreq = 1:numel(stim_freqs)
    boxchart(ifreq*ones(size(imp_RMS,1),1), imp_RMS(:,ifreq))
end
title('RMS Impedance')
xticks(1:numel(stim_freqs))
xticklabels(string(stim_freqs))
xlabel('Frequency (Hz)')
ylabel('RMS Impedance re: 1.5597 MRayl')
ylim([-34 -16])

% P2P
nexttile
hold on
for ifreq = 1:numel(stim_freqs)
    boxchart(ifreq*ones(size(imp_p2p,1),1), imp_p2p(:,ifreq))
end
title('Pk-Pk Impedance')
xticks(1:numel(stim_freqs))
xticklabels(string(stim_freqs))
xlabel('Frequency (Hz)')
ylabel('Pk-Pk Impedance re: 1.5597 MRayl')
ylim([-34 -16])
sgtitle('For Assigned Stimulus Frequency 140 dB SPL')

%% Plot time domain signals
% Hydrophone
figure;
tiledlayout(numel(stim_freqs),1,'TileSpacing','tight','Padding','tight');

% Set objects
ax_hydro = gobjects(numel(stim_freqs),1);

% Randomly select one trial
rand_idx = randperm(size(exemplar_accel_sigs,1),1);
for ifreq = 1:numel(stim_freqs)
    cur_color = select_chan_color(ifreq);
    % Get sigs
    hydro_sig = medfilt1(exemplar_hydro_sigs(rand_idx,:,ifreq));

    % Make x_vec
    x_vec = (0:(length(hydro_sig)-1))./fs;

    % Plot sigs
    ax_hydro(ifreq) = nexttile; 
    plot(x_vec,hydro_sig,'Color',cur_color)
    title('Hydrophone')
    xlabel('Time (s)')
    ylabel({sprintf('%g Hz', stim_freqs(ifreq)), 'Amplitude (mV)'})
end
linkaxes(ax_hydro,'xy')
sgtitle('Exemplar Acoustic Signals')

%% Accelerometer Hodogram
% Randomly select one trial
figure; tiledlayout(1,numel(stim_freqs),'TileSpacing','tight','Padding','tight');
ax_accel = gobjects(numel(stim_freqs),1);
rand_idx = randperm(size(exemplar_accel_sigs,1),1);
for ifreq = 1:numel(stim_freqs)
    cur_color = select_chan_color(ifreq);
    
    % Get sigs
    x_sig = medfilt1(exemplar_accel_sigs(rand_idx,:,ifreq,1),10);
    y_sig = medfilt1(exemplar_accel_sigs(rand_idx,:,ifreq,2),10);
    z_sig = medfilt1(exemplar_accel_sigs(rand_idx,:,ifreq,3),10);

    ax_accel(ifreq,1) = nexttile; 
    plot3(z_sig,y_sig,x_sig,'Color',cur_color)
    axis('equal')
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    title(sprintf('%d Hz',stim_freqs(ifreq)))
    grid('on')
end
linkaxes(ax_accel(:),'xyz')
sgtitle('Accelerometer Hodogram')

%% Plot FFTs
for ifreq = 1:numel(stim_freqs)
    figure; tiledlayout(1,numel(my_chans),'TileSpacing','tight','Padding','tight')
    cur_color = select_chan_color(ifreq);
    amp_vec = stim_amps{ifreq};
        for ichan = 1:numel(my_chans)
            amp_i = find(largest_amp_vec == max(stim_amps{ifreq}));
            nexttile
            
            % Get a subset of trials
            % Ensure you only get filled trials
            n_filled = row_idx(ifreq,amp_i) - 1;
            rand_idx = randperm(n_filled, min(30, n_filled));

            % Get highest amp data
            cur_ON = ON_fft(rand_idx,:,ifreq,amp_i,ichan);
            cur_OFF = OFF_fft(rand_idx,:,ifreq,amp_i,ichan);

            for itrial = 1:size(cur_ON,1)
                plot(tmp_freq_vec,abs(cur_ON(itrial,:)),'Color',cur_color);
                hold on;
                plot(tmp_freq_vec,abs(cur_OFF(itrial,:)),'Color',tableau_10('grey'),'LineWidth',0.5);
            end
            xlim([0 stim_freqs(ifreq)+50])
            xline(30)
            title(my_chans{ichan})
            xlabel('Frequency (Hz)')
            ylabel('Amplitude (m/s^2)')
        end
        sgtitle(sprintf('%g Hz | % dB SPL',stim_freqs(ifreq),largest_amp_vec(amp_i)))
        linkaxes
end
