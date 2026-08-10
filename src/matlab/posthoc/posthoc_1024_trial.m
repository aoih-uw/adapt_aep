%% Load your data first with load_my_file

% 1024 trial specific variables
trials_vec = [16 32 64 128 256 512 1024];
% Only use trim stimulus
subjid = grand_ex_save{1,1}.info.animal.subject_ID;
% trials_vec = [16 128 1024];
amp_vec = grand_ex_save{1,1}.info.mixed.test_amplitudes;
amp_vec = sort(amp_vec);
stim_type_vec = grand_ex_save{1,1}.info.mixed.stim_name;
my_chans = [2,3,4]; % 2 = 2mm, 3 = 4mm, 4 = subcut
my_chans_name = {'2 mm subcranial', '4 mm subcranial', 'Subcutaneous'};
n_it = 1000;
sp_slope_frac = 0.04; % fraction of max slope defining "end of lower asymptote"
use_sigmoid = 0;

% Preallocate
% These collect the 2f magnitudes calculated over n_it times depending on
% the n_trials included in the average
mean_2f_mag = NaN(n_it, length(amp_vec), length(trials_vec), length(my_chans));
sem_2f_mag = NaN(n_it, length(amp_vec), length(trials_vec), length(my_chans));

% Calculate means and std across varied trial counts
for itri = 1:length(trials_vec)
    % Setup figure
    cur_n_trial = trials_vec(itri);
    for iamp = 1:length(amp_vec)
        for ichan = 1:length(my_chans)
            cur_set = squeeze(ON_2f(:,iamp,1,ichan));
            cur_phase = squeeze(phase_vec(:,1,iamp,1,ichan));
            % Remove nans
            nan_mask = isnan(cur_set);
            cur_set(nan_mask) = [];
            cur_phase(nan_mask) = [];
            % Check if there are not enough trials to select from for this current trial
            if size(cur_set,1) < trials_vec(end)
                keyboard
            end
            for iit = 1:n_it
                % Ensure equal phases
                phases = unique(cur_phase);
                n_per_phase = cur_n_trial / length(phases); % assumes cur_n_trial divides evenly
                rand_select = [];
                for ip = 1:length(phases)
                    idx = find(cur_phase == phases(ip));
                    rand_select = [rand_select; idx(randi(length(idx), n_per_phase,1))];
                end

                % Ensure equal phases have been selected
                if sum(cur_phase(rand_select)) ~= 0
                    keyboard
                end

                % Save randomly selected subsample
                tmp_mean = mean(cur_set(rand_select),1);
                tmp_sem = std(cur_set(rand_select),[],1)/sqrt(size(rand_select,1));
                mean_2f_mag(iit,iamp,itri,ichan) = tmp_mean;
                sem_2f_mag(iit,iamp,itri,ichan) = tmp_sem;
            end
        end
    end
end

% Plot growth functions across different trial counts

% Start looping through data

% Preallocate
% These will contain the growth functions collapsed across all n_iterations
growth_mean = NaN(length(my_chans), length(trials_vec));
growth_std = NaN(length(my_chans), length(trials_vec));

a_fit = NaN(n_it,length(trials_vec),length(my_chans));
k_fit = NaN(n_it,length(trials_vec),length(my_chans));
x0_fit = NaN(n_it,length(trials_vec),length(my_chans));
thresh_fit = NaN(n_it,length(trials_vec),length(my_chans));

