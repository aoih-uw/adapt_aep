function [false_pos, false_neg] = calculate_false_rate(amp_vec, itvec, bootstrp_sim, ...
    resp_found_data, threshold, max_trials, my_chans,trials_in_batch)

% For each iamp and ichan find the first *stable* resp_found batch
for iit = 1:length(itvec)
    for iamp = 1:length(amp_vec)
        for ichan = 1:length(my_chans)
            cur_data = bootstrp_sim(:,2,iamp,ichan,iit);
            last_no_resp = find(cur_data == 0,1,'last');
            if last_no_resp == 13
                % no response found by the end
                resp_found_data(ichan,iamp,iit) = NaN;
            elseif isempty(last_no_resp) % All batches have found_response, just pick the first one
                resp_found_data(ichan,iamp,iit) = trials_in_batch;
            else % There was a mid batch no response, so find the last no response and take the first yes response right after or not even whent there is a midbatch
                resp_found_data(ichan,iamp,iit) = (last_no_resp+1)*trials_in_batch;
            end
        end
    end
end

% Assign vars
false_pos = zeros(length(amp_vec),length(itvec));
false_neg = zeros(length(amp_vec),length(itvec));

% Only look at channel 2 data
for iit = 1:length(itvec)
    for iamp = 1:length(amp_vec)
        cur_data = bootstrp_sim(:,2,iamp,2,iit);
        if any(isnan(cur_data))
            keyboard
        end
        ones_loc = cur_data == 1;
        zeros_loc = cur_data == 0;
        if amp_vec(iamp) < threshold
            false_pos(iamp,iit) = sum(ones_loc);
        elseif amp_vec(iamp) >= threshold
            false_neg(iamp,iit) = sum(zeros_loc);
        end
    end
end

fp_attempts = 13*sum(amp_vec < threshold);
fn_attempts = 13*sum(amp_vec >= threshold);

figure;
plot(itvec, (sum(false_pos,1)/fp_attempts)*100,'-o','Color',tableau_10('blue'),'LineWidth',2, 'MarkerFaceColor',tableau_10('blue'));
hold on;
plot(itvec, (sum(false_neg,1)/fn_attempts)*100,'-o','Color',tableau_10('orange'),'LineWidth',2,'MarkerFaceColor',tableau_10('orange'))
xlabel('N Bootstrap Iterations')
ylabel('% False Decisions')
ytickformat('percentage')
legend('False positive','False negative')
title('False +/- detections by bootstrap iterations')


% Calculate time needed
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

%% Plot trial count heatmap
% min num of trials needed to find reliable resp_found (i.e., no more no resp_found after resp_found)
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