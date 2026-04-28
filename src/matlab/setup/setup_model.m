function ex = setup_model(ex)

% Model
ex.model.doub_freq_stim_ON_vec = []; 
ex.model.noise_floor = []; 
ex.model.amplitude_vec = [];

ex.model.amplitude_vec_sorted = [];
ex.model.response_vecs_sorted = [];
ex.model.resp_found_sorted = [];
ex.model.trial_count_sorted = [];

ex.model.x0_fit = [];
ex.model.a1_fit = [];
ex.model.m_fit = [];
ex.model.y_int = [];
ex.model.Rsquared = [];