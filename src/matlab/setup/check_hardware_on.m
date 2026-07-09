function check_hardware_on
% A GUI to ensure that all necessary hardware used in experiment are turned
% on and using the correct settings
[y, Fs] = audioread('button_press.mp3');
sound(y, Fs)

% --- Style constants (match adapt_aep app) ---
bg      = [0.8824 0.9294 0.9686];
navy    = [0.1686 0.2196 0.5608];
btnBg   = [0.9412 0.9412 0.9412];
btnFg   = [0 0 0];
warnRed = [0.85 0.2 0.2];
pad     = 25;
dlgW = 460; dlgH = 600;
btnW = 240; btnH = 40;
cbH  = 22; cbGap = 6;

% Grouped checklist
groups = { ...
    'Audio',        {'Hydrophone amp ON @ 3.16 mV/Pa', 'Speaker amp ON', 'Oscilloscope ON and signal stable'}; ...
    'Recording',    {'Bioamp ON, gain 10,000x and filter settings match protocol'}; ...
    'Tank & table', {'Water pump ON (Current 0.2, Voltage 5.0)', 'Nitrogen ON, table floating','Hydrophone is unobstructed'}; ...
    'Temperature',  {'Temp within 1° of initial', 'Ice bag in tank removed', Set timer to remind noting temp every 15 minutes'}; ...
    'Test subject', {'Electrodes are secure','Head is centered in tank','Body is in a neutral horizontal position'}};
    
for g = 1:size(groups,1)
    groups{g,2} = groups{g,2}(randperm(numel(groups{g,2})));
end
nItems = sum(cellfun(@numel, groups(:,2)));
checks = zeros(nItems, 1);
allCheckedBefore = false;
completed = false;

% Create dialog
d = dialog('Position', [400 200 dlgW dlgH], ...
    'Name', 'Equipment Check', ...
    'Color', bg);

% Warning title
uicontrol('Parent', d, 'Style', 'text', ...
    'Position', [pad dlgH-55 dlgW-2*pad 35], ...
    'String', [char(9888) '  Equipment Check'], ...
    'FontName', 'Space Grotesk', 'FontSize', 16, 'FontWeight', 'bold', ...
    'ForegroundColor', warnRed, 'BackgroundColor', bg, ...
    'HorizontalAlignment', 'center');

% Subtitle
uicontrol('Parent', d, 'Style', 'text', ...
    'Position', [pad dlgH-85 dlgW-2*pad 22], ...
    'String', 'Verify all equipment before proceeding:', ...
    'FontName', 'Inter', 'FontSize', 12, ...
    'ForegroundColor', [0 0 0], 'BackgroundColor', bg, ...
    'HorizontalAlignment', 'center');

% Checkboxes with group headers
cbTop = dlgH - 115;
cb = gobjects(nItems, 1);
yPos = cbTop; idx = 0;
for g = 1:size(groups,1)
    uicontrol('Parent', d, 'Style', 'text', ...
        'Position', [pad yPos-2 dlgW-2*pad 20], ...
        'String', upper(groups{g,1}), ...
        'FontName', 'Space Grotesk', 'FontSize', 10, 'FontWeight', 'bold', ...
        'ForegroundColor', navy, 'BackgroundColor', bg, ...
        'HorizontalAlignment', 'left');
    yPos = yPos - 22;
    for j = 1:numel(groups{g,2})
        idx = idx + 1;
        cb(idx) = uicontrol('Parent', d, 'Style', 'checkbox', ...
            'Position', [pad+20 yPos dlgW-2*pad-20 cbH], ...
            'String', groups{g,2}{j}, 'FontName', 'Inter', 'FontSize', 11, ...
            'ForegroundColor', [0 0 0], 'BackgroundColor', bg, ...
            'Callback', @(~,~) update_checks());
        yPos = yPos - (cbH + cbGap);
    end
    yPos = yPos - 8;
end

% Progress label
pbY = 85;
pbH = 18;
progressLabel = uicontrol('Parent', d, 'Style', 'text', ...
    'Position', [pad pbY+pbH+2 dlgW-2*pad 18], ...
    'String', sprintf('Pre-experiment check:  0 / %d', nItems), ...
    'FontName', 'Inter', 'FontSize', 11, 'FontWeight', 'bold', ...
    'ForegroundColor', navy, 'BackgroundColor', bg, ...
    'HorizontalAlignment', 'center');

% Progress bar
progressAx = axes('Parent', d, 'Units', 'pixels', ...
    'Position', [pad pbY dlgW-2*pad pbH], ...
    'XLim', [0 1], 'YLim', [0 1], ...
    'XTick', [], 'YTick', [], ...
    'Box', 'on', 'Color', [0.85 0.88 0.92], ...
    'XColor', navy, 'YColor', navy);
progressBar = patch(progressAx, [0 0 0 0], [0 0 1 1], navy, 'EdgeColor', 'none');

% Ready button
okBtn = uicontrol('Parent', d, ...
    'Position', [(dlgW-btnW)/2 pad btnW btnH], ...
    'String', 'Rip it', 'FontName', 'Inter', 'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', btnBg, 'ForegroundColor', btnFg, ...
    'Enable', 'off', ...
    'Callback', @(~,~) finish_ok());

uiwait(d);

if ~completed
    error('check_hardware_on:incomplete', ...
        'Equipment check was closed before all items were verified.');
end

    function update_checks()
        for k = 1:nItems
            checks(k) = get(cb(k), 'Value');
        end
        nChecked = sum(checks);
        frac = nChecked / nItems;

        set(progressBar, 'XData', [0 frac frac 0]);
        set(progressLabel, 'String', ...
            sprintf('Pre-experiment check:  %d / %d', nChecked, nItems));

        if all(checks)
            set(okBtn, 'Enable', 'on');
            if ~allCheckedBefore
                this_dir   = fileparts(mfilename('fullpath'));
                sound_file = fullfile(this_dir, '..', 'sound_effects', 'step.mp3');
                [yc, Fsc]  = audioread(sound_file);
                sound(yc, Fsc);
                allCheckedBefore = true;
            end
        else
            set(okBtn, 'Enable', 'off');
            allCheckedBefore = false;
        end
    end

    function finish_ok()
        completed = true;
        delete(d);
    end

end
