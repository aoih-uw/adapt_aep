
d1 = gradient(y_vec, x_vec);
d2 = gradient(d1, x_vec);
[~, idx] = max(d2);
x_max = x_vec(idx);

% My functions
dsoftplus_dx = @(p,x) p(1) ./ (1 + exp(-p(2).*(x - p(3))));

rise_mask = y_vec > noise_floor + 0.1 * (max(y_vec) - noise_floor);
x_kneedle = x_vec(rise_mask);
yn = (y_vec(rise_mask) - min(y_vec(rise_mask))) / (max(y_vec(rise_mask)) - min(y_vec(rise_mask)));
xn = (x_kneedle - min(x_kneedle)) / (max(x_kneedle) - min(x_kneedle));
[~, ki] = max(yn - xn);
x_t = x_kneedle(ki);
y_t = softplus(p, x_t);
                    slope = dsoftplus_dx(p, x_t);  % = p(1) / (1 + exp(-p(2)*(x_t - p(3))))
x_cross = x_t - (y_t - noise_floor) / slope;

                    my_x_thresh(i_it,i_tri,ichan,isubj) = x_cross;

figure
tiledlayout(3,1,'TileSpacing','tight','Padding','tight');
titles = {'softplus','1st derivative','2nd derivative'};
data = {y_vec, d1, d2};
for r = 1:3
    nexttile; plot(x_vec, data{r}, '-k', 'LineWidth', 1);
    xl1 = xline(x_max, 'Color', tableau_10('green'),  'LineWidth', 3, 'DisplayName', '2nd deriv max');
    xl2 = xline(x_t,   'Color', tableau_10('orange'), 'LineWidth', 3, 'DisplayName', 'Kneedle');
    xl3 = xline(x_cross,   'Color', tableau_10('red'), 'LineWidth', 3, 'DisplayName', 'Threshold');
    title(titles{r});
    if r == 3, legend([xl1 xl2],'Location','southoutside'); end
    yline(noise_floor)
end
