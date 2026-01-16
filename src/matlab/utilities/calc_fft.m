function [N, freq_vec, fft_vals ] = calc_fft(stimulus, fs)
% calculate the fft and save only the 1st half of the results (i.e., the
% positive values.)
N = length(stimulus);
K = floor(N/2);

freq_vec = (0:K)*(fs/N);

Y = fft(stimulus);
P2 = abs(Y/N); % normalized magnitude spectrum

P1 = P2(1:K+1); % 1 = DC, N/2 + 1 = Nyquist, include both

% Handle nyquist depending on N is even or not
if mod(N,2) == 0
    P1(2:end-1) = 2*P1(2:end-1); % nyquist bin does exist at fs/2
else
    P1(2:end) = 2*P1(2:end); % There is no nyquist bin, the last bin should be doubled
end

fft_vals = P1;