function [FFT_block_FFTs, ex] = calculateFFTBlock_FFT(FFT_block_avgs, ifft, Nchan, channel_names, ...
    signals_to_track, ex, ifreq, iamp, fs, response_names,current_freq,rec_params)
% FFT_block_avgs.(curchan_name).prestimresp = new_prestimresp_avg;
% FFT_block_avgs.(curchan_name).stimresp = new_stimresp_avg;
% FFT_block_avgs.(curchan_name).poststimresp = new_poststimresp_avg;

double_freq = current_freq*2;
window = 4; % Include frequencies +/- 4 Hz above and below the frequencies of interest in amplitude calculations
downsample_factor = rec_params.downsample_factor;
fs = fs/downsample_factor;

for ich = 1:Nchan
    for itype = 1:length(response_names)
        curchan_name = channel_names{ich};
        curresp_name = response_names{itype};

        % Extract current iteration of averaged waveforms
        waveform = FFT_block_avgs.(curchan_name).(curresp_name);
        waveform_std = FFT_block_avgs.(curchan_name).([curresp_name '_std']);

        % Force consistent zero-padding for exact frequency resolution
        desired_freq_resolution = 0.5; % Hz
        target_length = ceil(fs / desired_freq_resolution);
        current_length = length(waveform);
        
        if current_length < target_length
            % Zero-pad to reach target length
            pad_length = target_length - current_length;
            waveform = [waveform, zeros(size(waveform,1), pad_length)];
            waveform_std = [waveform_std, zeros(size(waveform_std,1), pad_length)];
        elseif current_length > target_length
            % This shouldn't happen if waveforms are consistent, but just in case
            error('Waveform longer than expected, truncating to maintain resolution');
        end
        
        % Compute FFT
        Y = fft(waveform);
        Y_std = fft(waveform_std);
        N = size(waveform,2);

        % Calculate number of positive frequency bins (including DC and Nyquist if present)
        n_positive_freqs = floor(N/2) + 1;

        % Create frequency vector for positive frequencies only
        frequencies = fs * (0:(n_positive_freqs-1))/N;

        % Keep only the first half (since the result is symmetric for real input)
        P2 = abs(Y/N); % P2 = full length FFT magnitude spectrum
        P1 = P2(1:n_positive_freqs); % P1 only positive frequencies are included
        P1(2:end-1) = 2*P1(2:end-1); % Multiply by 2 (except DC and Nyquist) to conserve total energy

        % Calculate amplitude standard deviation from FFT of std waveform
        P2_std = abs(Y_std/N); % Full length FFT magnitude spectrum of std
        P1_std = P2_std(1:n_positive_freqs); % Keep positive frequencies only
        P1_std(2:end-1) = 2*P1_std(2:end-1); % Multiply by 2 to match energy scaling
        
        % Phase for positive frequencies
        phase_full = angle(Y); % Returns phase in radians
        phase = phase_full(1:n_positive_freqs); % Keep first half, matching P1

        % Store overall results
        FFT_block_FFTs.(curchan_name).(curresp_name).FFT = P1;
        FFT_block_FFTs.(curchan_name).(curresp_name).FFT_std = P1_std;
        FFT_block_FFTs.(curchan_name).(curresp_name).phase = phase;
        FFT_block_FFTs.(curchan_name).(curresp_name).frequencies = frequencies;

        % Ex structure
        ex{ifreq, iamp}.electrodes.(curchan_name).FFTcalcs.(curresp_name).FFT{ifft} = P1;
        ex{ifreq, iamp}.electrodes.(curchan_name).FFTcalcs.(curresp_name).FFT_std{ifft} = P1_std;
        ex{ifreq, iamp}.electrodes.(curchan_name).FFTcalcs.(curresp_name).phase{ifft} = phase;
        ex{ifreq, iamp}.electrodes.(curchan_name).FFTcalcs.(curresp_name).frequencies{ifft} = frequencies;

        % Calculate current frequency resolution for adaptive windowing
        freq_resolution = fs / length(waveform);
        
        % Now calculate the average amplitude for signals of interest
        for isignal = 1:length(signals_to_track)
            cursignal = signals_to_track{isignal};
            
            % Determine target frequency for each signal type
            if strcmp(cursignal, 'sixty_cycle')
                target_freq = 60;
            elseif strcmp(cursignal, 'stimulus_freq')
                target_freq = current_freq;
            elseif strcmp(cursignal, 'double_freq')
                target_freq = double_freq;
            else
                error('Unknown signal type: %s', cursignal);
            end
            
            % Find closest frequency bin to target
            [~, closest_idx] = min(abs(frequencies - target_freq));
            
            % Fixed ±4 Hz window around target frequency
            window_half_width = 4; % Hz
            freq_lower = target_freq - window_half_width;
            freq_upper = target_freq + window_half_width;
            
            % Find indices for frequencies within the ±4 Hz window
            window_mask = (frequencies >= freq_lower) & (frequencies <= freq_upper);
            myindicies = find(window_mask);
            
            % Ensure we have at least one frequency bin
            if isempty(myindicies)
                % If no bins in range, use closest bin
                myindicies = closest_idx;
                warning('No frequency bins found in ±4 Hz window around %.1f Hz, using closest bin only', target_freq);
            end
            
            % Calculate mean amplitude for frequencies within current window
            windowed_fft = P1(myindicies);
            windowed_fft_std = P1_std(myindicies);
            windowed_meanmag = mean(windowed_fft,2);
            windowed_meanmag_std = mean(windowed_fft_std); % Want to know the average std associated with this window
            window_freqs = frequencies(myindicies);

            % DEBUG: Display frequency window details
            if ich == 1 && itype == 1  % Only display once per signal type (first channel, first response type)
                fprintf('\n=== FREQUENCY WINDOW DEBUG ===\n');
                fprintf('Signal: %s\n', cursignal);
                fprintf('Target frequency: %.2f Hz\n', target_freq);
                fprintf('Frequency resolution: %.3f Hz\n', freq_resolution);
                fprintf('Closest bin index: %d (%.2f Hz)\n', closest_idx, frequencies(closest_idx));
                fprintf('Window indices: %d to %d\n', myindicies(1), myindicies(end));
                fprintf('Window frequencies: ');
                for freq_idx = 1:length(window_freqs)
                    fprintf('%.2f ', window_freqs(freq_idx));
                end
                fprintf(' Hz\n');
                fprintf('Window width: %.2f Hz (%d bins)\n', ...
                    window_freqs(end) - window_freqs(1), length(window_freqs));
                fprintf('Mean amplitude in window: %.6f\n', windowed_meanmag);
                fprintf('===============================\n');
            end
            
            % Store signal type specific info
            FFT_block_FFTs.(curchan_name).(curresp_name).(cursignal).windowSize = length(myindicies);
            FFT_block_FFTs.(curchan_name).(curresp_name).(cursignal).frequencies = window_freqs;
            FFT_block_FFTs.(curchan_name).(curresp_name).(cursignal).FFT = windowed_fft;
            FFT_block_FFTs.(curchan_name).(curresp_name).(cursignal).FFT_std = windowed_fft_std;
            FFT_block_FFTs.(curchan_name).(curresp_name).(cursignal).amplitude = windowed_meanmag;
            FFT_block_FFTs.(curchan_name).(curresp_name).(cursignal).amplitude_std = windowed_meanmag_std;

        end
    end
