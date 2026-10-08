function ex = preprocess_signal(ex,app)
%% Handles preprocessing of electrode signals 
% Assign variables
fs = ex.info.DAC.sampling_rate_hz;
pass_band_hz = ex.info.signal_quality.pass_band_hz;
ex.no_valid_trials = 0;

%% Reject artefacts but not in timed mode
if ~strcmp(ex.info.experiment.exp_type,'Timed')
    ex = reject_artefacts_single(ex,app);
end
