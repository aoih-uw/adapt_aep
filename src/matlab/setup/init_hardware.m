function ex = init_hardware(ex)
% D/A converter
ex = init_dac(ex);
ex = test_latency(ex);

% Check that other hardware is on and uses the right settings
check_hardware_on