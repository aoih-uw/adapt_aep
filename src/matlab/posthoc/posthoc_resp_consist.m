%% posthoc_resp_consist
%% Assign variables
% Metadata
subjid = meta.subjid;
amp_vecs = meta.amp_vecs;
stim_type_vec = meta.stim_type_vec;
if isfield(meta, 'stim_freqs')
    stim_freqs = meta.stim_freqs;
else
    stim_freqs = meta.stim_freq;
end
my_chans = meta.my_chans;
nchans = length(my_chans);
my_chans_name = meta.my_chans_name;
target_freq_range = meta.target_freq_range;
trials_per_block = meta.trials_per_block;
max_trials = meta.ON_OFF_max_trials;
use_sigmoid = 0;

% Organized data
ON_2f        = org_data.ON_2f;
OFF_2f       = org_data.OFF_2f;
time_vec     = org_data.time_vec;

% Function specific vars
stim_type_idx = find(strcmp('ONOFF',stim_type_vec));
max_batches = max_trials/trials_per_block;

%% Turn into a long format table
T_ON_2f = table();
for ifreq = 1:length(stim_freqs)
    amp_vec = amp_vecs{ifreq}(:);
    tmp = permute(squeeze(ON_2f(:,:,1,:,ifreq)), [1 3 2]);
    tmp = tmp(:,:,1:numel(amp_vec));
    tmp_time = permute(squeeze(time_vec(:,1,:,:,:,ifreq)), [1 3 2]);
    tmp_time = tmp_time(:,:,1:numel(amp_vec));
    [~, Chan, Amp] = ndgrid(1:size(tmp,1), 1:nchans, 1:numel(amp_vec)); % order of ngrid have to follow tmp dimension meaning
    T_new = table(repmat(subjid,numel(tmp),1),...
        categorical(Chan(:),1:nchans,my_chans_name), ...
        repmat(stim_freqs(ifreq),numel(tmp),1),...
        amp_vec(Amp(:)), tmp(:),tmp_time(:), ...
        'VariableNames',{'Subj_ID','Chan','Freq', 'Amp','Val','Time'});
    T_new(isnan(T_new.Val),:) = [];
    T_ON_2f = [T_ON_2f; T_new];
end

%% Plot data
T_ON_2f.AbsVal = abs(T_ON_2f.Val);
inc_electrodes = ["Subcranial","Subcutaneous"];
sub = T_ON_2f(ismember(T_ON_2f.Chan,inc_electrodes),:);

G = groupsummary(sub,{'Freq','Chan','Amp','Time'}, ... % For each unique freq,chan,amp,time combination
    {'median',@(x) mad(x,1)}, 'AbsVal');
G.Properties.VariableNames{'fun1_AbsVal'} = 'mad_AbsVal';

% Preallocate slope table
all_amps = amp_vecs{1}; % Identify the largest amp_vec range
[Freq, Chan, Amp] = ndgrid(1:length(stim_freqs), 1:numel(inc_electrodes), 1:numel(all_amps));
T_slope = table(repmat(subjid,numel(Freq),1),...
        categorical(Chan(:),1:numel(inc_electrodes),inc_electrodes), ...
        stim_freqs(Freq(:))',...
        all_amps(Amp(:))',  ...
        NaN(numel(Freq(:)),1), ...
        NaN(numel(Freq(:)),1), ...
        'VariableNames',{'Subj_ID','Chan','Freq', 'Amp','Slope', 'P_Val'});

for ifreq = 1:length(stim_freqs)
    figure; tiledlayout(4,5,'TileSpacing','tight','Padding','tight')
    amp_vec = amp_vecs{ifreq};
    cur_freq = stim_freqs(ifreq);
    for iamp = 1:numel(amp_vec)
        nexttile; hold on
        for ichan = 2:3
            idx = G.Freq == cur_freq ...
                & G.Chan == my_chans_name(ichan) ...
                & G.Amp == amp_vec(iamp);
            errorbar(G.Time(idx), G.median_AbsVal(idx), G.mad_AbsVal(idx), 'o-',...
                'Color', select_chan_color(ichan), 'MarkerFaceColor', select_chan_color(ichan))
            hold on;
            
            % Fit regression line
            first_time = G.Time(idx);
            first_time = first_time(1);
            my_t = minutes(G.Time(idx) - first_time);
            mdl = fitlm(my_t,G.median_AbsVal(idx));
            my_slope = mdl.Coefficients.Estimate(2);
            my_p = mdl.Coefficients.pValue(2);
            % Plot regression line
            plot(G.Time(idx), mdl.Fitted, 'Color',select_chan_color(ichan), 'LineWidth',3)

            % Save to slope table
            idx = T_slope.Freq == cur_freq ...
                & T_slope.Chan == my_chans_name(ichan) ...
                & T_slope.Amp == amp_vec(iamp);

            T_slope.Slope(idx) = my_slope;
            T_slope.P_Val(idx) = my_p;
        end
        ylabel('Amplitude (\muV)')
        title(sprintf('%g dB', amp_vec(iamp)))
    end
    sgtitle(sprintf('%d Hz', stim_freqs(ifreq)))
end

% Plot Slope and Fill by p value
T_slope.Chan = categorical(T_slope.Chan);
figure; tiledlayout(1,3,'TileSpacing','tight','Padding','tight');
for ifreq = 1:length(stim_freqs)
    nexttile; hold on;
    for ichan = 2:3
        cur_chan = my_chans_name(ichan);
        % Get slopes and p values for current channel and frequency
        Slopes = T_slope(T_slope.Freq == stim_freqs(ifreq) & T_slope.Chan == cur_chan, :);
        sig = Slopes.P_Val < 0.05;
        h = plot(Slopes.Amp, Slopes.Slope, '-o', 'Color', select_chan_color(ichan), 'LineWidth',2);
        scatter(Slopes.Amp(sig), Slopes.Slope(sig),[], select_chan_color(ichan), 'filled', 'HandleVisibility', 'off')
    end
    title(stim_freqs(ifreq) + " Hz")
    ylabel('Slope (\muV / min)');
    xlabel('Stimulus Amplitude (dB SPL)')

end
sgtitle('Do 2f magnitudes change across testing time?')