for ichan = 1:length(my_chans)
    figure;
    t1 = tiledlayout(1, 3, 'TileSpacing','tight','Padding','tight');
    % Assign plotting colors
    cur_chan = my_chans(ichan);
    if ichan == 1
        cur_color = tableau_10('blue');
    elseif ichan == 2
        cur_color = tableau_10('orange');
    elseif ichan == 3
        cur_color = tableau_10('purple');
    end

    % Start looping through trial N conditions
    for itri = 1:length(trials_vec)
        if itri == 1 || itri == 4 || itri == 7
            nexttile
        end
        % Preallocate
        % These will collect every iterations growth function, where all
        % amplitude data is included in a vector per iteration
        growth_per_it_mean = NaN(n_it,length(amp_vec));
        growth_per_it_sem = NaN(n_it,length(amp_vec));

        % Generate per iteration growth functions
        for iamp = 1:length(amp_vec)
            growth_per_it_mean(:,iamp) = squeeze(mean_2f_mag(:,iamp,itri,ichan));
            growth_per_it_sem(:,iamp) = squeeze(sem_2f_mag(:,iamp,itri,ichan));
        end

        % Calculate softplus for each iteration
        for iit = 1:n_it
            % Load in current iteration mean and sem data
            cur_data = growth_per_it_mean(iit,:);
            cur_data_sem = growth_per_it_sem(iit,:);

            if use_sigmoid
                [p, cur_data, cur_data_sem, logistic] = param_logistic(cur_data, cur_data_sem, amp_vec, []);
            else
                % Fit softplus
                [p, cur_data, cur_data_sem, softplus] = param_softplus(cur_data,cur_data_sem,amp_vec, []); % Fit to the raw data without correction
            end

            % Save params
            a_fit(iit ,itri,ichan) = p(1);
            k_fit(iit ,itri,ichan) = p(2);
            x0_fit(iit ,itri,ichan) = p(3);

            % Find threshold
            x_vec = linspace(min(amp_vec),max(amp_vec),200);
            if use_sigmoid
                y_vec = logistic(p,x_vec);
            else
                y_vec = softplus(p,x_vec);
            end
            thresh_fit(iit ,itri,ichan) = p(3) + (1/p(2))*log(sp_slope_frac/(1-sp_slope_frac));

            if itri == 1 || itri == 4 || itri == 7
                if mod(iit,250) == 0
                     % Plot only every 100th iteration
                    % Plot model fit
                    plot(x_vec,y_vec,'Color',[128 128 128]./255,'LineWidth',2);
                    hold on;

                    % Plot raw data
                    errorbar(amp_vec, cur_data , cur_data_sem,'o','Color',cur_color)
                    title(sprintf('%d trials', trials_vec(itri)))
                    xlabel('Stimulus Amplitude (dB)')
                    ylabel('2f Magnitude (\muV)')
                    xline(x0_fit(iit ,itri,ichan), '--', 'Color',tableau_10('grey'))
                    xline(thresh_fit(iit ,itri,ichan),'--','Color',tableau_10('red'))
                    yline(cur_data(1),'--')
                    yline(0,'--')
                end
            end
        end
    end
% Calculate mean threshold
growth_mean(ichan,:) = mean(thresh_fit(:,:,ichan),1)';
growth_std(ichan,:) = std(thresh_fit(:,:,ichan),[],1)';
end


%% Plot how much 2f magnitude varies by channel and N trials included in average
for ichan = 1:length(my_chans)
    figure;
    if ichan == 1
        cur_color = tableau_10('blue');
    elseif ichan == 2
        cur_color = tableau_10('orange');
    elseif ichan == 3
        cur_color = tableau_10('purple');
    end
    cur_mean_vec = squeeze(growth_mean(ichan,:));
    cur_std_vec = squeeze(growth_std(ichan,:));
    errorbar(trials_vec,cur_mean_vec,cur_std_vec,'o-','LineWidth',1.5,'Color',cur_color,'MarkerFaceColor',cur_color)
    hold on;
    xticks(trials_vec)
    xtickangle(45)
    title(my_chans_name{ichan})
    xlabel('N Trials in Average')
    ylabel('Threshold (dB SPL)')
    xscale('log')
    xlim([0 1050])

end

% Apply tufte styling
apply_tufte

% % Save figures
% figs = findall(0, 'Type', 'figure');
% for i = 1:length(figs)
%     figs(i).WindowState = 'maximized';
%     drawnow;
%     exportgraphics(figs(i), sprintf('%d_figure_%d_1024_trials.png', subjid, figs(i).Number), 'Resolution', 300);
%     savefig(figs(i), sprintf('%d_figure_%d_1024_trials.fig', subjid, figs(i).Number));
% end
%
% close all