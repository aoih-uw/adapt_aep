function ex = setup_stimuli(ex)
%% Create sound stimulus templates
ex = make_tone_burst_template(ex);
ex = make_health_check_signal(ex);