function ex = preprocess_signal(ex,app)
ex = reject_artefacts(ex,app); 
ex = apply_channel_weights(ex); 
ex = filter_signals(ex);

% In the future functions
% subtract_background(); % Figure out if needed later Subtract abdomen signal from remaining channels
% remove_line_noise(); % ? test this out
