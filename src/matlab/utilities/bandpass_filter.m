function sigout = bandpass_filter(sig_in,cutoff_low,cutoff_high,order)
% function sigout = bandpassfilter(sig_in,notchfreq)
%
% This is a simple bandpass filter. Inputs are self-explanatory.

if cutoff_low == cutoff_high;
    cutoff_low = cutoff_low-10; cutoff_high = cutoff_high+10;
elseif cutoff_low < cutoff_high
    error('cutoff_low must be less than cutoff_high');
end

% set up filter; We are going to assume that the samprate is 44100...
d = designfilt('bandpassfir', 'FilterOrder', order, ...
             'CutoffFrequency1', cutoff_low, 'CutoffFrequency2', cutoff_high,...
             'SampleRate', 44100); 
         
sigout = filtfilt(d,sig_in);