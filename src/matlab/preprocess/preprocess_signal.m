function ex = preprocess_signal(ex)
% Use this to get iblock for the below functions
% iblock = [ex.block.iteration_num];
% iblock = iblock(end);

% ex.info.signal_quality has many of the parameters you need

remove_line_noise(); % ? test this out
reject_artefacts();
bandpass_filter();
subtract_background(); % Subtract abdomen signal from remaining channels
apply_channel_weights; % Weigh signals by std