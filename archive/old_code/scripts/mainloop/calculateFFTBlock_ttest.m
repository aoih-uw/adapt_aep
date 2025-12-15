function [FFT_block_TTest, any_significant_response, alpha_spent, adapt_params,ex] = calculateFFTBlock_ttest(ex,ifreq,iamp,ifft, frequencies, current_amplitude, adapt_params, alpha_spent, ...
                    channel_names,FFT_block_FFTs,any_significant_response, maxTrialNum)
% channel_names = {'ch1', 'ch2', 'ch3', 'ch4'};
% response_names = {'prestim', 'stimresp', 'poststimresp'};
% signals_to_track = {'stimulus_freq','double_freq','60_cycle'};

% Initialize variables
FFT_block_TTest = struct();

% Calculate alpha value for this current comparison
trialsSoFar = ex{ifreq,iamp}.electrodes.(channel_names{1}).running_stats.stimresp.N(ifft);
alpha_slice = lanDeMets_Linear(trialsSoFar, maxTrialNum, adapt_params, ifft, alpha_spent);

% Initialize t-test variables
p_vector = zeros(1,length(channel_names));
tstat_vec = zeros(size(p_vector));
df_vec = zeros(size(p_vector));

for ichan = 1:length(channel_names)
    curchan_name = channel_names{ichan};
    % Compare the double_freq frequency range average amplitude of prestim
    % and stimresp periods. If there was a present auditory response, we
    % would expect to see a statistically significant larger ampltiude
    % value in the stimresp double frequency amplitude compared to the
    % prestim signal

    prestim_mean = FFT_block_FFTs.(curchan_name).prestim.double_freq.amplitude; % Mean of the amplitudes within frequency window of the cumulative averaged waveform
    prestim_std = FFT_block_FFTs.(curchan_name).prestim.double_freq.amplitude_std; % Mean std associated with the frequencies in the window
    prestim_N = ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.prestim.N(ifft); % Total number of trials included in the cumulative averaged waveform

    stimresp_mean = FFT_block_FFTs.(curchan_name).stimresp.double_freq.amplitude; % Mean of the amplitudes within frequency window of the cumulative averaged waveform
    stimresp_std = FFT_block_FFTs.(curchan_name).stimresp.double_freq.amplitude_std; % Mean std associated with the frequencies in the window
    stimresp_N = ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.stimresp.N(ifft); % Total number of trials included in the cumulative averaged waveform

    % Apply check to see if prestim_N and stimresp_N have same values
    if prestim_N ~= stimresp_N
        error('The number of trials included in the pre-stimulus average is not the same as the stimulus response')
    end

    [p, t_stat, df] = ttest_from_summary(stimresp_mean, stimresp_std, stimresp_N, prestim_mean, prestim_std, prestim_N);
    
    p_vector(ichan)   = p;
    tstat_vec(ichan)  = t_stat;
    df_vec(ichan)     = df;
end

% DEBUG: Check what we're actually comparing
fprintf('\n=== DEBUG: T-TEST INPUT VALUES ===\n');
for ichan = 1:length(channel_names)
    fprintf('Channel %s:\n', channel_names{ichan});
    fprintf('  Prestim:  mean=%.6f, std=%.6f, N=%d\n', ...
        FFT_block_FFTs.(channel_names{ichan}).prestim.double_freq.amplitude, ...
        FFT_block_FFTs.(channel_names{ichan}).prestim.double_freq.amplitude_std, ...
        ex{ifreq, iamp}.electrodes.(channel_names{ichan}).running_stats.prestim.N(ifft));
    fprintf('  Stimresp: mean=%.6f, std=%.6f, N=%d\n', ...
        FFT_block_FFTs.(channel_names{ichan}).stimresp.double_freq.amplitude, ...
        FFT_block_FFTs.(channel_names{ichan}).stimresp.double_freq.amplitude_std, ...
        ex{ifreq, iamp}.electrodes.(channel_names{ichan}).running_stats.stimresp.N(ifft));
    fprintf('  Difference: %.6f, Effect size: %.3f\n', ...
        FFT_block_FFTs.(channel_names{ichan}).stimresp.double_freq.amplitude - ...
        FFT_block_FFTs.(channel_names{ichan}).prestim.double_freq.amplitude, ...
        (FFT_block_FFTs.(channel_names{ichan}).stimresp.double_freq.amplitude - ...
         FFT_block_FFTs.(channel_names{ichan}).prestim.double_freq.amplitude) / ...
        sqrt((FFT_block_FFTs.(channel_names{ichan}).prestim.double_freq.amplitude_std^2 + ...
              FFT_block_FFTs.(channel_names{ichan}).stimresp.double_freq.amplitude_std^2)/2));
    fprintf('  P-value: %.8f, T-stat: %.3f\n\n', p_vector(ichan), tstat_vec(ichan));
