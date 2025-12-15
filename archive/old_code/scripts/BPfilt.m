function sig_out = BPfilt(varargin)
%function sig_out = BPfilt(sig_in,order,cutoff1,cutoff2,fs)
%
% This function returns a highpass output signal given an input signal
% (sig_in) and arguments specifying the order (order) and cutoff frequency
% (cutoff) in Hz of a Butterworth filter given a the signal samprate
% (samprate). Optional second cutoff frequency can be defined to set
% passband (narrowband with 1 CF will be assumed otherwise
if nargin > 4
    sig_in = varargin{1};
    order = varargin{2};
    cutoff1 = varargin{3};
    cutoff2 = varargin{4};
    fs = varargin{5};
else
    sig_in = varargin{1};
    order = varargin{2};
    cutoff1 = varargin{3};
    cutoff2 = cutoff1;
    fs = 44100;
end


% if nargin==4
%     [b,a]=butter(order,[(cutoff1)/(fs/2) (cutoff2)/(fs/2)],'bandpass');
% else
    [b,a]=butter(order,[(cutoff1)/(fs/2) (cutoff2)/(fs/2)],'bandpass');
% end

sig_out=filtfilt(b,a,sig_in);