end

%% Plotting FFT Results
% Find existing figure or create new one
fig_handle = findobj('Type', 'figure', 'Tag', 'FFT_AllChannels');
if isempty(fig_handle)
   fig_handle = figure('Name', 'FFT Analysis - All Channels', 'Tag', 'FFT_AllChannels');
   set(fig_handle, 'Position', [100, 100, 800, 600]); % [left, bottom, width, height]
else
   figure(fig_handle); % Bring existing figure to front
end
clf; % Clear any existing plots

% Calculate frequency bounds for plotting
double_freq = current_freq * 2;
lower_freq = current_freq - 100;  % 100 Hz below current_freq
upper_freq = double_freq + 100;   % 100 Hz above double_freq

%% Pre-calculate y-limit based on double_freq amplitude in stimresp data
max_amplitude_at_double_freq = 0;

% Loop through channels to find maximum amplitude at double_freq in stimresp data
for ich = 1:Nchan
   curchan_name = channel_names{ich};
   
   % Check if stimresp data exists for this channel
   if isfield(FFT_block_FFTs.(curchan_name), 'stimresp')
       frequencies = FFT_block_FFTs.(curchan_name).stimresp.frequencies;
       fft_data = FFT_block_FFTs.(curchan_name).stimresp.FFT;
       
       % Find amplitude at double_freq using interpolation
       if double_freq >= min(frequencies) && double_freq <= max(frequencies)
           amplitude_at_double_freq = interp1(frequencies, fft_data, double_freq, 'linear');
           max_amplitude_at_double_freq = max(max_amplitude_at_double_freq, amplitude_at_double_freq);
       end
   end
