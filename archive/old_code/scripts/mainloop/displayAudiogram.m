function [audiogram_fig, audiogram_axes] = displayAudiogram(current_freq, current_amplitude, ...
    ifreq, iamp, itrial, loop_exit_reason, possible_amplitudes, ex, ...
    stim_params, exp_params, audiogram_fig, audiogram_axes, ...
    ifreq_index, presentation_order)
% plotAudiogram - Plot a single frequency point on the audiogram
%
% Inputs:
%   current_freq - Current frequency being tested (Hz)
%   current_amplitude - Current amplitude being tested (dB)
%   ifreq - Frequency index in the frequencies array
%   iamp - Amplitude index in possible_amplitudes array
%   itrial - Number of trials completed for this frequency
%   loop_exit_reason - Reason why frequency testing completed
%   possible_amplitudes - Array of all possible amplitude levels
%   ex - Experiment data structure
%   stim_params - Stimulus parameters structure
%   exp_params - Experiment parameters structure
%   audiogram_fig - Handle to audiogram figure
%   audiogram_axes - Handle to audiogram axes
%   ifreq_index - Current frequency index in presentation order
%   presentation_order - Order of frequency presentation
%
% Outputs:
%   audiogram_fig - Updated figure handle
%   audiogram_axes - Updated axes handle

%% EDGE CASE HANDLING: Before audiogram plotting

% Handle case where no trials were completed for this frequency
if itrial == 0
    fprintf('Warning: No trials completed for frequency %.1f Hz\n', current_freq);
    % Set defaults for plotting
    audiogram_amplitude = possible_amplitudes(1);  % Use max amplitude
    audiogram_response_detected = false;
    plot_marker = 'o';  % Circle
    plot_color = [0.5, 0.5, 0.5];  % Gray
    loop_exit_reason = 'no_trials_completed';
    
    fprintf('Plotting untested frequency at max amplitude %.1f dB\n', audiogram_amplitude);
else
    % Normal processing - keep existing logic here
    audiogram_amplitude = current_amplitude;
    audiogram_response_detected = false;
    plot_marker = 'o';  % Circle
    plot_color = [1, 0, 0];  % Red - default
    
    % VALIDATION: Ensure we have valid data before plotting
    if isempty(current_freq) || isnan(current_freq)
        fprintf('Error: Invalid frequency data for audiogram plotting\n');
        error('Invalid frequency data - cannot plot audiogram point');
    end
    
    if isempty(current_amplitude) || isnan(current_amplitude)
        fprintf('Error: Invalid amplitude data for audiogram plotting\n');
        current_amplitude = possible_amplitudes(iamp);  % Fallback to array value
        audiogram_amplitude = current_amplitude;
    end
    
    % VALIDATION: Ensure loop_exit_reason is set
    if isempty(loop_exit_reason)
        fprintf('Warning: loop_exit_reason not set. Setting to unknown.\n');
        loop_exit_reason = 'unknown_exit';
    end
    
    fprintf('\n=== AUDIOGRAM PLOTTING ANALYSIS ===\n');
    fprintf('Frequency: %.1f Hz (index %d/%d)\n', current_freq, ifreq_index, length(presentation_order));
    fprintf('Exit reason: %s\n', loop_exit_reason);
    fprintf('Current amplitude: %.1f dB (index %d/%d)\n', current_amplitude, iamp, length(possible_amplitudes));
    
    %% Determine plotting parameters based on how we completed this frequency
    % Simplified: Use only circle markers, color-coded by exit reason
    plot_marker = 'o';  % Always use circles
    marker_size = 40;  % Standard size
    
    if strcmp(loop_exit_reason, 'all_amplitudes_tested')
        % We found responses at multiple amplitudes - plot the lowest (best) amplitude with response
        % Find the lowest amplitude where we confirmed a response
        best_response_found = false;
        for amp_idx = length(possible_amplitudes):-1:1  % Start from lowest amplitude
            if amp_idx <= size(ex, 2) && ~isempty(ex{ifreq, amp_idx}) && ...
                    isfield(ex{ifreq, amp_idx}, 'decision') && ex{ifreq, amp_idx}.decision == 1
                audiogram_amplitude = possible_amplitudes(amp_idx);
                audiogram_response_detected = true;
                best_response_found = true;
                fprintf('Found confirmed response at %.1f dB\n', audiogram_amplitude);
                break;
            end
        end
        
        if ~best_response_found
            fprintf('Warning: Expected response data but none found. Using current amplitude.\n');
            audiogram_amplitude = current_amplitude;
        end
        
        plot_color = [0, 0.8, 0];  % Green - Response detected
        
    elseif strcmp(loop_exit_reason, 'user_skipped_frequency')
        % User chose to skip - plot current amplitude as no response
        audiogram_amplitude = current_amplitude;
        audiogram_response_detected = false;
        plot_color = [0, 0, 1];  % Blue - User skipped
        fprintf('User skipped frequency - plotting no response at %.1f dB\n', audiogram_amplitude);
        
    elseif strcmp(loop_exit_reason, 'max_trials_reached')
        % Max trials reached without response - plot current amplitude
        audiogram_amplitude = current_amplitude;
        audiogram_response_detected = false;
        plot_color = [1, 0.5, 0];  % Orange - Max trials reached
        fprintf('Max trials reached - plotting no response at %.1f dB\n', audiogram_amplitude);
        
    elseif strcmp(loop_exit_reason, 'no_trials_completed')
        % No trials completed
        plot_color = [0.5, 0.5, 0.5];  % Gray - No trials
        
    else
        % Fallback case - shouldn't happen but provides safety
        fprintf('Warning: Unexpected loop exit reason: %s\n', loop_exit_reason);
        audiogram_amplitude = current_amplitude;
        audiogram_response_detected = false;
        plot_color = [1, 0, 1];  % Magenta - Unknown
    end