end
fprintf('Alpha slice being used: %.8f\n', alpha_slice);
fprintf('=====================================\n');

% DEBUG: Check if this is a systematic bias
fprintf('\n=== SYSTEMATIC BIAS CHECK ===\n');
total_channels_negative = sum([FFT_block_FFTs.(channel_names{1}).stimresp.double_freq.amplitude - FFT_block_FFTs.(channel_names{1}).prestim.double_freq.amplitude, ...
                              FFT_block_FFTs.(channel_names{2}).stimresp.double_freq.amplitude - FFT_block_FFTs.(channel_names{2}).prestim.double_freq.amplitude, ...
                              FFT_block_FFTs.(channel_names{3}).stimresp.double_freq.amplitude - FFT_block_FFTs.(channel_names{3}).prestim.double_freq.amplitude, ...
                              FFT_block_FFTs.(channel_names{4}).stimresp.double_freq.amplitude - FFT_block_FFTs.(channel_names{4}).prestim.double_freq.amplitude] < 0);
fprintf('Channels with prestim > stimresp: %d out of %d\n', total_channels_negative, length(channel_names));
if total_channels_negative >= 3
    fprintf('Pattern suggests: Systematic bias\n');
else
    fprintf('Pattern suggests: Random variation\n');
end
fprintf('=====================================\n');

[h_vector, crit_vector]= holm_bonferroni(p_vector,alpha_slice);

%% Output results onto command window
dispStatsSummary(frequencies, current_amplitude, ifreq, iamp, ifft, ...
    trialsSoFar, maxTrialNum, alpha_slice, alpha_spent, adapt_params, ...
    channel_names, p_vector, tstat_vec, df_vec, h_vector)

for ichan = 1:length(channel_names)
    curchan_name = channel_names{ichan};

    % Save results
    FFT_block_TTest.(curchan_name).h = h_vector(ichan);
    FFT_block_TTest.(curchan_name).crit = crit_vector(ichan);
    FFT_block_TTest.(curchan_name).p = p_vector(ichan);
    FFT_block_TTest.(curchan_name).t_stat = tstat_vec(ichan);
    FFT_block_TTest.(curchan_name).df = df_vec(ichan);

    % To the ex structure
    ex{ifreq, iamp}.electrodes.(curchan_name).stats_tests.fft_ttest_verdict{ifft} = h_vector(ichan);
    ex{ifreq, iamp}.electrodes.(curchan_name).stats_tests.fft_ttest_pval{ifft} = p_vector(ichan);
    ex{ifreq, iamp}.electrodes.(curchan_name).stats_tests.fft_ttest_critval{ifft} = crit_vector(ichan);
    ex{ifreq, iamp}.electrodes.(curchan_name).stats_tests.fft_ttest_tstat{ifft} = tstat_vec(ichan);
    ex{ifreq, iamp}.electrodes.(curchan_name).stats_tests.fft_ttest_df{ifft} = df_vec(ichan);
end

% Check if there is any significant response
any_significant_response = any(h_vector);

% Update cumulative alpha spent for this condition
if ifft == 1
    alpha_spent(ifft) = alpha_slice;
else
    alpha_spent(ifft) = alpha_spent(ifft-1) + alpha_slice;
end


function [p, t_stat, df] = ttest_from_summary(mean1, std1, n1, mean2, std2, n2)
% Two-sample Welch's t-test from summary statistics
% Does NOT assume equal variances (more robust)

% Calculate standard error of the difference using separate variances
se1 = std1^2 / n1;
se2 = std2^2 / n2;
se_diff = sqrt(se1 + se2);

% Calculate t-statistic
t_stat = (mean1 - mean2) / se_diff;

% Calculate Welch-Satterthwaite degrees of freedom
df = (se1 + se2)^2 / (se1^2/(n1-1) + se2^2/(n2-1));

% Calculate p-value (two-tailed)
p = 2 * (1 - tcdf(abs(t_stat), df));
end

