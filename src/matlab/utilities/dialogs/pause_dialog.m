function [action, ex] = pause_dialog(ex)
    % Creates a simple dialog when pause is pressed
    % Returns: action = 'continue', 'change', or 'stop'
    
    % Create dialog
    d = dialog('Position', [300 300 500 300], 'Name', 'Experiment Paused', 'Color', 'w');
    
    % Add title text
    uicontrol('Parent', d, 'Style', 'text', 'Position', [20 240 460 40], ...
        'String', 'Paused', 'FontSize', 16, 'FontWeight', 'bold', ...
        'BackgroundColor', 'w', 'ForegroundColor', 'k');
    
    % Initialize action
    action = 'continue';
    
    % Continue button
    uicontrol('Parent', d, 'Position', [50 160 400 50], ...
        'String', 'Resume testing', 'FontSize', 12, ...
        'BackgroundColor', [0.94 0.94 0.94], 'ForegroundColor', 'k', ...
        'Callback', @(~,~) continue_callback());
    
    % Change amplitude button
    uicontrol('Parent', d, 'Position', [50 90 400 50], ...
        'String', 'Change amplitude', 'FontSize', 12, ...
        'BackgroundColor', [0.94 0.94 0.94], 'ForegroundColor', 'k', ...
        'Callback', @(~,~) change_callback());
    
    % Stop button
    uicontrol('Parent', d, 'Position', [50 20 400 50], ...
        'String', 'End experiment', 'FontSize', 12, ...
        'BackgroundColor', [0.94 0.94 0.94], 'ForegroundColor', 'k', ...
        'Callback', @(~,~) stop_callback());
    
    % Wait for dialog to close
    uiwait(d);
    
    % Callback functions
    function continue_callback()
        action = 'continue';
        delete(d);
    end
    
    function change_callback()
        action = 'change';
        save_data(ex);
        ex.decision(ex.counter.iamp).amp_done = 1;
        ex.decision(ex.counter.iamp).amp_done_reason = 'User override';
        ex = select_next(ex);
        delete(d);
    end
    
    function stop_callback()
        action = 'stop';
        save_data(ex);
        fprintf('Experiment stopped by user\n');
        ex.decision(ex.counter.iamp).amp_done = 1;
        ex.decision.exp_done = 1;
        ex.decision(ex.counter.iamp).amp_done_reason = 'User override';
        ex.decision.exp_done_reason = 'User override';
        ex = end_experiment(ex);
        delete(d);
    end
end