end

% EDGE CASE: Handle last frequency specially
if ifreq_index == length(presentation_order)
    fprintf('This is the final frequency in the experiment.\n');
end

% EDGE CASE: Check if we're testing frequencies in a valid range
if current_freq < stim_params.min_freq || current_freq > stim_params.max_freq
    fprintf('Warning: Testing frequency %.1f Hz outside defined range [%.1f, %.1f] Hz\n', ...
        current_freq, stim_params.min_freq, stim_params.max_freq);
end

% VALIDATION: Final check before plotting
if audiogram_amplitude < stim_params.minAmplitude || audiogram_amplitude > stim_params.maxAmplitude
    fprintf('Warning: Amplitude %.1f dB outside valid range [%.1f, %.1f]. Clamping.\n', ...
        audiogram_amplitude, stim_params.minAmplitude, stim_params.maxAmplitude);
    audiogram_amplitude = max(stim_params.minAmplitude, ...
        min(stim_params.maxAmplitude, audiogram_amplitude));
end

% EDGE CASE: Check if audiogram figure was accidentally closed
if ~isvalid(audiogram_fig) || ~isvalid(audiogram_axes)
    fprintf('Warning: Audiogram figure was closed. Recreating...\n'); 
    
    audiogram_fig = figure('Name', 'Audiogram', 'NumberTitle', 'off');
    
    % Position figure in top right of primary monitor (laptop screen)
    % Get screen size of primary monitor
    screen_size = get(0, 'MonitorPositions');
    primary_monitor = screen_size(1, :); % First row is primary monitor
    primary_width = primary_monitor(3);
    primary_height = primary_monitor(4);
    
    % Set figure size (adjust as needed)
    fig_width = 400;
    fig_height = 700;
    
    % Calculate position for top right corner
    fig_x = primary_width - fig_width - 50; % 50px margin from right edge
    fig_y = primary_height - fig_height - 100; % 100px margin from top (accounts for taskbar)
    
    % Set figure position
    set(audiogram_fig, 'Position', [fig_x, fig_y, fig_width, fig_height]);
    
    audiogram_axes = axes(audiogram_fig);
    
    % Reset axes properties
    xlabel(audiogram_axes, 'Frequency (Hz)');
    ylabel(audiogram_axes, 'Amplitude (dB)');
    title(audiogram_axes, [exp_params.fish_ID, ' Audiogram'], 'Interpreter', 'none');
    xlim(audiogram_axes, [stim_params.min_freq stim_params.max_freq]);
    ylim(audiogram_axes, [stim_params.minAmplitude stim_params.maxAmplitude]);
    
    set(audiogram_axes, 'YDir', 'reverse');
    hold(audiogram_axes, 'on');
    grid(audiogram_axes, 'on');
    
    fprintf('Audiogram figure recreated successfully.\n');
