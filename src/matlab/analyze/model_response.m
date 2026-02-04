function ex = model_response(ex)
doub_freq_resp_vec_mV = ex.model.doub_freq_resp_vec_mV;
amplitude_vec = ex.model.amplitude_vec;

[amplitude_sorted, sort_idx] = sort(amplitude_vec);
response_sorted = doub_freq_resp_vec_mV(sort_idx);

plot(amplitude_sorted,response_sorted)
hold on;

% If have enough data points, then fit the piecewise
if size(amplitude_sorted,2) >= 3
end