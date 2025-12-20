function ex = setup()
ex = setup_ex(); % Initialize data structure
ex = load_stim_cali(ex); % Stimulus calibration variables
ex = measure_noise_floor(ex);
ex = make_tone_burst(ex); % Create sound stimulus
ex = init_hardware(ex); % Initialization