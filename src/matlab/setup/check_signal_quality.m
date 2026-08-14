function check_signal_quality
% A GUI to ensure hydrophone signal quality and 2f magnitudes are
% acceptable before proceeding

% --- Style constants (match adapt_aep app) ---
bg      = [0.8824 0.9294 0.9686];
navy    = [0.1686 0.2196 0.5608];
btnBg   = [0.9412 0.9412 0.9412];
btnFg   = [0 0 0];
warnRed = [0.85 0.2 0.2];
pad     = 25;
btnW = 240; btnH = 40;
cbGap = 10;
rightW = 340;
imgH = 320*1.6;
bottomReserved = 50; % space reserved at bottom for progress bar + button

this_dir = fileparts(mfilename('fullpath'));
img = imread(fullfile(this_dir, 'good_signals_example.png'));
[imgPxH, imgPxW, ~] = size(img);
imgW = imgH * imgPxW / imgPxH; % width that matches imgH at the image's real aspect ratio

dlgW = pad + imgW + cbGap + rightW + pad;
dlgH = 800;

items = { ...
    {'Hydrophone signal is stable/clean'}; ...
    {'Electrode signals are stable/clean'}; ...
{'Tank noise floor is ~105 dB'}; ...
    {'Are 2f magnitudes within expected ranges?', ...
     '   CH2: 1-5 (2mm)', ...
     '   CH3: 10+ (4mm)', ...
     '   CH4: Below 1 (skin)'}};

nItems = numel(items);
checks = zeros(nItems, 1);
allCheckedBefore = false;
completed = false;

% Create dialog
d = dialog('Position', [300 75 dlgW dlgH], ...
    'Name', 'Signal Quality Check', ...
    'Color', bg);

% Warning title
uicontrol('Parent', d, 'Style', 'text', ...
    'Position', [pad dlgH-55 dlgW-2*pad 35], ...
    'String', [char(9888) '  Verify signal quality before proceeding:'], ...
    'FontName', 'Space Grotesk', 'FontSize', 16, 'FontWeight', 'bold', ...
    'ForegroundColor', warnRed, 'BackgroundColor', bg, ...
    'HorizontalAlignment', 'center');

% Example image of good signals (left column)
contentTop = dlgH - 75;
titleH = 24;
imgTop = contentTop - titleH - imgH;
assert(imgTop > bottomReserved, 'Image too tall for dialog; increase dlgH or shrink imgH.');
uicontrol('Parent', d, 'Style', 'text', ...
    'Position', [pad contentTop-titleH imgW titleH], ...
    'String', 'Example ideal signals', ...
    'FontName', 'Inter', 'FontSize', 12, 'FontWeight', 'bold', ...
    'ForegroundColor', navy, 'BackgroundColor', bg, ...
    'HorizontalAlignment', 'center');
imgAx = axes('Parent', d, 'Units', 'pixels', ...
    'Position', [pad imgTop imgW imgH]);
imshow(img, 'Parent', imgAx);

% Checkboxes (right column)
rightX = pad + imgW + cbGap;
cb = gobjects(nItems, 1);
iconW = 20; % space taken by the checkbox tick-icon, not available for text
yPos = contentTop-150;
for k = 1:nItems
    tmp = uicontrol('Parent', d, 'Style', 'text', 'Visible', 'off', ...
        'Position', [0 0 rightW-iconW 22], 'FontName', 'Inter', 'FontSize', 11);
    wrapped = textwrap(tmp, items{k});
    delete(tmp);
    cbH = 22 * numel(wrapped);
    yPos = yPos - cbH;
    cb(k) = uicontrol('Parent', d, 'Style', 'checkbox', ...
        'Position', [rightX yPos rightW cbH], ...
        'String', wrapped, 'FontName', 'Inter', 'FontSize', 11, ...
        'ForegroundColor', [0 0 0], 'BackgroundColor', bg, ...
        'HorizontalAlignment', 'left', ...
        'Callback', @(~,~) update_checks());
    yPos = yPos - cbGap;
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
    error('check_signal_quality:incomplete', ...
        'Signal quality check was closed before all items were verified.');
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