function ex = prepare_next_amp(ex)
ex.info.stimulus.amplitude = ex.next_amplitude; % Set by select_next_GUI

% Store most recent model parameters to use for next amplitude
ex.info.model.initial_x0 = ex.model(end).fit_x0;
ex.info.model.initial_kappa = ex.model(end).fit_kappa;
ex.info.model.initial_lambda = ex.model(end).fit_lambda;
ex.info.model.initial_max_resp = ex.model(end).fit_max_resp;

ex.info.model.initial_x_vector = ex.model(end).x_vector;
ex.info.model.initial_y_vector = ex.model(end).y_vector;