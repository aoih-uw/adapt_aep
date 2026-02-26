function ex = setup_hardware(ex)
ex = init_dac(ex);
ex = init_audio(ex);
ex = test_latency(ex);
