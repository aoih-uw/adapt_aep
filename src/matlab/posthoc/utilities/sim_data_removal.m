function T_error = sim_data_removal(F_growth,amp_vec,my_params,cur_freq)
F_data = F_growth.all.F_vals(:,:,end); % Only use the true experiment simulation where no resampling with replacement is used
ref_thresh = F_growth.all.thresh(:,1,end);
my_chans = my_params.my_chans;
my_alpha = my_params.my_alpha;
max_trials = my_params.max_batches*my_params.trials_per_block;
my_chans_name = my_params.my_chans_name;

my_reso = 2000;
x_vec = linspace(min(amp_vec), max(amp_vec), my_reso);
log_trans_alpha = log10(finv(1 - my_alpha, 2, 2*(max_trials - 1)));

% Assign indexing
n = numel(amp_vec);
m = 3; % minimum points needed to fit your model
bottom_up = arrayfun(@(k) k:n, 1:n-m+1, 'uni', 0); % drop amps from low to high
top_down = arrayfun(@(k) 1:k, n:-1:m,'uni', 0);
every_6_dB = {1:2:n, 2:2:n}; % 6 dB spacing (both offsets)

% Idx sets
idxSets = [ ...
    bottom_up,...
    top_down, ...  
    every_6_dB]; 

% Preallocate
error_mat = NaN(4,n,numel(my_chans));

% Fit models and identify thresholds
remov_thresh = NaN(numel(my_chans),numel(idxSets));
warning('off','optimlib:lsqncommon:SwitchToLineSearch')
for iset = 1:numel(idxSets)
        idx = idxSets{iset};
    for ichan = 1:numel(my_chans)
        cur_y = log10(max(F_data(ichan, idx),realmin,'includenan'));
        [p, logistic, ~] = param_logistic(cur_y, amp_vec(idx));
        y_vec = logistic(p, x_vec);

        % Find and assign alpha value crossing threshold
        if y_vec(1) < log_trans_alpha
            cross_idx = find(y_vec >= log_trans_alpha, 1, 'first');
            if ~isempty(cross_idx)
                cur_thresh = x_vec(cross_idx);
                remov_thresh(ichan,iset) = cur_thresh;
            end
        end
    end
end

% Plot results
figure; tiledlayout(1,3,'TileSpacing','tight','Padding','tight')
titles = {'Bottom-up', 'Top-down','6 dB resolution'};

idx = 1; % To select the right indexes
for iset = 1:3    
    nexttile
    % Select which set we are working with
    if iset == 1
        sets  = bottom_up;
    elseif iset == 2
        sets  = top_down;
    elseif iset == 3
        sets  = every_6_dB;
    end

    cur_N = numel(sets);
    sizes = cellfun(@numel, sets);
    if iset == 3
        sizes = sizes + [-5 5];
    end
    for ichan = 1:numel(my_chans)
        cur_color = select_chan_color(ichan);
        cur_thresholds = remov_thresh(ichan,idx:(idx+cur_N-1));
        error_vec = ref_thresh(ichan)-cur_thresholds;

        % Store error
        if iset == 3
            error_mat(iset,1,ichan) = error_vec(1);
            error_mat(iset+1,1,ichan) =  error_vec(2);
        else 
            error_mat(iset,1:length(error_vec),ichan) = error_vec;
        end

        plot(sizes,error_vec,'-o','Color',cur_color,'MarkerFaceColor',cur_color,'DisplayName',my_chans_name{ichan})
        hold on;

    end
    yregion(-3,3,'FaceColor',tableau_10('grey'),'FaceAlpha',0.1,'HandleVisibility','off');
    yline(0,'--','Color',tableau_10('grey'),'HandleVisibility','off');
    ylabel('Error (dB)')
    title(titles{iset})
    if iset == 3
        xlabel('Offset type')
        xticks(sizes)
        xticklabels({'1', '2'})
    else
        xlabel('N data points included')
        set(gca, 'XDir', 'reverse');
    end

    % Increment idx
    idx = idx + cur_N;
end
% Formatting
sgtitle(sprintf('%g Hz | How stable is the threshold estimate with less data points', cur_freq))
delete(findobj(gcf,'-regexp','DisplayName','Forebrain|EKG'))
legend('Location','northeast')
ylim([-10 10])
linkaxes

% Convert into table
mylabels = {'Bottom-up','Top_down','6_dB_1','6_dB_2'};
[M,S,C] = ndgrid(1:size(error_mat,1),1:size(error_mat,2),1:numel(my_chans));
Method = mylabels(M);
Channel = my_chans_name(C);
T_error = table(categorical(Method(:),mylabels),S(:),categorical(Channel(:),my_chans_name), error_mat(:), ...
    'VariableNames', {'Method','Step','Channel','Error'});
T_error(isnan(T_error.Error),:) = [];

% Set back warning message
warning('on','optimlib:lsqncommon:SwitchToLineSearch')