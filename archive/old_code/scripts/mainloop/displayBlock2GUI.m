function displayBlock2GUI(app,FFT_block_avgs, FFT_block_FFTs, FFT_block_TTest, Nchan, channel_names, ifft)
global gui_channel_data

    function valid_axes = validateAxesForLinking(axes_array)
        % Helper function to validate axes handles before linking
        valid_axes = [];
        
        if isempty(axes_array)
            return;
        end
        
        for i = 1:length(axes_array)
            ax = axes_array(i);
            
            % Check if handle is valid and is an axes object
            if isvalid(ax) && isa(ax, 'matlab.graphics.axis.Axes')
                % Check if axes has any children (plotted data)
                if ~isempty(get(ax, 'Children'))
                    valid_axes = [valid_axes, ax];
                end
            end
        end
    end

%% Clear axes if starting with new stimulus type
if ifft == 1
    % Clear channel-specific axes (waveform, FFT, and p-value)
    for ich = 1:4
        % Clear waveform axes
        cla(app.(sprintf('wavAvgFig%d', ich)));
        
        % Clear FFT axes
        cla(app.(sprintf('fftAvgFig%d', ich)));
        
        % Clear p-value axes
        cla(app.(sprintf('pValTrackerFig%d', ich)));
        
        % Clear accumulated p-value data arrays
        gui_channel_data.pval_x_data{ich} = [];
        gui_channel_data.pval_y_data{ich} = [];
        gui_channel_data.crit_x_data{ich} = [];
        gui_channel_data.crit_y_data{ich} = [];
    end
    
    % Clear single tracker axes
    cla(app.sixtyCycleTrackFig);
    cla(app.stimFreqTrackFig);
    cla(app.doubleFreqTrackFig);
end

%% Define Tableau 10 color scheme for channels
tableau_colors = [
    214, 39, 40;    % Red ch1
    31, 119, 180;   % Blue  ch2
    44, 160, 44;    % Green ch3
    148, 103, 189   % Purple ch 4
    ] / 255;  % Convert to MATLAB's 0-1 range

%% Waveform plotting
% Example: app.wavAvgFig1
% Data: FFT_block_avgs

% Collect axes handles for linking
wav_axes = [];

for ich = 1:Nchan
    curchan_name = channel_names{ich};
    current_axes = app.(sprintf('wavAvgFig%d', ich));
    cur_color = tableau_colors(ich,:);
    prestim = FFT_block_avgs.(curchan_name).prestim(:)';
    stimresp = FFT_block_avgs.(curchan_name).stimresp(:)';
    poststimresp = FFT_block_avgs.(curchan_name).poststimresp(:)';
    
    % Remove trailing zeros from each segment
    prestim_trimmed = prestim(1:find(prestim, 1, 'last'));
    stimresp_trimmed = stimresp(1:find(stimresp, 1, 'last'));
    poststimresp_trimmed = poststimresp(1:find(poststimresp, 1, 'last'));
    
    % Concatenate the trimmed segments
    mysig = [prestim_trimmed stimresp_trimmed poststimresp_trimmed];
    
    cla(current_axes)  % clear before plotting
    plot(current_axes, mysig, 'Color',cur_color)
    axis(current_axes, 'tight');  % Remove excess whitespace
    xlim(current_axes, [1 length(mysig)]);  % Set tight x-limits
    
    % Collect axes for linking
    wav_axes = [wav_axes, current_axes];
end

% Link only waveform axes together
if ~isempty(wav_axes) && length(wav_axes) > 1
    % Unlink each axis first
    for i = 1:length(wav_axes)
        linkaxes(wav_axes(i), 'off');
    end
    % Link them together
    linkaxes(wav_axes, 'xy');
end

%% FFTs
% Example: app.fftAvgFig1
% Data: FFT_block_FFTs

% Collect axes handles for linking
fft_axes = [];

