function ex = setup(ex)
%% Create sound stimulus template
ex = make_tone_burst(ex);

%% Initialize Hardware
% D/A converter
ex = init_dac(ex);
ex = test_latency(ex);

% Check that other hardware is on and uses the right settings
check_hardware_on