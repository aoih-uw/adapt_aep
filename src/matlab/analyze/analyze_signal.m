function ex = analyze_signal(ex)
separate_periods();
calc_period_diffs();
calc_bootstrap_dist();
model_response();
make_prediction();
is_response_present(); % here ex.decision().amp_done and amp_done_reason will be assigned