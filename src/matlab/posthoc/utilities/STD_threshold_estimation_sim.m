% generate pink noise
n_trial = 1024;
n_samp = 8820;
trials = zeros(n_trial,n_samp);
for i = 1:n_trial
    tmp = pinknoise(n_samp)';
    trials(i,1:length(tmp)) = tmp;
end

thresh = zeros(n_trial,1);
for i = 1:n_trial
    cur_data = trials(1:i,:);
    tmp = rms(cur_data,1)';
    my_means(i) = mean(tmp,1);
    my_std(i) = std(tmp,[],1);
    thresh(i) = my_means(i)+(my_std(i)*2);
end

figure;tiledlayout(1,2,'TileSpacing','tight','Padding','tight')
nexttile
plot(my_means,'Color',tableau_10('blue'),'LineWidth',2)
title('Mean')
ylabel('RMS Mean')
xlabel('N trials included in avg')

nexttile
plot(my_std,'Color',tableau_10('blue'),'LineWidth',2)
title('Standard Deviation')
ylabel('RMS STD')
xlabel('N trials included in avg')
sgtitle('N trials in average vs. mean / SD values')