function ex = check_health(ex, app)
ex.counter.health = ex.counter.health + 1;

% Present sound

% Save response

x_vec = 1:ex.counter.health; 
y_vec = zeros(1,ex.counter.iblock);


% Fit linear regression
p = polyfit(x_vec, y_vec, 1);      % p(1) = slope, p(2) = intercept

plot(app.health_ax, x_vec, y_vec)
hold(app.health_ax, 'on')
plot(app.health_ax, x_vec, polyval(p, x_vec), 'r--')
xlabel(app.health_ax, 'Check point')
ylabel(app.health_ax, 'Double Freq. Response Mag.')

rel_strength = y_vec(end)/max(y_vec); % find the relative strenght of the last check to the highest response

% If the last response magnitude is less than 
if rel_strength > 0.8
    ex.health(1).status = good;
    ex = health_dialog(ex);
end