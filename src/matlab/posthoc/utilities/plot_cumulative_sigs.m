function [cumu_noise, cumu_diff] = plot_cumulative_sigs...
    (max_trials,trials_per_block,my_chans,my_chans_name,amp_vec,cumu)
% Show decrease in 2f amplitudes across cumulative batches
% ADD Summary stats/fit a softplus to them, track their parameters,
% etc.  amplitude of noise floor at stimulus frequency bin

% Preallocate
n = max_trials/trials_per_block;
cumu_noise = NaN(n,length(amp_vec),length(my_chans));
cumu_diff = NaN(n,length(amp_vec),length(my_chans));
c = nebula(n);

figure; tiledlayout(2,length(my_chans),"TileSpacing",'tight','Padding','tight')
for ichan = 1:length(my_chans)
    nexttile(ichan); hold on;
    title(my_chans_name{ichan});
    if ichan == 1, ylabel('2f Magnitude (\muV)'); end
    for i = 1:n
        cur_diff = cumu.diff_mean_2f(i,:,ichan);
        cumu_diff(i,:,ichan) = cur_diff;
        plot(amp_vec,cur_diff,'Color',c(i,:));
    end
    nexttile(ichan+length(my_chans)); hold on;
    if ichan == 1, ylabel('Noise Floor at 2f bin (\muV)'); end
    for i = 1:n
        cur_noise = cumu.noise_floor_mean_2f(i,:,ichan);
        cumu_noise(i,:,ichan) = cur_noise;
        plot(amp_vec,cur_noise,'Color',c(i,:));
    end
end
sgtitle('Cumulative averaging across batches')
colormap(nebula);

