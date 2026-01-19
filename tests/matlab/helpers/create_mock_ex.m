function ex = create_mock_ex
addpath(genpath("\\wsl$\ubuntu\home\aoih\adapt_aep\src\matlab"))
ex = setup_ex();

ex.info.animal.subject_ID = 1;
ex.info.animal.sex = 'F';
ex.info.animal.health = 'Good';
ex.info.stimulus.frequency_hz = 100;
ex.info.stimulus.amplitude_spl = 130;
ex.info.stimulus.type = 'Tone burst';
ex.info.adaptive.response_feature = 'Double frequency';
ex.info.adaptive.trials_per_block = 20;
ex.info.adaptive.max_trials = 1000;
ex.info.animal.filename = [ex.info.animal.species_name '_' ...
    num2str(ex.info.animal.subject_ID) '_' ...
    num2str(ex.info.stimulus.frequency_hz) '_Hz_' ...
    num2str(ex.info.stimulus.amplitude_spl) '_SPL_' ...
    ex.info.experiment.exp_date '_' ...
    ex.info.experiment.exp_time_start];
ex.info.recording.latency_samples = 100;
ex.info.stimulus.correction_factor_sf = 1;