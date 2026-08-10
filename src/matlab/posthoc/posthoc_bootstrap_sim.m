%% posthoc_bootstrap_simulation
% Assign variables
amp_vec = grand_ex_save{1,1}.info.mixed.test_amplitudes;
amp_vec = sort(amp_vec);
stim_type_vec = grand_ex_save{1,1}.info.mixed.stim_name;
stim_type_idx = find(strcmp('ONOFF',stim_type_vec));
my_chans = [2,3,4];
my_chans_name = {'2 mm subcranial', '4 mm subcranial', 'Subcutaneous'};
itvec = [10 100 500 1000 5000 10000];
trials_in_batch = 10;
max_batches = 130/trials_in_batch; % 130 trials in batches of 10
bootstrp_sim = NaN(max_batches, 8, length(amp_vec), length(my_chans), length(itvec));
resp_found_data = NaN(length(my_chans),length(amp_vec),length(itvec));
growth_func_mean = NaN(length(my_chans),length(amp_vec));
growth_func_sem = NaN(length(my_chans),length(amp_vec));
lower_ci_vec = NaN(13,length(amp_vec),length(my_chans));
boot_std_vec = NaN(13,length(amp_vec),length(my_chans));
growth_func_noise_floor = NaN(length(my_chans),length(amp_vec));
my_dists = zeros(max(itvec),length(amp_vec));
thresh_fit = NaN(length(my_chans),1);
use_sigmoid = 1;
max_resp_frac = 0.01; % fraction of max slope defining "end of lower asymptote"

% Loop through data
for iit = 1:length(itvec)
    n_bootstrap = itvec(iit);
    for iamp = 1:length(amp_vec)
        for ichan = 1:length(my_chans)
            % Get all ON-OFF data
            cur_phase = squeeze(phase_vec(:,1,iamp,stim_type_idx,ichan));
            diff_2f = ON_2f(:,iamp,stim_type_idx,ichan) - OFF_2f(:,iamp,1,ichan);

            % Keep only real data
            keep = ~isnan(cur_phase) & ~isnan(diff_2f);
            cur_phase = cur_phase(keep);
            diff_2f = diff_2f(keep);
            phases = unique(cur_phase);
            idx = 1;
            resp_found = 0;
            used_all_trials = 0;
            for ibatch = 1:max_batches
                % Ensure equal phases are selected
                n_per_phase = (idx+trials_in_batch-1)/length(phases);
                inc_select = [];
                for ip = 1:length(phases)
                    phase_idx = find(cur_phase == phases(ip));
                    inc_select = [inc_select; phase_idx(1:n_per_phase)];
                end

                % Ensure equal phases have been selected
                if sum(cur_phase(inc_select)) ~= 0
                    keyboard
                end

                % Get current batch of data
                cur_data = diff_2f(inc_select);
                cur_mean = mean(cur_data,1);
                cur_sem = std(cur_data,[],1)/sqrt(length(cur_data));
                cur_off = OFF_2f(keep,iamp,1,ichan);
                cur_noise_floor = median(cur_off(inc_select));

                % Run bootstrap on current batch of data
                [bootstat, lower_CI, upper_CI] = ...
                    calculate_bootstrap(n_bootstrap, cur_data);

                % Calculate distribution metrics
                cur_boot_mean = mean(bootstat);
                cur_boot_std = std(bootstat);

                % Save only channel 2 bootstrap dist for highest
                % n_bootstrap count
                if ichan == 2 && iit == length(itvec)
                    my_dists(:,iamp) = bootstat;
                end

                resp_found = lower_CI > 0;

                % cur_batch_summary
                % idx = N_trials in average
                cur_batch_summary = [length(inc_select) resp_found cur_mean cur_sem ...
                    cur_noise_floor cur_boot_mean cur_boot_std lower_CI];
                boot_std_vec(ibatch,iamp,ichan) = cur_batch_summary(7);
                lower_ci_vec(ibatch,iamp,ichan) = cur_batch_summary(8);
                bootstrp_sim(ibatch,:,iamp,ichan,iit) = cur_batch_summary;
                idx = idx+trials_in_batch;
            end
        end
    end
end

