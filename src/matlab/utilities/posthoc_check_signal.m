%% posthoc_check_signals
% Quality control
my_chans = [2 3 4];

% Reset rejected_trials post
for cur_name = 1:size(grand_ex_save, 1)
    for cur_subj = 1:size(grand_ex_save, 2)
        if isfield(grand_ex_save{cur_name, cur_subj}, 'rejected_trials_post')
            grand_ex_save{cur_name, cur_subj}.rejected_trials_post = {};
        end
    end
end

%% ELECTRODES
chan_colors = {'blue','orange','red','green','purple','brown','pink','grey','teal','yellow'};
clipped = [];
added_rej = 0;
for isubj = 1:length(subjid_list)
    figure; tiledlayout(length(my_names{isubj}), length(my_chans), 'TileSpacing','tight','Padding','tight')
    for iname = 1:length(my_names{isubj})
        N_batches = size(grand_ex_save{iname,isubj}.raw_signals,2);
        ds_fs = grand_ex_save{iname,isubj}.ds_fs;
        plot_rand_batch = randperm(N_batches, 1);
        for ichan = 1:length(my_chans)
            nexttile
            for ibatch = 1:N_batches
                cur_chan = my_chans(ichan);
                channel_matrix = grand_ex_save{iname,isubj}.raw_signals(ibatch).electrodes_microV_ds(:,:,cur_chan); % itrial x samples
                for itrial = 1:size(channel_matrix,1)
                    cur_trial = channel_matrix(itrial,:);
                    chan_rms(iname,cur_chan,ibatch,itrial,isubj) = rms(cur_trial);
                    chan_kurt(iname,cur_chan,ibatch,itrial,isubj) = kurtosis(cur_trial);
                    chan_max(iname,cur_chan,ibatch,itrial,isubj) = max(cur_trial);
                    chan_min(iname,cur_chan,ibatch,itrial,isubj) = min(cur_trial);
                    if any(cur_trial >= 500) % microV near DAC limit, isn't put through a bioamp so no need to divide by 10k
                        clipped = [clipped; iname ichan ibatch itrial isubj];
                    end
                    % if ibatch == plot_rand_batch
                    %     cur_trial_ds = cur_trial(1,1:2:end);
                    %     plot((0:2:size(channel_matrix,2)-1)/ds_fs, cur_trial_ds, 'LineWidth',1, 'Color', [tableau_10(chan_colors{ichan}) 0.3]); hold on;
                    % end

                end
                title(sprintf('%d dB SPL Channel %d', my_amp(iname,isubj), cur_chan))
            end
        end
        hold off;
    end
    sgtitle(sprintf('Subject %s',subjid_list{isubj}))
end

