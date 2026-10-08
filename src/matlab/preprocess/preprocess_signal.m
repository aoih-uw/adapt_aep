function ex = preprocess_signal(ex,app)
%% Handles preprocessing of electrode signals 
% Assign variables
ex.no_valid_trials = 0;

%% Reject artefacts but not in timed mode
if ~strcmp(ex.info.experiment.exp_type,'Timed')
    ex = reject_artefacts_single(ex,app);
end
