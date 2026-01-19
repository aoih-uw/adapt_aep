function ex = analyze_signal(ex)
ex = separate_periods(ex);
ex = calc_period_diffs(ex);
ex = calc_bootstrap_dist(ex);
ex = model_response(ex);
ex = make_decision(ex); % here ex.decision().amp_done and amp_done_reason will be assigned
