function ex = analyze_signal(ex)
ex = separate_periods(ex);

if ex.decision(ex.counter.iamp).resp_found
    ex = model_response(ex); % Start modeling once you have 2 points, Determine here if elbow point has stabilized w/in 3 dB for past 
end