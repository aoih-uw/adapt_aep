function [any_significant_response] =  checkifResponse_FFT(ifreq, iamp,ex, any_significant_response)
FFT_block_FFTs.(curchan_name).(curresp_name).(cursignal).windowSize = length(myindicies);
            FFT_block_FFTs.(curchan_name).(curresp_name).(cursignal).frequencies = window_freqs;
            FFT_block_FFTs.(curchan_name).(curresp_name).(cursignal).FFT = windowed_fft;
            FFT_block_FFTs.(curchan_name).(curresp_name).(cursignal).amplitude = windowed_meanmag;

% Check each channel for significant responses and user decisions
for ch = 1:4
    channel_field = ['ch' num2str(ch)];

    % Skip channels without data
    if ~isfield(ex{ifreq, iamp}.electrodes, channel_field) || ...
            ~isfield(ex{ifreq, iamp}.electrodes.(channel_field), 'fft_pval') || ...
            isempty(ex{ifreq, iamp}.electrodes.(channel_field).fft_pval)
        continue;
    end

    % Get channel p-value
    channel_p_value = ex{ifreq, iamp}.electrodes.(channel_field).fft_pval;

    % Check if this channel has a significant response
    if channel_p_value <= adaptive_params.pval_threshold
        any_significant_response(ch)=1;
    else
        any_significant_response(ch)=0;
    end
end
end