for isubj = 1:length(subjid_list)
    % Identify outliers
    for ichan = 1:length(my_chans)
        figure; tiledlayout('flow','TileSpacing','tight','Padding','tight')
        cur_chan = my_chans(ichan);
        outlier_trials = [];
        chan_rms_subj = squeeze(chan_rms(:,cur_chan,:,:,isubj)); % [iname x ibatch x itrial]
        valid_mask = chan_rms_subj > 0;
        chan_rms_subj(~valid_mask) = NaN;

        % Histogram based outlier detection
        nexttile; histogram(chan_rms_subj); title('Histogram'); xlabel('RMS');
        % [thresh_original, ~] = ginput(1);
        thresh_original = 60;
        xline(thresh_original, 'r--', sprintf('thresh=%.0f', thresh_original), 'LineWidth', 1);

        % Extract indices for rejected trials
        [iname_idx, ibatch_idx, itrial_idx] = ind2sub(size(chan_rms_subj), find(chan_rms_subj > thresh_original));

        for irej = 1:length(iname_idx)
            outlier_trials = [outlier_trials; isubj, iname_idx(irej), ibatch_idx(irej), itrial_idx(irej), chan_rms_subj(iname_idx(irej), ibatch_idx(irej), itrial_idx(irej))];
        end

        for irej = 1:size(clipped,1) % [iname, ichan, ibatch, itrial, isubj]
            cur_clip = clipped(irej,:);
            if cur_clip(5) ~= isubj || cur_clip(2) ~= ichan; continue; end
            linear_idx = sub2ind(size(chan_rms), cur_clip(1), cur_clip(2), cur_clip(3), cur_clip(4), cur_clip(5));
            outlier_trials = [outlier_trials; cur_clip(5), cur_clip(1), cur_clip(3), cur_clip(4), chan_rms(linear_idx)];
        end

        % Remove duplicates across rejected based on rms and rejected based
        % on clipping
        outlier_trials = unique(outlier_trials, 'rows');

        % Plot outlying trials
        nexttile;
        for i = 1:size(outlier_trials,1)
            cur_subj  = outlier_trials(i,1);
            cur_name  = outlier_trials(i,2);
            cur_batch = outlier_trials(i,3);
            cur_trial = outlier_trials(i,4);
            plot(grand_ex_save{cur_name,cur_subj}.raw_signals(cur_batch).electrodes_microV_ds(cur_trial,:,cur_chan)); hold on;
            title('Outlying Signals')

            % Add to reject list
            % Get rejected trials list
            if isfield(grand_ex_save{cur_name, cur_subj}, 'rejected_trials')
                cur_reject_list = grand_ex_save{cur_name, cur_subj}.rejected_trials{:};
                if isfield(grand_ex_save{cur_name, cur_subj}, 'rejected_trials_post')
                    cur_reject_list = unique([cur_reject_list grand_ex_save{cur_name, cur_subj}.rejected_trials_post{:}]);
                end
            else
                cur_reject_list = NaN;
                if isfield(grand_ex_save{cur_name, cur_subj}, 'rejected_trials_post')
                    cur_reject_list = unique([cur_reject_list grand_ex_save{cur_name, cur_subj}.rejected_trials_post{:}]);
                end
            end

            % Get trial number of the rejected trial across all batches for this file
            linear_idx = (cur_batch-1)*size(channel_matrix,1)+cur_trial;

            % Check what trials were rejected during testing along with
            % newly rejected ones
            if isnan(cur_reject_list)
                grand_ex_save{cur_name,cur_subj}.rejected_trials_post = {linear_idx};
            else
                if ismember(linear_idx,cur_reject_list)
                    grand_ex_save{cur_name,cur_subj}.rejected_trials_post = {unique([cur_reject_list linear_idx])};
                else
                    added_rej = added_rej +1;
                    grand_ex_save{cur_name,cur_subj}.rejected_trials_post = {unique([cur_reject_list linear_idx])};
                end
            end
        end
        sgtitle(sprintf('Channel %d',my_chans(ichan)))
    end
    fprintf('Added %d rejected trials\n', added_rej)

end

% Plot Scatters
figure; tiledlayout('flow','TileSpacing','tight','Padding','tight')
t1 = nexttile; t2 = nexttile; t3 = nexttile; t4 = nexttile;

for ichan = 1:length(my_chans)
    cur_chan = my_chans(ichan);
    chan_rms(chan_rms == 0) = NaN;
    chan_kurt(chan_kurt == 0) = NaN;
    chan_max(chan_max == 0) = NaN;
    chan_min(chan_min == 0) = NaN;

    chan_rms_mat  = reshape(chan_rms(:,ichan,:,:,:),  [], size(chan_rms,  5));
    chan_kurt_mat = reshape(chan_kurt(:,ichan,:,:,:), [], size(chan_kurt, 5));
    chan_max_mat  = reshape(chan_max(:,ichan,:,:,:),  [], size(chan_max,  5));
    chan_min_mat  = reshape(chan_min(:,ichan,:,:,:),  [], size(chan_min,  5));

    scatter(t1, chan_rms_mat, chan_kurt_mat, 36, tableau_10(chan_colors{ichan}), 'filled', 'MarkerFaceAlpha', 0.5); hold(t1,'on');
    scatter(t2, chan_rms_mat, chan_max_mat,  36, tableau_10(chan_colors{ichan}), 'filled', 'MarkerFaceAlpha', 0.5); hold(t2,'on');
    scatter(t3, chan_rms_mat, chan_min_mat,  36, tableau_10(chan_colors{ichan}), 'filled', 'MarkerFaceAlpha', 0.5); hold(t3,'on');
    scatter(t4, chan_min_mat, chan_max_mat,  36, tableau_10(chan_colors{ichan}), 'filled', 'MarkerFaceAlpha', 0.5); hold(t4,'on');
