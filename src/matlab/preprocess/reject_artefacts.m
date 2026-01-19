function ex = reject_artefacts(ex)
% Reject artefacts and display count of number of trials w/ rejected
% artefacts
% Make sure if one channel has large artefact, rest of channels will also
% be thrown out? Think about this
reject_threshold = ex.info.signal_quality.rejection_threshold_sd;

ex.block(iblock).num_rejected
ex.block(iblock).reject_rate
