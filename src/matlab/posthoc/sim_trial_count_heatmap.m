function [resp_found_data] = sim_trial_count_heatmap(amp_vec, my_dataset, ...
    resp_found_data, max_trials, my_chans,trials_per_block)

%% For each iamp and ichan find the first *stable* resp_found batch
for ii = 1:size(my_dataset,4)
    for iamp = 1:length(amp_vec)
        for ichan = 1:length(my_chans)
            cur_data = my_dataset.resp_found(:,iamp,ichan,ii);
            n_filled = find(~isnan(cur_data),1,'last');   % [] if all NaN
            cur_data = cur_data(1:n_filled);
            last_no_resp = find(cur_data == 0,1,'last');
            if isempty(n_filled)                    % all NaN
                resp_found_data(ichan,iamp,ii) = NaN;
            elseif isempty(last_no_resp)            % never a no-response
                resp_found_data(ichan,iamp,ii) = trials_per_block;
            elseif last_no_resp == n_filled         % final filled batch still no-response
                resp_found_data(ichan,iamp,ii) = NaN;
            else
                resp_found_data(ichan,iamp,ii) = (last_no_resp+1)*trials_per_block;
            end
        end
    end
end

%% Plot trial count heatmap
% min num of trials needed to find reliable resp_found (i.e., no more no resp_found after resp_found)
figure;
cur_data = squeeze(resp_found_data(:,:,end));
h = heatmap(cur_data);              % keep NaNs
h.MissingDataColor = tableau_10('grey');   % grey out the NaN cells
h.XDisplayLabels = string(amp_vec);
h.YDisplayLabels = {'EKG','2 mm Subcranial', '4 mm Subcranial','Subcutaneous'};
h.ColorbarVisible = 'off';
h.Colormap = interp1([0 1], [1 1 1; tableau_10('blue')], linspace(0,1,256));
title('Number of trials needed to detect AEP response')
h.XLabel = 'Stimulus Amplitude (dB SPL)';

%% Calculate time needed
adaptive_trials = squeeze(resp_found_data(:,:,end));
adaptive_trials(isnan(adaptive_trials)) = max_trials;
static_trials = ones(size(adaptive_trials,1),size(adaptive_trials,2))*max_trials;
time_mat = ones(size(adaptive_trials,1),size(adaptive_trials,2))*(600/1000/60); % 600 ms in minutes

adaptive_time = adaptive_trials.*time_mat;
static_time = static_trials.*time_mat;

clean_adaptive = cumsum(adaptive_time(2,:));
clean_static = cumsum(static_time(2,:));

figure;plot(amp_vec,clean_adaptive,'-o','Color',tableau_10('blue'),'LineWidth',2, 'MarkerFaceColor',tableau_10('blue'))
hold on;
plot(amp_vec,clean_static,'-o','Color',tableau_10('orange'),'LineWidth',2, 'MarkerFaceColor',tableau_10('orange'))
xlabel('Stimulus Amplitude')
ylabel('Cumulative time testing (min)')
title('Over 15 minutes saved using adaptive trial presentation')
legend('Adaptive trial presentation','Static trial count')