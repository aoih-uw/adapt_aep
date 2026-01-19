function ex = health_dialog(ex)
    status = ex.health(1).status;
    if strcmp(status, 'poor')
        choice = questdlg(['Animal health status: ' status '! Continue testing?'], ...
                         'Health Warning', ...
                         'Continue testing', 'End experiment', 'Continue testing');
        
        if strcmp(choice, 'End experiment')
            ex.decision.exp_done = 1;
            ex.decision(ex.counter.iamp).amp_done = 1;
            ex.decision(ex.counter.iamp).amp_done_reason = 'User override: Poor health';
            ex.decision.exp_done_reason = 'User override: Poor health';
        end
    end
end