%% Estimate threshold based on lower CI value
% Fit softplus to lower_CI growth functions and find zero-crossing threshold
x_vec = linspace(min(amp_vec), max(amp_vec), 2000);
thresh_ci = NaN(size(bootstrp_sim,1), length(my_chans));
figure; tiledlayout(1,3,'TileSpacing','tight','Padding','tight');
for ichan = 1:length(my_chans)
    nexttile
    if ichan == 1
        cur_color = tableau_10('blue');
    elseif ichan == 2
        cur_color = tableau_10('orange');
    elseif ichan == 3
        cur_color = tableau_10('purple');
    end
    for ibatch = 1:size(bootstrp_sim,1)
        cur_y = reshape(lower_ci_vec(ibatch,:,ichan), 1, []);
        if any(isnan(cur_y)), continue; end

        % Fit softplus
        cur_data_std = boot_std_vec(ibatch,:,ichan);
        [p, ~, ~, softplus] = param_softplus(cur_y, cur_data_std, reshape(amp_vec,1,[]), [], 1);
        y_vec = softplus(p, x_vec);
        cross_idx = find(y_vec >= 0, 1, 'first');
        if ~isempty(cross_idx)
            thresh_ci(ibatch,ichan) = x_vec(cross_idx);
        end
        plot(x_vec,y_vec,'Color',cur_color,'LineWidth',1.5)
        hold on;
        plot(amp_vec, cur_y, 'o','Color',cur_color)
        xline(thresh_ci(ibatch,ichan), '--', 'Color',tableau_10('grey'))
        yline(0,'--')

        xlabel('Stimulus Amplitude')
        if ichan == 1, ylabel('Lower CI Value'); end
        title(sprintf('%s', my_chans_name{ichan}))
        hold on;
        
    end
end
sgtitle('Lower CI values fitted with Softplus Function')

% Find N trials at which threshold estimate stabilizes
tol = 3; % dB tolerance band
n_trials = 10:10:130;
stable_n = NaN(1,length(my_chans));
for ichan = 1:length(my_chans)
    y_vec = thresh_ci(:,ichan);
    last_bad = find(abs(y_vec - y_vec(end)) > tol, 1, 'last');
    if isempty(last_bad)
        stable_n(ichan) = n_trials(1);
    elseif last_bad < numel(y_vec)
        stable_n(ichan) = n_trials(last_bad+1);
    end
end

% Plot change in threshold estimate across batches of 10
figure; tiledlayout(1,3,'Padding','tight','TileSpacing','tight');
for ichan = 1:length(my_chans)
    nexttile
    if ichan == 1
        cur_color = tableau_10('blue');
    elseif ichan == 2
        cur_color = tableau_10('orange');
    elseif ichan == 3
        cur_color = tableau_10('purple');
    end

plot(n_trials,thresh_ci(:,ichan),'-o','Color',cur_color,'LineWidth',2,'MarkerFaceColor',cur_color)
hold on;
xline(stable_n(ichan),'--','Color',cur_color,'LineWidth',1.5)
% Tolerance fill
xf = [min(n_trials) max(n_trials)];
yf = thresh_ci(end,ichan) + [-tol tol];
fill([xf fliplr(xf)],[yf(1) yf(1) yf(2) yf(2)],cur_color, ...
    'FaceAlpha',0.15,'EdgeColor','none','HandleVisibility','off')
title(sprintf('%s', my_chans_name{ichan}))
xlabel('N trials in AEP average')
ylabel('Estimated threshold (dB SPL)')
end
sgtitle('Lower CI-based threshold value estimate')
linkaxes
ylim([95 140])
xlim([0 140])

%% False +/- Identification
% For each iamp and ichan find the first *stable* resp_found batch
for iit = 1:length(itvec)
    for iamp = 1:length(amp_vec)
        for ichan = 1:length(my_chans)
            cur_data = bootstrp_sim(:,2,iamp,ichan,iit);
            last_no_resp = find(cur_data == 0,1,'last');

            if last_no_resp == 13
                % no response found at any point
                resp_found_data(ichan,iamp,iit) = NaN;
            elseif isempty(last_no_resp) % All batches have found_response, just pick the first one
                resp_found_data(ichan,iamp,iit) = trials_in_batch;
            else % There was a mid batch no response, so find the last no response and take the first yes response right after or not even whent there is a midbatch
                resp_found_data(ichan,iamp,iit) = (last_no_resp+1)*trials_in_batch;
            end
        end
    end