end

%% FIX: Set tick marks every time (not just during recreation)
% Calculate tick marks with validation
freq_range = stim_params.max_freq - stim_params.min_freq;
amp_range = stim_params.maxAmplitude - stim_params.minAmplitude;

% Use adaptive tick spacing based on range
if freq_range <= 100
    freq_tick_spacing = 10;
elseif freq_range <= 500
    freq_tick_spacing = 20;
else
    freq_tick_spacing = 50;
end

if amp_range <= 50
    amp_tick_spacing = 5;
elseif amp_range <= 100
    amp_tick_spacing = 10;
else
    amp_tick_spacing = 20;
end

% Generate tick arrays with proper bounds
x_ticks = stim_params.min_freq:freq_tick_spacing:stim_params.max_freq;
y_ticks = stim_params.minAmplitude:amp_tick_spacing:stim_params.maxAmplitude;

% Ensure tick arrays are not empty
if isempty(x_ticks)
    x_ticks = [stim_params.min_freq, stim_params.max_freq];
end
if isempty(y_ticks)
    y_ticks = [stim_params.minAmplitude, stim_params.maxAmplitude];
end

% Apply tick marks with error handling
try
    set(audiogram_axes, 'XTick', x_ticks);
    set(audiogram_axes, 'YTick', y_ticks);
    
    % Force tick mark update
    set(audiogram_axes, 'XTickMode', 'manual');
    set(audiogram_axes, 'YTickMode', 'manual');
    
    % Debug output
    fprintf('Tick marks set: X-ticks [%.1f:%.1f:%.1f], Y-ticks [%.1f:%.1f:%.1f]\n', ...
        x_ticks(1), freq_tick_spacing, x_ticks(end), ...
        y_ticks(1), amp_tick_spacing, y_ticks(end));
    
catch ME
    fprintf('Warning: Could not set tick marks. Error: %s\n', ME.message);
    % Fallback to automatic ticks
    set(audiogram_axes, 'XTickMode', 'auto');
    set(audiogram_axes, 'YTickMode', 'auto');
end

%% DIAGNOSTIC: Pre-plotting validation and debugging
fprintf('\n=== PLOTTING DIAGNOSTICS ===\n');
fprintf('About to plot point:\n');
fprintf('  Frequency: %.2f Hz\n', current_freq);
fprintf('  Amplitude: %.2f dB\n', audiogram_amplitude);
fprintf('  Color: %s\n', plot_color);
fprintf('  Marker: %s\n', plot_marker);
fprintf('  Axes limits: X=[%.1f, %.1f], Y=[%.1f, %.1f]\n', ...
    xlim(audiogram_axes), ylim(audiogram_axes));

% Check if point is within axes limits (with margin check)
x_limits = xlim(audiogram_axes);
y_limits = ylim(audiogram_axes);

% Add small margin to limits for visibility
x_margin = (x_limits(2) - x_limits(1)) * 0.05;
y_margin = (y_limits(2) - y_limits(1)) * 0.05;

if current_freq < (x_limits(1) + x_margin) || current_freq > (x_limits(2) - x_margin)
    fprintf('WARNING: Frequency %.2f is near/at X-axis edge [%.1f, %.1f]\n', ...
        current_freq, x_limits(1), x_limits(2));
