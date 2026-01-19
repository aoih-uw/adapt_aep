function resp_found_dialog(ex)
    % Create dialog
    d = dialog('Position', [300 300 350 150], 'Name', 'Response Detected');
    
    % Message
    uicontrol('Parent', d, 'Style', 'text', ...
              'Position', [20 100 310 30], ...
              'String', 'A response was detected. What would you like to do?', ...
              'FontSize', 10);
    
    % Continue button
    uicontrol('Parent', d, 'Position', [20 50 100 30], ...
              'String', 'Continue Testing', ...
              'Callback', @(~,~) continue_testing());
    
    % New amplitude button
    uicontrol('Parent', d, 'Position', [125 50 100 30], ...
              'String', 'New Amplitude', ...
              'Callback', @(~,~) new_amplitude());
    
    % End experiment button
    uicontrol('Parent', d, 'Position', [230 50 100 30], ...
              'String', 'End Experiment', ...
              'Callback', @(~,~) end_experiment());
    
    uiwait(d);
    
    function continue_testing()
        ex.decision(ex.counter.iamp).amp_done = 0;
        delete(d);
    end
    
    function new_amplitude()
        ex.decision(ex.counter.iamp).amp_done = 1;
        delete(d);
    end
    
    function end_experiment()
        ex.decision(ex.counter.iamp).amp_done = 1;
        ex.decision.exp_done_reason = 'Successfully finished testing at current amplitude, user decided to not test further amplitudes.';
        delete(d);
    end
end