function sigout = bandpassfilter(sigin,cutofflow,cutoffhigh,order,fs)
% function sigout = bandpassfilter(sigin,notchfreq)
%
% This is a simple bandpass filter. Inputs are self-explanatory.

if cutofflow > cutoffhigh
    error('cutofflow must be less than cutoffhigh');
end

% set up filter; 
d = designfilt('bandpassfir', 'FilterOrder', order, ...
             'CutoffFrequency1', cutofflow, 'CutoffFrequency2', cutoffhigh,...
             'SampleRate', fs); 
         
sigout = filtfilt(d,sigin); 

%% About filtfilt
% Filters the signal twice, once forward, once backward and combines the
% results. The result has these characteristics:
% Zero phase distortion
% A filter transfer function equal to the squared magnitude of the original filter transfer function
% A filter order that is double the order of the filter specified by b and a