function alpha_slice = lanDeMets_Linear(trialsSoFar, maxTrialNum, adapt_params, ifft, alpha_spent)
% Lan-DeMets α spending with a linear (Hwang-Shih-DeCani) spending
% function (more conservative in early comparisons, and more liberal by
% middle comparisons

% alpha_spent(tau) = tau * alpha_total; tau = information fraction = trialsSoFar/maxTrialNum

tau = trialsSoFar / maxTrialNum;
alphaToSpend = tau * adapt_params.alpha_total; %How much alpha I am allowed to have spent BY THIS POINT
if ifft == 1
    alpha_slice = alphaToSpend;
else
    alpha_slice = alphaToSpend - alpha_spent(ifft-1); % How much alpha do we have left based on how much we have already spent
end
end

function [h, crit] = holm_bonferroni(p, alpha_slice)
    % Vectorized Holm-Bonferroni decision, returns logical vector h
    % Compare the smallest p value to the most stringent alpha value to
    % prevent false discoveries
    h = false(size(p)); % Pre-allocate output array
    [p_sorted,idx] = sort(p);
    m = numel(p);
    crit = alpha_slice ./ (m-(0:m-1));
    h_sorted = p_sorted <= crit;
    first_false = find(~h_sorted,1);
    if ~isempty(first_false),h_sorted(first_false:end) = false; end
    h(idx) = h_sorted;
end

function dispStatsSummary(frequencies, current_amplitude, ifreq, iamp, ifft, ...
    trialsSoFar, maxTrialNum, alpha_slice, alpha_spent, adapt_params, ...
    channel_names, p_vector, tstat_vec, df_vec, h_vector)
% Display detailed statistical results
fprintf('\n=== STATISTICAL ANALYSIS RESULTS ===\n');
fprintf('Frequency: %.1f Hz, Amplitude: %.1f dB, FFT Block: %d\n', ...
    frequencies(ifreq), current_amplitude, ifft);
fprintf('Trials collected so far: %d / %d (%.1f%%)\n', ...
    trialsSoFar, maxTrialNum, 100*trialsSoFar/maxTrialNum);

% Lan-DeMets results
fprintf('\n--- LAN-DEMETS ALPHA SPENDING ---\n');
fprintf('Information fraction (tau): %.3f\n', trialsSoFar/maxTrialNum);
fprintf('Alpha slice for this test: %.6f\n', alpha_slice);
if ifft > 1
    fprintf('Cumulative alpha spent: %.6f / %.6f\n', ...
        alpha_spent(ifft), adapt_params.alpha_total);
    fprintf('Remaining alpha budget: %.6f\n', ...
        adapt_params.alpha_total - alpha_spent(ifft));
else
    fprintf('First test - no previous alpha spending\n');
end

% Individual electrode results
fprintf('\n--- INDIVIDUAL ELECTRODE RESULTS ---\n');
fprintf('%-8s %-10s %-8s %-8s %-12s\n', 'Channel', 'P-value', 'T-stat', 'DF', 'Significant?');
fprintf('%-8s %-10s %-8s %-8s %-12s\n', '-------', '-------', '------', '--', '------------');
for ich = 1:length(channel_names)
    sig_text = {'No', 'YES'};
    fprintf('%-8s %-10.6f %-8.2f %-8d %-12s\n', ...
        channel_names{ich}, p_vector(ich), tstat_vec(ich), df_vec(ich), ...
        sig_text{h_vector(ich)+1});
end

% Holm-Bonferroni correction details
fprintf('\n--- HOLM-BONFERRONI CORRECTION ---\n');
[p_sorted, sort_idx] = sort(p_vector);
m = length(p_vector);
crit_values = alpha_slice ./ (m-(0:m-1));

fprintf('Alpha slice used: %.6f\n', alpha_slice);
fprintf('%-8s %-10s %-12s %-12s %-8s\n', 'Rank', 'P-value', 'Critical', 'Pass Test?', 'Channel');
fprintf('%-8s %-10s %-12s %-12s %-8s\n', '----', '-------', '--------', '----------', '-------');

h_sorted = p_sorted <= crit_values;
first_false = find(~h_sorted,1);
if ~isempty(first_false)
    h_sorted(first_false:end) = false;
end

for i = 1:length(p_sorted)
    pass_text = {'FAIL', 'PASS'};
    fprintf('%-8d %-10.6f %-12.6f %-12s %-8s\n', ...
        i, p_sorted(i), crit_values(i), pass_text{h_sorted(i)+1}, ...
        channel_names{sort_idx(i)});
end

% Summary
fprintf('\n=== SUMMARY ===\n');
num_significant = sum(h_vector);
fprintf('Channels with significant responses: %d / %d\n', num_significant, length(channel_names));
if num_significant > 0
    sig_channels = channel_names(h_vector);
    fprintf('Significant channels: %s\n', strjoin(sig_channels, ', '));
end
fprintf('=====================================\n');
end
end