end

% Calculate rate
posthoc_false_rate

%% Generate vector for plotting 2f based growth function 
for iamp = 1:length(amp_vec)
    for ichan = 1:length(my_chans)
        cur_idx = resp_found_data(ichan,iamp,end)/trials_in_batch;
        if isnan(cur_idx) % Get the mean and sem of the last measured batch
            growth_func_mean(ichan,iamp) = bootstrp_sim(end,3,iamp,ichan,end);
            growth_func_sem(ichan,iamp) = bootstrp_sim(end,4,iamp,ichan,end);
            growth_func_noise_floor(ichan,iamp) = bootstrp_sim(end,5,iamp,ichan,end);
        else % Get the valid resp_found idx and extract its mean/sem
            growth_func_mean(ichan,iamp) = bootstrp_sim(cur_idx,3,iamp,ichan,end);
            growth_func_sem(ichan,iamp) = bootstrp_sim(cur_idx,4,iamp,ichan,end);
            growth_func_noise_floor(ichan,iamp) = bootstrp_sim(cur_idx,5,iamp,ichan,end);
        end
    end
end

%% Plot
% Plot mean/sem across batches and ID when resp_found
for ichan = 1:length(my_chans)
    figure;
    tiledlayout(4,4,'Padding','tight','TileSpacing','tight');
    for iamp = 1:length(amp_vec)
        nexttile; hold on;

        chan_amp_data = bootstrp_sim(:,:,iamp,ichan,end);
        chan_amp_data = chan_amp_data(~isnan(chan_amp_data(:,1)),:);  % keep filled batches
        batch_num  = chan_amp_data(:,1);
        resp_found = chan_amp_data(:,2);
        batch_mean = chan_amp_data(:,3);
        batch_sem  = chan_amp_data(:,4);

        % Sort batch data
        [batch_num, si] = sort(batch_num);
        batch_mean = batch_mean(si);
        batch_sem  = batch_sem(si);
        resp_found = resp_found(si);

        % Create error fill
        x_vec  = batch_num(:).';
        lo = (batch_mean - batch_sem).';
        hi = (batch_mean + batch_sem).';
        fill([x_vec fliplr(x_vec)], [lo fliplr(hi)], [.7 .7 .7], ...
            'FaceAlpha',.25,'EdgeColor','none','HandleVisibility','off');
        plot(x_vec, batch_mean, 'Color',[.7 .7 .7],'HandleVisibility','off');

        % Plot raw data
        scatter(batch_num(resp_found==1),batch_mean(resp_found==1),40,tableau_10('green'),'filled');
        scatter(batch_num(resp_found==0),batch_mean(resp_found==0),40,tableau_10('red'),'filled');
        title(sprintf('%d dB',amp_vec(iamp)));
        xlabel('N trials in average'); ylabel('Amplitude (\muV)');
    end
    sgtitle(sprintf('Channel %d', my_chans(ichan)));
    hold off;
end

% Plot heatmap min num of trials needed to find reliable resp_found (i.e., no more no resp_found after resp_found)
figure;
cur_data = squeeze(resp_found_data(:,:,end));
h = heatmap(cur_data);              % keep NaNs — don't convert to 130
h.MissingDataColor = tableau_10('grey');   % grey out the NaN cells
h.XDisplayLabels = string(amp_vec);
h.YDisplayLabels = {'2 mm Subcranial', '4 mm Subcranial','Subcutaneous'};
h.ColorbarVisible = 'off';
h.Colormap = interp1([0 1], [1 1 1; tableau_10('blue')], linspace(0,1,256));
title('Number of trials needed to detect AEP response')
h.XLabel = 'Stimulus Amplitude (dB SPL)';

