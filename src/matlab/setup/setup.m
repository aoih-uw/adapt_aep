function ex = setup()
% Set up ex structure
ex = setup_ex();

%% Initialize Hardware
% D/A converter
ex = init_dac(ex);
ex = test_latency(ex);
% Audio hardware
ex = init_audio(ex);

% Check that other hardware is on and uses the right settings
check_hardware_on