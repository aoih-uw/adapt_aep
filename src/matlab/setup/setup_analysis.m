function ex = setup_analysis(ex)

% Kept trials
ex.kept.trials = [];
ex.kept.phases = [];
ex.kept.jitter = [];
ex.kept.channels = [];
ex.kept.trials_weighted = [];
ex.kept.trials_filtered = [];

% Model
ex.model.doub_freq_resp_mV = []; % Delete from ex when saving
ex.model.noise_floor = []; % Delete from ex when saving

ex.model.response_mean = [];
ex.model.response_vars = [];

ex.model.noise_floor_mean = [];
ex.model.noise_floor_std = [];

ex.model.amplitude_vec = [];
ex.model.x0_fit = [];
ex.model.a1_fit = [];
ex.model.m_fit = [];
ex.model.y_int = [];

%% Create sound stimulus template
ex = make_tone_burst_template(ex);
ex = make_health_check_signal(ex);