end

xlabel(t1,'RMS');  ylabel(t1,'Kurtosis'); title(t1,'RMS vs Kurtosis');
xlabel(t2,'RMS');  ylabel(t2,'Max');      title(t2,'RMS vs Max');
xlabel(t3,'RMS');  ylabel(t3,'Min');      title(t3,'RMS vs Min');
xlabel(t4,'Min');  ylabel(t4,'Max');      title(t4,'Min vs Max');
sgtitle(sprintf('Subject %s', subjid_list{isubj}));
legend(string(my_chans))



%% HYDROPHONE
colors = {'blue','orange','red','green','purple','brown','pink','grey','teal','yellow','blue','orange','red','green','purple','brown','pink','grey','teal','yellow'};
clipped = [];
added_rej = 0;

for isubj = 1:length(subjid_list)
    figure; tiledlayout('flow','TileSpacing','tight','Padding','tight')
    for iname = 1:length(my_names{isubj})
        nexttile
        N_batches = size(grand_ex_save{iname,isubj}.raw_signals,2);
        ds_fs = grand_ex_save{iname,isubj}.ds_fs;
        plot_rand_batch = randperm(N_batches, 1);
        for ibatch = 1:N_batches
            hydro_matrix = grand_ex_save{iname,isubj}.raw_signals(ibatch).hydrophone_ds; % itrial x samples
            for itrial = 1:size(hydro_matrix,1)
                cur_trial = hydro_matrix(itrial,:);
                hydro_rms(iname,ibatch,itrial,isubj) = rms(cur_trial);
                hydro_kurt(iname,ibatch,itrial,isubj) = kurtosis(cur_trial);
                hydro_max(iname,ibatch,itrial,isubj) = max(cur_trial);
                hydro_min(iname,ibatch,itrial,isubj) = min(cur_trial);
                if any(cur_trial >= 4500) % 4500 mv near DAC limit, isn't put through a bioamp so no need to divide by 10k
                    clipped = [clipped; iname ibatch itrial isubj];
                end
                if ibatch == plot_rand_batch
                    plot((0:size(hydro_matrix,2)-1)/ds_fs, cur_trial, 'LineWidth',1, 'Color', [tableau_10(colors{iname}) 0.3]); hold on;
                end
            end
            title(sprintf('%d dB SPL', my_amp(iname,isubj)))
        end
        hold off;
    end
    sgtitle(sprintf('Subject %s',subjid_list{isubj}))

    % Identify outliers
    outlier_trials = [];
    hydro_rms_subj = hydro_rms(:,:,:,isubj);
    valid_mask = hydro_rms_subj > 0;
    hydro_rms_subj(~valid_mask) = NaN;

    % Interactive threshold selection
    figure; tiledlayout('flow','TileSpacing','tight','Padding','tight')
    nexttile; histogram(hydro_rms_subj); title('Histogram'); xlabel('RMS');
    % [thresh_original, ~] = ginput(1);
    thresh_original = 60;
    xline(thresh_original, 'r--', sprintf('thresh=%.0f', thresh_original), 'LineWidth', 1);

    % Extract indices for rejected trials
    [iname_idx, ibatch_idx, itrial_idx] = ind2sub(size(hydro_rms_subj), ...
        find(hydro_rms_subj  > thresh_original));
    for irej = 1:length(iname_idx)
        outlier_trials = [outlier_trials; ... %[isubj, iname, ibatch, itrial, rms value]
            isubj, iname_idx(irej), ibatch_idx(irej), itrial_idx(irej), ...
            hydro_rms_subj(iname_idx(irej), ibatch_idx(irej), itrial_idx(irej))];
    end

    % Add in clipped signals as well
    for irej = 1:size(clipped,1) % [iname, ibatch, itrial, isubj]
        cur_clip = clipped(irej,:);
        if cur_clip(4) ~= isubj; continue; end
        linear_idx = sub2ind(size(hydro_rms), cur_clip(1), cur_clip(2), cur_clip(3), cur_clip(4));
        outlier_trials = [outlier_trials; cur_clip(4), cur_clip(1), cur_clip(2), cur_clip(3), hydro_rms(linear_idx)];
    end

    % Remove duplicates across rejected based on rms and rejected based
    % on clipping
    outlier_trials = unique(outlier_trials, 'rows');

    % Plot outlying trials
    nexttile
    for i = 1:size(outlier_trials,1)
        cur_idxs = outlier_trials(i,:);
        cur_subj = cur_idxs(1);
        cur_name = cur_idxs(2);
        cur_batch = cur_idxs(3);
        cur_trial = cur_idxs(4);
        plot(grand_ex_save{cur_name,cur_subj}.raw_signals(cur_batch).hydrophone_ds(cur_trial,:));
        hold on;
        title('Outlying Signals')
        pause(2)
        % Add to reject list in grand_ex_save for later plotting
        % Add to reject list
        if isfield(grand_ex_save{cur_name, cur_subj}, 'rejected_trials_post')
            if ~isempty(grand_ex_save{cur_name,cur_subj}.rejected_trials_post)
                cur_reject_list = grand_ex_save{cur_name,cur_subj}.rejected_trials_post{:};
            else
                cur_reject_list = NaN;
            end
        elseif isfield(grand_ex_save{cur_name, cur_subj}, 'rejected_trials')
            if ~isempty(grand_ex_save{cur_name,cur_subj}.rejected_trials)
                cur_reject_list = grand_ex_save{cur_name,cur_subj}.rejected_trials{:};
            else
                cur_reject_list = NaN;
            end
        else
            cur_reject_list = NaN;
        end
        N_batches = size(grand_ex_save{cur_name,cur_subj}.raw_signals, 2);
        N_trials = size(grand_ex_save{cur_name,cur_subj}.raw_signals(cur_batch).hydrophone_ds, 1);
        linear_idx = sub2ind([N_batches, N_trials], cur_batch, cur_trial);
        if isnan(cur_reject_list)
            grand_ex_save{cur_name,cur_subj}.rejected_trials_post = {linear_idx};
        else
            added_rej = added_rej +1;
            grand_ex_save{cur_name,cur_subj}.rejected_trials_post = {unique([cur_reject_list, linear_idx])};
        end
    end
        fprintf('Added %d rejected trials\n', added_rej)
