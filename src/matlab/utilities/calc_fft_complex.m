function [freq_vec, Y_pos] = calc_fft_complex(stimulus, fs)
% Here phase is saved
if ~isvector(stimulus), error('calc_fft: expects a vector'); end
stimulus = stimulus(:)';
N = numel(stimulus);
K = floor(N/2);
freq_vec = (0:K)*(fs/N);
Y = fft(stimulus)/N;
Y_pos = Y(1:K+1);
if mod(N,2) == 0
    Y_pos(2:end-1) = 2*Y_pos(2:end-1);
else
    Y_pos(2:end) = 2*Y_pos(2:end);
end