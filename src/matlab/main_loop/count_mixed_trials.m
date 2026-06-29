function ex = count_mixed_trials(ex,app)
%% Count which trials in the testing schedule have been presented and plot these counts to a heatmap
% test_schedule: rows = n total trials to test, columns stimuli_type, stimulus_amplitude, n_trials_needed, unique_idx
test_schedule = ex.info.mixed.test_schedule;
ischedule = ex.counter.ischedule;
uniq_stimuli = ex.info.mixed.uniq_stimuli;
N_unique_stimuli = ex.info.mixed.N_unique_stimuli;
trials_per_block = ex.info.trials.trials_per_block;

% Preallocate completion matrix
completion_mat = zeros(N_unique_stimuli,1);

completed_schedule = test_schedule(1:ischedule,:); % Get list of stimuli we have tested up till now
[unique_tested_stimuli, ~, all_idx] = unique(completed_schedule, 'rows'); % Get idxs of unique stimuli we have tested up till now
[~, ~, idx] = unique(all_idx); % Need to count unique instances of each unique stimuli to count
unique_counts = accumarray(idx, 1); % Here are the counts

completion_mat(unique_tested_stimuli(:,4)) = unique_counts ./ unique_tested_stimuli(:,3);

%% Plot heatmap
% Reshape completion_mat into 2D: rows = stim_type, cols = amplitude
stim_types = unique(uniq_stimuli(:,1));
amplitudes = unique(uniq_stimuli(:,2));

% Generate 2d heatmap
heat_2d = zeros(length(stim_types), length(amplitudes));
for i = 1:N_unique_stimuli
    r = find(stim_types == uniq_stimuli(i,1));
    c = find(amplitudes == uniq_stimuli(i,2));
    heat_2d(r, c) = completion_mat(i);
end

% Find or recreate figure if closed
fig = findobj('Type','figure','Tag','heatmap_fig');
if isempty(fig)
    fig = figure('Tag','heatmap_fig','Name','Trial Progress');
end
figure(fig); clf;

imagesc(heat_2d);
for r = 1:length(stim_types)
    for c = 1:length(amplitudes)
        text(c, r, sprintf('%1.2f%%', heat_2d(r,c)*100), ...
            'HorizontalAlignment','center', 'VerticalAlignment','middle', 'FontSize', 8);
    end
end
n = 256; blue = tableau_10('blue');
colormap([linspace(1,blue(1),n)', linspace(1,blue(2),n)', linspace(1,blue(3),n)']);
clim([0 max(completion_mat(:))]);
xticks(1:length(amplitudes)); xticklabels(amplitudes);
yticks(1:length(stim_types)); yticklabels(ex.info.mixed.stim_name(stim_types));
title('Mixed Stimuli Experiment Progress')
ylabel('Stimuil type')
xlabel('Amplitude (dB SPL)')

% Print out % Complete
fprintf('Experiment progress: %1.2f%% complete, %d/%d trials\n', (ischedule/size(test_schedule,1)*100), ...
    ischedule*trials_per_block, size(test_schedule,1)*trials_per_block)