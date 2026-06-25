function plot_model_data_points(myaxes, amplitude_sorted, per_amp_noise_sorted, ...
    per_amp_noise_mad_sorted, trial_count_sorted, response_sorted, response_std_sorted, resp_found_sorted)

for i = 1:length(amplitude_sorted)
    % Plot individual amplitude noise_floor dots
    errorbar(myaxes, amplitude_sorted(i), per_amp_noise_sorted(i), per_amp_noise_mad_sorted(i), ...
        'o','MarkerFaceColor', tableau_10('grey'), 'MarkerEdgeColor', tableau_10('grey'), ...
        'MarkerSize', 5, 'Color', tableau_10('grey'));
end

% Plot individual amplitude dots
for i = 1:length(amplitude_sorted)
    if resp_found_sorted(i) == 1
        color = tableau_10('green');

    else
        color = tableau_10('red');
    end
    errorbar(myaxes, amplitude_sorted(i), response_sorted(i), response_std_sorted(i), ...
        'o', 'MarkerSize', 5, ...
        'MarkerFaceColor', color, 'MarkerEdgeColor', color, 'Color', color);
end

y_low  = [min(per_amp_noise_sorted)-max(per_amp_noise_mad_sorted)];
y_high = [max(response_sorted)      + max(response_std_sorted)];

ylim(myaxes, [y_low - 0.1, y_high + 0.1])
xlim(myaxes, [min(amplitude_sorted)-5, max(amplitude_sorted)+5])