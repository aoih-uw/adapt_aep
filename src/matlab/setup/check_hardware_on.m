function check_hardware_on
% A GUI to ensure that all necessary hardware used in experiment are turned
% on and using the correct settings

beep;
f = figure('Position', [300 300 400 240], 'MenuBar', 'none', 'Name', 'Equipment Check', 'NumberTitle', 'off');

% Add caution symbol using text
uicontrol('Style', 'text', 'Position', [20 210 360 25], 'String', '⚠ CAUTION: Check all items before proceeding:', 'FontWeight', 'bold', 'ForegroundColor', [0.8 0.4 0], 'FontSize', 12);
uicontrol('Style', 'text', 'Position', [20 185 360 20], 'String', 'Verify equipment status:', 'FontSize', 10);

checks = zeros(5,1);
cb1 = uicontrol('Style', 'checkbox', 'Position', [20 160 360 20], 'String', 'Hydrophone amplifier is ON and set to 100 mV/Pa', 'Callback', @(~,~) setCheck(1));
cb2 = uicontrol('Style', 'checkbox', 'Position', [20 135 360 20], 'String', 'Speaker amplifier is ON', 'Callback', @(~,~) setCheck(2));
cb3 = uicontrol('Style', 'checkbox', 'Position', [20 110 360 20], 'String', 'Oscilloscope is ON', 'Callback', @(~,~) setCheck(3));
cb4 = uicontrol('Style', 'checkbox', 'Position', [20 85 360 20], 'String', 'Bioamplifier lights are ON and gain is at 10,000x', 'Callback', @(~,~) setCheck(4));
cb5 = uicontrol('Style', 'checkbox', 'Position', [20 60 360 20], 'String', 'Water pump system is ON', 'Callback', @(~,~) setCheck(5));

okBtn = uicontrol('Style', 'pushbutton', 'Position', [160 20 80 30], 'String', 'OK', 'Enable', 'off', 'Callback', @(~,~) close(f));

    function setCheck(n)
        checks(n) = ~checks(n);
        if all(checks)
            set(okBtn, 'Enable', 'on');
        else
            set(okBtn, 'Enable', 'off');
        end
    end

uiwait(f);
end