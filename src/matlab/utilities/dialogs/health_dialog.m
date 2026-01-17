function ex = health_dialog(ex)

if poor_health && user_decision
    ex.decision.exp_done = 1;
    ex.decision(ex.counter.iamp).amp_done = 1;
    ex.decision(ex.counter.iamp).amp_done_reason = 'User override: Poor health';
    ex.decision.exp_done_reason = 'User override: Poor health';
end