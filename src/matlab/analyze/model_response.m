function ex = model_response(ex)
% Get current iteration number
iblock = [ex.block.iteration_num];
iblock = iblock(end);

response_fn = ex.info.model.response_fn;

% Assign model parameter guess vector
if iblock == 1 % first block for current amplitude
    % if this is not the 1st tested amplitude, 
    % will use previous amplitudes final fitted parameters
    guess = [ex.info.model.initial_x0, ... 
             ex.info.model.initial_kappa, ...
             ex.info.model.initial_lambda, ...
             ex.info.model.initial_max_resp];
else
    guess = [ex.model(end).fit_x0, ...
             ex.model(end).fit_kappa, ...
             ex.model(end).fit_lmbda, ...
             ex.model(end).fit_max_resp];
end

last_x_vector = ex.model(end).x_vector;
last_y_vector = ex.model(end).y_vector;

new_x = ex.info.stimulus.amplitude;
new_y = ex.analysis(end).ci_lower;

x_vector = [last_x_vector, new_x];
y_vector = [last_y_vector, new_y];

ex.model(iblock).x_vector = x_vector;
ex.model(iblock).y_vector = y_vector;

try
    % Study lsqcurve fit!!
    fitted_params = lsqcurvefit(response_fn, guess, x_vector, y_vector);
catch ME
    fprintf('Curve fitting error: %s\n', ME.message)
    save_data(ex)
    rethrow(ME)
end

ex.model(iblock).fit_x0 = fitted_params(1);
ex.model(iblock).fit_kappa = fitted_params(2);
ex.model(iblock).fit_lmbda = fitted_params(3);
ex.model(iblock).fit_max_resp = fitted_params(4);
