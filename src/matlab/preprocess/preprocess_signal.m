function ex = preprocess_signal(ex)

% Use this to get iblock for the below functions
% iblock = [ex.block.iteration_num];
% iblock = iblock(end);

ex = remove_line_noise(ex); % ? test this out
ex = reject_artefacts(ex);
ex = bandpass_filter(ex);
ex = subtract_background(ex); % Subtract abdomen signal from remaining channels
ex = apply_channel_weights; % Weigh signals by std