function ex = setup_model(ex)
%% Setup model field of ex structure
% Model
ex.model.stim_ON_2f_vec = []; 
ex.model.stim_OFF_2f_vec = []; 
ex.model.diff_2f_vec = [];
ex.model.amplitude_vec = [];

ex.model.amplitude_vec_sorted = [];
ex.model.response_vec_sorted = [];

ex.model.per_amp_noise_sorted = [] ;
ex.model.resp_found_sorted = [];
ex.model.trial_count_sorted = [];

ex.model.x0_fit         = [];
ex.model.a1_fit         = [];
ex.model.k_fit          = [];
ex.model.threshold      = [];
ex.model.gp_threshold   = [];