end

% Scatter plots
% Reshape for scatter
hydro_rms(hydro_rms == 0) = NaN;
hydro_kurt(hydro_kurt == 0) = NaN;
hydro_max(hydro_max == 0) = NaN;
hydro_min(hydro_min == 0) = NaN;

hydro_rms_mat = reshape(hydro_rms, [], size(hydro_rms, 4));
hydro_kurt_mat = reshape(hydro_kurt, [], size(hydro_kurt, 4));
hydro_max_mat = reshape(hydro_max, [], size(hydro_max, 4));
hydro_min_mat = reshape(hydro_min, [], size(hydro_min, 4));

% Plop
figure; tiledlayout('flow','TileSpacing','tight','Padding','tight')

nexttile
scatter(hydro_rms_mat, hydro_kurt_mat, 36, tableau_10('blue'), 'filled', 'MarkerFaceAlpha', 0.5)
xlabel('RMS'); ylabel('Kurtosis'); title('RMS vs Kurtosis')

nexttile
scatter(hydro_rms_mat, hydro_max_mat, 36, tableau_10('orange'), 'filled', 'MarkerFaceAlpha', 0.5)
xlabel('RMS'); ylabel('Max'); title('RMS vs Max')

nexttile
scatter(hydro_rms_mat, hydro_min_mat, 36, tableau_10('red'), 'filled', 'MarkerFaceAlpha', 0.5)
xlabel('RMS'); ylabel('Min'); title('RMS vs Min')

nexttile
scatter(hydro_min_mat, hydro_max_mat, 36, tableau_10('green'), 'filled', 'MarkerFaceAlpha', 0.5)
xlabel('Min'); ylabel('Max'); title('Min vs Max')

sgtitle(sprintf('Subject %s',subjid_list{isubj}))