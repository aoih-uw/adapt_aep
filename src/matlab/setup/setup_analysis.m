function ex = setup_analysis(ex)

% Kept trials
ex.kept.trials = [];
ex.kept.phases = [];
ex.kept.jitter = [];
ex.kept.channels = [];
ex.kept.trials_weighted = [];
ex.kept.trials_filtered = [];

% Model
ex.model.doub_freq_diff_vec= [];
ex.model.doub_freq_dur_vec= [];

ex.model.doub_freq_diff_temp = [];
ex.model.doub_freq_dur_temp = []; 

ex.model.noise_floor = []; 
ex.model.noise_floor_temp = [];

ex.model.amplitude_vec = [];
ex.model.response_vec = [];
ex.model.resp_found = [];
ex.model.trial_count = [];

ex.model.x0_fit = [];
ex.model.a1_fit = [];
ex.model.m_fit = [];
ex.model.y_int = [];