% Plot 2f based growth functions
figure; tiledlayout(1,3,'Padding','tight','TileSpacing','tight');
for ichan = 1:length(my_chans)
    nexttile
    if ichan == 1
        cur_color = tableau_10('blue');
    elseif ichan == 2
        cur_color = tableau_10('orange');
    elseif ichan == 3
        cur_color = tableau_10('purple');
    end
    cur_y = growth_func_mean(ichan,:);
    cur_y_sem = growth_func_sem(ichan,:);
    cur_noise_floor = median(growth_func_noise_floor(ichan,:));

    % Fit model
    if use_sigmoid
        % Fit sigmoid
        [p, cur_data, cur_data_sem, logistic] = param_logistic(cur_y, [], amp_vec, []);
    else
        % Fit softplus
        [p, cur_data, cur_data_sem, softplus] = param_softplus(cur_y,[],amp_vec, []); % Fit to the raw data without correction
    end

    % Find threshold
    x_vec = linspace(min(amp_vec),max(amp_vec),200);
    if use_sigmoid
        y_vec = logistic(p,x_vec);
    else
        y_vec = softplus(p,x_vec);
    end
    thresh_idx = find(y_vec >= max(y_vec)*max_resp_frac,1,'first');
    if isempty(thresh_idx)
        thresh_fit(ichan) = NaN;
    else
        thresh_fit(ichan) = x_vec(thresh_idx);
    end

    % Plot raw data
    errorbar(amp_vec,cur_y,cur_y_sem,'o','Color',cur_color,'MarkerFaceColor',cur_color,'LineWidth',2);
    hold on;

    % Plot fitted curve
    plot(x_vec,y_vec,'-','Color',cur_color,'LineWidth',2);
    xline(thresh_fit(ichan), '--','LineWidth',2,'Color', tableau_10('red'))
    xline(p(3), '--', 'Color', tableau_10('grey'))
    xticks(amp_vec)
    xlabel('Stimulus amplitude')
    ylabel('Amplitude (\muV)')
    title(string(ichan))
end
sgtitle('Simulated Adaptive Growth Functions')


% Apply Tufte styling
apply_tufte

% % Save figures
% figs = findall(0, 'Type', 'figure');
% for i = 1:length(figs)
%     figs(i).WindowState = 'maximized';
%     drawnow;
%     exportgraphics(figs(i), sprintf('%d_figure_%d_1024_trials.png', subjid, figs(i).Number), 'Resolution', 300);
%     savefig(figs(i), sprintf('%d_figure_%d_bootstrap.fig', subjid, figs(i).Number));
% end


% % Plot bootstrap distribution characteristics
% for ichan = 1:length(my_chans)
% figure; tiledlayout('flow','TileSpacing','tight','Padding','tight')
% for ibatch = 1:size(bootstrp_sim,1)
%     nexttile
%     for iamp = 1:length(amp_vec)
%         cur_data = bootstrp_sim(ibatch,:,iamp,ichan,end);
%         cur_resp = cur_data(2);
%         cur_boot_mean = cur_data(6);
%         cur_boot_std = cur_data(7);
%         cur_mean = cur_data(3);
%         cur_sem = cur_data(4);
%         cur_lower_ci = cur_data(8);
% 
%         boot_mean_vec(ibatch,iamp,ichan) = cur_boot_mean;
%         boot_std_vec(ibatch,iamp,ichan) = cur_boot_std;
%         lower_ci_vec(ibatch,iamp,ichan) = cur_lower_ci;
% 
%         if cur_resp == 1
%             my_color = tableau_10('green');
%         else
%             my_color = tableau_10('red');
%         end
%         s = scatter(amp_vec(iamp), cur_lower_ci,'Color',my_color,'MarkerFaceColor',my_color,'MarkerEdgeColor',my_color);
%         % s = errorbar(amp_vec(iamp),cur_boot_mean, cur_boot_std,'Color',my_color,'MarkerFaceColor',my_color,'MarkerEdgeColor',my_color);
%         % s = errorbar(cur_mean, cur_boot_mean,cur_boot_std,cur_boot_std,cur_sem,cur_sem,'Color',my_color,'MarkerFaceColor',my_color,'MarkerEdgeColor',my_color);
%         s.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('amp', amp_vec(iamp));
%         hold on;
%     end
%     title(ibatch)
%     xlabel('Stimulus Amplitude')
%     ylabel('Bootstrap Mean')
% end
% sgtitle(sprintf('Channel %d',my_chans(ichan)));
% end