for ich = 1:Nchan
    curchan_name = channel_names{ich};
    current_axes = app.(sprintf('fftAvgFig%d', ich));
    cur_color = tableau_colors(ich,:);
    myfft = FFT_block_FFTs.(curchan_name).stimresp.FFT;
    myfreqs = FFT_block_FFTs.(curchan_name).stimresp.frequencies;
    
    cla(current_axes)  % clear before plotting
    plot(current_axes, myfreqs, myfft,'Color',cur_color)
    set(current_axes, 'XScale', 'log');  % Use current_axes instead of gca
    grid(current_axes, 'on');
    
    axis(current_axes, 'tight');  % Remove excess whitespace
    xlim(current_axes, [min(myfreqs), max(myfreqs)]);  % Set tight x-limits
    ylim(current_axes, [min(myfft), max(myfft)]);      % Set tight y-limits
    
    % Collect axes for linking
    fft_axes = [fft_axes, current_axes];
end

% Link FFT axes
if ~isempty(fft_axes) && length(fft_axes) > 1
    % Unlink each axis first
    for i = 1:length(fft_axes)
        linkaxes(fft_axes(i), 'off');
    end
    % Link them together
    linkaxes(fft_axes, 'xy');
end

%% Trackers
curTrialInAvg = ifft*10;

% Ensure we have enough colors for all channels
if Nchan > size(tableau_colors, 1)
    error('Not enough colors defined for %d channels', Nchan);
end

%% DIAGNOSTIC: Check frequency tracker data
fprintf('\n=== FREQUENCY TRACKER DIAGNOSTICS (Trial %d) ===\n', curTrialInAvg);
for ich = 1:Nchan
    curchan_name = channel_names{ich};
    
    % Check 60 cycle data
    sixty_amp = FFT_block_FFTs.(curchan_name).stimresp.sixty_cycle.amplitude;
    fprintf('Ch%d (%s) - 60 cycle: ', ich, curchan_name);
    if isempty(sixty_amp)
        fprintf('EMPTY\n');
    elseif any(isnan(sixty_amp))
        fprintf('Contains NaN (value=%g)\n', sixty_amp);
    else
        fprintf('Value=%g\n', sixty_amp);
    end
    
    % Check stimulus freq data
    stim_amp = FFT_block_FFTs.(curchan_name).stimresp.stimulus_freq.amplitude;
    fprintf('Ch%d (%s) - Stim freq: ', ich, curchan_name);
    if isempty(stim_amp)
        fprintf('EMPTY\n');
    elseif any(isnan(stim_amp))
        fprintf('Contains NaN (value=%g)\n', stim_amp);
    else
        fprintf('Value=%g\n', stim_amp);
    end
    
    % Check double freq data
    double_amp = FFT_block_FFTs.(curchan_name).stimresp.double_freq.amplitude;
    fprintf('Ch%d (%s) - Double freq: ', ich, curchan_name);
    if isempty(double_amp)
        fprintf('EMPTY\n');
    elseif any(isnan(double_amp))
        fprintf('Contains NaN (value=%g)\n', double_amp);
    else
        fprintf('Value=%g\n', double_amp);
    end
    fprintf('\n');
end
fprintf('=============================================\n\n');

%% 60 Cycle Tracker
current_axes = app.sixtyCycleTrackFig;
hold(current_axes, 'on');

% Plot each channel individually with its assigned color
plot_handles = [];  % Store handles for legend
for ich = 1:Nchan
    curchan_name = channel_names{ich};
    amplitude = FFT_block_FFTs.(curchan_name).stimresp.sixty_cycle.amplitude;
    
    h = scatter(current_axes, curTrialInAvg, amplitude, 50, ...
        'MarkerFaceColor', tableau_colors(ich, :), ...
        'MarkerEdgeColor', tableau_colors(ich, :));
    plot_handles(ich) = h;
end

% Add legend only to 60 cycle tracker
legend(current_axes, plot_handles, channel_names, 'Location', 'best');

%% Stimulus Freq. Tracker
current_axes = app.stimFreqTrackFig;
hold(current_axes, 'on');

for ich = 1:Nchan
    curchan_name = channel_names{ich};
    amplitude = FFT_block_FFTs.(curchan_name).stimresp.stimulus_freq.amplitude;
    
    scatter(current_axes, curTrialInAvg, amplitude, 50, ...
        'MarkerFaceColor', tableau_colors(ich, :), ...
        'MarkerEdgeColor', tableau_colors(ich, :));
end

%% Double Freq. Tracker
current_axes = app.doubleFreqTrackFig;
hold(current_axes, 'on');

