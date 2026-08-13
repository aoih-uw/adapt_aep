function  compare_bias(all_data,ds_data,bottom_up,top_down,my_chans_name, trials_per_block)
%% Compare downsample
my_tag = 'Downsample';
my_xlabel = 'Downsample factor';
calc_params_delta(my_chans_name,ds_data,all_data,my_tag,my_xlabel)
calc_threshold_delta(my_chans_name,ds_data,all_data,my_tag,trials_per_block)

% compare bottom_up
my_tag = 'Bottom-up';
my_xlabel = 'N datapoints deleted';
calc_params_delta(my_chans_name,bottom_up,all_data,my_tag,my_xlabel)
calc_threshold_delta(my_chans_name,bottom_up,all_data,my_tag,trials_per_block)

% compare top_down
my_tag = 'Top-down';
my_xlabel = 'N datapoints deleted';
calc_params_delta(my_chans_name,top_down,all_data,my_tag,my_xlabel)
calc_threshold_delta(my_chans_name,top_down,all_data,my_tag,trials_per_block)
end

%% Helper functions
function calc_params_delta(my_chans_name,data_set,all_data,my_tag,my_xlabel)
p_x_label = {'a','k','x0','b'};
figure; tiledlayout(1,length(p_x_label),'TileSpacing','tight','Padding','tight');
for itype = 1:length(p_x_label)
    nexttile
    % Model parameters
    x_vec = [];
    my_delta = [];
    for ichan = 1:length(my_chans_name)
        cur_color = select_chan_color(ichan);
        for istep = 1:size(data_set,2)
            x_vec(istep) = data_set(istep).ds_factor;
            cur_data = data_set(istep).p(ichan,itype,end); % Use the last batch/all trials included
            my_delta(istep) = all_data.p(ichan,itype,end) - cur_data;
        end
        plot(x_vec,my_delta,'o-','Color',cur_color,'MarkerFaceColor',cur_color,'LineWidth',1)
        hold on;
    end
    xlabel(my_xlabel)
    ylabel('\Delta')
    yline(0,'--')
    title(p_x_label{itype})
end
sgtitle([my_tag ' model parameter \Delta'])
end

function calc_threshold_delta(my_chans_name,data_set,all_data,my_tag,trials_per_block)
figure; tiledlayout(1,length(my_chans_name),'TileSpacing','tight','Padding','tight');
my_delta = [];
legend_vec = [];
for ichan = 1:length(my_chans_name)
    nexttile
    cur_color = select_chan_color(ichan);
    for istep = 1:size(data_set,2)
        legend_vec(istep) = data_set(istep).ds_factor;
        cur_data = data_set(istep).thresh_ci(:,ichan)';
        my_delta(istep,:,ichan) = all_data.thresh_ci(:,ichan)' - cur_data;
    end
    for istep = 1:size(data_set,2)
        a = istep/size(data_set,2);
        x_vec = (1:size(my_delta,2))*trials_per_block;
        y_vec = my_delta(istep,:,ichan);
        plot(x_vec,y_vec,'o-','Color',[cur_color a],'MarkerFaceColor',1-a*(1-cur_color))
        hold on;
        text(x_vec(end)+3,y_vec(end),num2str(data_set(istep).ds_factor),...
            'Color',cur_color,'VerticalAlignment','middle')
    end

    % Add +/- 3 dB Shaded area
    xlim([0 x_vec(end)+20])
    xl = xlim;
    h = patch([xl(1) xl(2) xl(2) xl(1)],[-3 -3 3 3],cur_color,...
        'FaceAlpha',0.15,'EdgeColor','none');
    uistack(h,'bottom')

    % Add labels
    xlabel('N trials in avg.')
    ylabel('\Delta Threshold')
    yline(0,'--')
    title(my_chans_name{ichan})

end
sgtitle([my_tag ' Threshold \Delta'])
linkaxes(findall(gcf,'Type','axes'),'xy')
end