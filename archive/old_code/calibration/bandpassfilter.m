function sigout = bandpassfilter(sigin,cutofflow,cutoffhigh,order)
% function sigout = bandpassfilter(sigin,notchfreq)
%
% This is a simple bandpass filter. Inputs are self-explanatory.

if cutofflow == cutoffhigh;
    cutofflow = cutofflow-10; cutoffhigh = cutoffhigh+10;
elseif cutofflow < cutoffhigh
    error('cutofflow must be less than cutoffhigh');
end

% set up filter; We are going to assume that the samprate is 44100...
d = designfilt('bandpassfir', 'FilterOrder', order, ...
             'CutoffFrequency1', cutofflow, 'CutoffFrequency2', cutoffhigh,...
             'SampleRate', 44100); 
         
sigout = filtfilt(d,sigin);