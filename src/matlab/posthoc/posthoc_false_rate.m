% Identify false +/- rate
threshold = 107;
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
            if sum(ones_loc) > 0 % False positive
                false_pos(iamp,iit) = sum(ones_loc);
            else
                false_pos(iamp,iit) = 0;
            end
            % False negative (find sandwiched 0s when above threshold)
        elseif amp_vec(iamp) >= threshold
            first1 = find(cur_data, 1, 'first');
            last1  = find(cur_data, 1, 'last');
            sandwiched = find(cur_data(first1:last1) == 0) + first1 - 1;
            false_neg(iamp,iit) = numel(sandwiched);
            if cur_data(end) == 0 % also count final judgement as 0 as a false neg
                false_neg(iamp,iit) =  false_neg(iamp,iit) + 1;
            end
        end
    end
end

total_attempts = 13*length(amp_vec);

figure;
plot(itvec, (sum(false_pos,1)/total_attempts)*100,'-o','Color',tableau_10('blue'),'LineWidth',2, 'MarkerFaceColor',tableau_10('blue'));
hold on;
plot(itvec, (sum(false_neg,1)/total_attempts)*100,'-o','Color',tableau_10('orange'),'LineWidth',2,'MarkerFaceColor',tableau_10('orange'))
xlabel('N Bootstrap Iterations')
ylabel('N False Decisions')
ytickformat('percentage')
legend('False positive','False negative')
title('False +/- detections by bootstrap iterations')


% Calculate time needed
max_trials = 130;
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