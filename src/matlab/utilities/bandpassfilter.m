function sigout = bandpassfilter(sigin, d)
sigout = filtfilt(d, sigin);
end

%% About filtfilt
% Filters the signal twice, once forward, once backward and combines the
% results. The result has these characteristics:
% Zero phase distortion
% A filter transfer function equal to the squared magnitude of the original filter transfer function
% A filter order that is double the order of the filter specified by b and a