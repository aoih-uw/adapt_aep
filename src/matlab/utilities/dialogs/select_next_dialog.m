function ex = select_next_dialog(ex)
% Select which stimulus amplitude to test next or end experiment
% Create dialog
d = dialog('Position', [400 400 400 250], 'Name', 'Set Amplitude', 'Color', 'w');

% Title text
uicontrol('Parent', d, 'Style', 'text', 'Position', [20 190 360 40], ...
    'String', 'Enter new stimulus amplitude (dB SPL):', ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', 'w', 'ForegroundColor', 'k');

% Input box
txt = uicontrol('Parent', d, 'Style', 'edit', 'Position', [100 140 200 40], ...
    'FontSize', 14, 'BackgroundColor', 'w', 'ForegroundColor', 'k');

% Submit button
uicontrol('Parent', d, 'Position', [100 80 200 40], ...
    'String', 'Submit', 'FontSize', 12, ...
    'BackgroundColor', [0.94 0.94 0.94], 'ForegroundColor', 'k', ...
    'Callback', @(~,~) submit_callback());

% End Experiment button
uicontrol('Parent', d, 'Position', [100 30 200 40], ...
    'String', 'End Experiment', 'FontSize', 12, ...
    'BackgroundColor', [0.94 0.94 0.94], 'ForegroundColor', 'k', ...
    'Callback', @(~,~) end_callback());

% Wait for dialog
uiwait(d);

    function submit_callback()
        val = str2double(get(txt, 'String'));
        if ~isnan(val) && isscalar(val)
            ex.info.stimulus.amplitude_spl = val;
            delete(d);
        else
            errordlg('Please enter a valid number', 'Invalid Input');
        end
    end

    function end_callback()
        ex.decision.exp_done = 1;
        ex.decision(ex.counter.iamp).amp_done = 1;
        ex.decision(ex.counter.iamp).exp_done_reason = 'User terminated experiment';
        save_data(ex)
        ex = end_experiment(ex);
        delete(d);
    end
end