end

% Calculate y-limit (double the maximum amplitude)
y_limit_upper = max_amplitude_at_double_freq * 2;

% Pre-allocate subplot handles array for better performance
subplot_handles = zeros(1, Nchan*2);

% Loop through channels and create subplots
for ich = 1:Nchan
   curchan_name = channel_names{ich};
   
   % Plot prestim FFT (left column)
   subplot_idx_prestim = (ich-1)*2 + 1;
   h1 = subplot(4, 2, subplot_idx_prestim);
   subplot_handles(subplot_idx_prestim) = h1;
   
   % Check if prestim data exists
   if isfield(FFT_block_FFTs.(curchan_name), 'prestim')
       frequencies = FFT_block_FFTs.(curchan_name).prestim.frequencies;
       fft_data = FFT_block_FFTs.(curchan_name).prestim.FFT;
       fft_std = FFT_block_FFTs.(curchan_name).prestim.FFT_std;
       
       % Plot main FFT data
       plot(frequencies, fft_data, 'b-', 'LineWidth', 1.5);
       hold on;
       % Plot +1 standard deviation trace
       plot(frequencies, fft_data + fft_std, 'b--', 'LineWidth', 0.5);
       % Add vertical lines at stimulus and double frequencies
       xline(current_freq, 'k--', 'Alpha', 0.7);
       xline(double_freq, 'k--', 'Alpha', 0.7);
       hold off;
       
       set(gca, 'XScale', 'log');
       xlim([lower_freq, upper_freq]); % 100 Hz below current_freq to 100 Hz above double_freq
       ylim([0, y_limit_upper]); % Set consistent y-limit
       grid on;
       title(sprintf('%s - Prestim FFT', upper(curchan_name)));
       xlabel('Frequency (Hz)');
       ylabel('Amplitude');
   else
       text(0.5, 0.5, 'No prestim data', 'HorizontalAlignment', 'center');
       title(sprintf('%s - Prestim FFT (No Data)', upper(curchan_name)));
       ylim([0, y_limit_upper]); % Set consistent y-limit even for no data
   end
   
   % Plot stimresp FFT (right column)
   subplot_idx_stimresp = (ich-1)*2 + 2;
   h2 = subplot(4, 2, subplot_idx_stimresp);
   subplot_handles(subplot_idx_stimresp) = h2;
   
   % Check if stimresp data exists
   if isfield(FFT_block_FFTs.(curchan_name), 'stimresp')
       frequencies = FFT_block_FFTs.(curchan_name).stimresp.frequencies;
       fft_data = FFT_block_FFTs.(curchan_name).stimresp.FFT;
       fft_std = FFT_block_FFTs.(curchan_name).stimresp.FFT_std;
       
       % Plot main FFT data
       plot(frequencies, fft_data, 'r-', 'LineWidth', 1.5);
       hold on;
       % Plot +1 standard deviation trace
       plot(frequencies, fft_data + fft_std, 'r--', 'LineWidth', 0.5);
       % Add vertical lines at stimulus and double frequencies
       xline(current_freq, 'k--', 'Alpha', 0.7);
       xline(double_freq, 'k--', 'Alpha', 0.7);
       hold off;
       
       set(gca, 'XScale', 'log');
       xlim([lower_freq, upper_freq]); % 100 Hz below current_freq to 100 Hz above double_freq
       ylim([0, y_limit_upper]); % Set consistent y-limit
       grid on;
       title(sprintf('%s - Stimresp FFT', upper(curchan_name)));
       xlabel('Frequency (Hz)');
       ylabel('Amplitude');
   else
       text(0.5, 0.5, 'No stimresp data', 'HorizontalAlignment', 'center');
       title(sprintf('%s - Stimresp FFT (No Data)', upper(curchan_name)));
       ylim([0, y_limit_upper]); % Set consistent y-limit even for no data
   end
end

% Link all subplot axes for synchronized zooming/panning
if ~isempty(subplot_handles)
   linkaxes(subplot_handles, 'xy');
end

try
    % Adjust subplot spacing for better readability
    set(gcf, 'AutoResizeChildren', 'off');
    sgtitle('FFT Analysis: Prestim vs Stimresp by Channel');
catch ME
    % Optional: Display warning if you want to know when it fails
    warning('Figure formatting failed');
    % Script continues regardless of error
end