end
if audiogram_amplitude < (y_limits(1) + y_margin) || audiogram_amplitude > (y_limits(2) - y_margin)
    fprintf('WARNING: Amplitude %.2f is near/at Y-axis edge [%.1f, %.1f]\n', ...
        audiogram_amplitude, y_limits(1), y_limits(2));
    
    % If point is at the exact edge, adjust it slightly inward for visibility
    if audiogram_amplitude >= y_limits(2)
        audiogram_amplitude = y_limits(2) - y_margin;
        fprintf('ADJUSTED: Moved amplitude to %.2f for visibility\n', audiogram_amplitude);
    end
    if audiogram_amplitude <= y_limits(1)
        audiogram_amplitude = y_limits(1) + y_margin;
        fprintf('ADJUSTED: Moved amplitude to %.2f for visibility\n', audiogram_amplitude);
    end
end

% Verify axes handle is valid
if ~isvalid(audiogram_axes)
    fprintf('ERROR: Axes handle is invalid!\n');
    return;
end

% Check current axes state
fprintf('Axes state:\n');
fprintf('  Hold: %s\n', get(audiogram_axes, 'NextPlot'));
fprintf('  Visible: %s\n', get(audiogram_axes, 'Visible'));
fprintf('  Children count: %d\n', length(get(audiogram_axes, 'Children')));

%% Proceed with plotting using validated parameters
fprintf('Executing scatter plot...\n');

% Use larger marker size and ensure it's visible
marker_size = 50;  % Increased from 100
try
    h_scatter = scatter(audiogram_axes, current_freq, audiogram_amplitude, marker_size, plot_color, plot_marker, 'filled');
    
    % Verify the scatter object was created
    if isvalid(h_scatter)
        fprintf('SUCCESS: Scatter object created successfully\n');
        fprintf('  Handle: %s\n', class(h_scatter));
        fprintf('  XData: %.2f\n', get(h_scatter, 'XData'));
        fprintf('  YData: %.2f\n', get(h_scatter, 'YData'));
        fprintf('  SizeData: %.1f\n', get(h_scatter, 'SizeData'));
        fprintf('  Marker: %s\n', get(h_scatter, 'Marker'));
        fprintf('  Visible: %s\n', get(h_scatter, 'Visible'));
    else
        fprintf('ERROR: Scatter object is invalid after creation\n');
    end
    
catch ME
    fprintf('ERROR creating scatter plot: %s\n', ME.message);
    fprintf('Full error:\n');
    disp(ME);
end

% Count children again after plotting
fprintf('Axes children count after plotting: %d\n', length(get(audiogram_axes, 'Children')));

% Create label text with response status
if audiogram_response_detected
    label_text = sprintf('%.1f Hz (R)', current_freq);  % R = Response
else
    label_text = sprintf('%.1f Hz (NR)', current_freq); % NR = No Response
end

% Add text label
try
    h_text = text(audiogram_axes, current_freq + (stim_params.max_freq - stim_params.min_freq)*0.02, ...
        audiogram_amplitude, label_text, 'FontSize', 8);
    
    if isvalid(h_text)
        fprintf('Text label created successfully\n');
    else
        fprintf('Text label creation failed\n');
    end
catch ME
    fprintf('ERROR creating text label: %s\n', ME.message);
end

% Force immediate display update
fprintf('Calling drawnow...\n');
drawnow;

% Additional refresh to ensure everything appears
fprintf('Calling refresh...\n');
refresh(audiogram_fig);

fprintf('=== END PLOTTING DIAGNOSTICS ===\n');

if audiogram_response_detected
    response_status = 'Response';
else
    response_status = 'No Response';
end

fprintf('Successfully plotted on audiogram: %.1f Hz at %.1f dB (%s)\n', ...
    current_freq, audiogram_amplitude, response_status);

fprintf('=== END AUDIOGRAM PLOTTING ===\n\n');

end