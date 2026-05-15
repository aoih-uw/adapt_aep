function plot_model_data_points(myaxes, amplitude_sorted, per_amp_noise_sorted, ...
    per_amp_noise_mad_sorted, trial_count_sorted, response_sorted, response_std_sorted, resp_found_sorted)

for i = 1:length(amplitude_sorted)
    % Plot individual amplitude noise_floor dots
    errorbar(myaxes, amplitude_sorted(i), per_amp_noise_sorted(i), per_amp_noise_mad_sorted(i), ...
        'o','MarkerFaceColor', tableau_10('grey'), 'MarkerEdgeColor', tableau_10('grey'), ...
        'MarkerSize', 4+6*(1 - trial_count_sorted(i) / max(trial_count_sorted)), 'Color', tableau_10('grey'));
end

% Plot individual amplitude dots
for i = 1:length(amplitude_sorted)
    if resp_found_sorted(i) == 1
        color = tableau_10('green');

    else
        color = tableau_10('red');
    end
    errorbar(myaxes, amplitude_sorted(i), response_sorted(i), response_std_sorted(i), ...
        'o', 'MarkerSize', 4+6*(1 - trial_count_sorted(i) / max(trial_count_sorted)), ...
        'MarkerFaceColor', color, 'MarkerEdgeColor', color, 'Color', color);
end

xlim(myaxes,[min(amplitude_sorted)-1.5 max(amplitude_sorted)+1.5])
ylim(myaxes,[min(per_amp_noise_sorted)-0.1, max(response_sorted)+0.1])