for ich = 1:Nchan
    curchan_name = channel_names{ich};
    amplitude = FFT_block_FFTs.(curchan_name).stimresp.double_freq.amplitude;
    
    scatter(current_axes, curTrialInAvg, amplitude, 50, ...
        'MarkerFaceColor', tableau_colors(ich, :), ...
        'MarkerEdgeColor', tableau_colors(ich, :));
end

%% P Vals
% Example: app.pValTracker
% Data: FFT_block_TTest

% Ensure p-value axes are independent (unlink from any existing groups)
for ich = 1:Nchan
    pval_axes = app.(sprintf('pValTrackerFig%d', ich));
    linkaxes(pval_axes, 'off');  % Unlink this axes from any groups
end

for ich = 1:Nchan
    curchan_name = channel_names{ich};
    current_axes = app.(sprintf('pValTrackerFig%d', ich));
    myp = FFT_block_TTest.(curchan_name).p;
    mycrit = FFT_block_TTest.(curchan_name).crit;
    
    % Append new data points
    gui_channel_data.pval_x_data{ich} = [gui_channel_data.pval_x_data{ich}, curTrialInAvg];
    gui_channel_data.pval_y_data{ich} = [gui_channel_data.pval_y_data{ich}, myp];
    gui_channel_data.crit_x_data{ich} = [gui_channel_data.crit_x_data{ich}, curTrialInAvg];
    gui_channel_data.crit_y_data{ich} = [gui_channel_data.crit_y_data{ich}, mycrit];
    
    % Clear and replot entire series
    cla(current_axes);
    hold(current_axes, 'on');
    
    % Handle criterion line - single vs multiple points
    if length(gui_channel_data.crit_x_data{ich}) == 1
        % For single criterion point, use a marker
        scatter(current_axes, gui_channel_data.crit_x_data{ich}, gui_channel_data.crit_y_data{ich}, 20, [0.7, 0.7, 0.7], 'filled', 'Marker', 'd');
    else
        % For multiple points, use dashed line
        plot(current_axes, gui_channel_data.crit_x_data{ich}, gui_channel_data.crit_y_data{ich}, '--', 'Color',[0.7, 0.7, 0.7], 'LineWidth', 1);
    end
    
    % Handle p-values - single vs multiple points
    if length(gui_channel_data.pval_x_data{ich}) == 1
        % For single points, use scatter/markers only
        if myp > mycrit
            scatter(current_axes, gui_channel_data.pval_x_data{ich}, gui_channel_data.pval_y_data{ich}, 20, 'r', 'filled', 'Marker', 'o');
        else
            scatter(current_axes, gui_channel_data.pval_x_data{ich}, gui_channel_data.pval_y_data{ich}, 20, 'g', 'filled', 'Marker', 'o');
        end
    else
        % For multiple points, use line + markers
        if myp > mycrit
            plot(current_axes, gui_channel_data.pval_x_data{ich}, gui_channel_data.pval_y_data{ich}, 'r-o', 'LineWidth', 1, 'MarkerSize', 3, 'MarkerFaceColor', 'r');
        else
            plot(current_axes, gui_channel_data.pval_x_data{ich}, gui_channel_data.pval_y_data{ich}, 'g-o', 'LineWidth', 1, 'MarkerSize', 3, 'MarkerFaceColor', 'g');
        end
    end
    
    % Set reasonable axis limits for visibility
    set(current_axes,'YScale','log')
    
    % Check for empty data to avoid errors
    if ~isempty(gui_channel_data.pval_x_data{ich}) && ~isempty(gui_channel_data.pval_y_data{ich})
        x_data = gui_channel_data.pval_x_data{ich};
        y_data = [gui_channel_data.pval_y_data{ich}, gui_channel_data.crit_y_data{ich}];
        
        % Set x-axis limits
        xlim(current_axes, [min(x_data)-5, max(x_data)+5]);
        
        % Set y-axis limits for log scale (avoid 0 as lower limit)
        y_min = min(y_data(y_data > 0));  % Find smallest positive value
        y_max = max(y_data);
        
        if ~isempty(y_min) && ~isempty(y_max) && y_min > 0
            ylim(current_axes, [y_min*0.5, y_max*1.2]);
        else
            % Fallback limits if data is problematic
            ylim(current_axes, [1e-6, 1]);
        end
    end
    
end
end