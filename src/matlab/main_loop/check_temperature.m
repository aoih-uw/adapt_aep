function ex = check_temperature(ex)
iblock = ex.counter.iblock;
target_temp = ex.info.experiment.target_water_temp_C;
tolerance = ex.info.experiment.water_temp_tol_C;

temp_C = read_thermometer();
ex.block(iblock).water_temp_C = temp_C;

while temp_C > target_temp+tolerance || temp_C < target_temp - tolerance
    water_temp_warning(temp_C, target_temp);
    temp_C = read_thermometer();
    ex.block(iblock).water_temp_C = temp_C;
end
end

function water_temp_warning(temp_C, target_temp)
% Warning popup for out-of-range water temperature
% Create dialog
d = dialog('Position', [400 400 450 200], 'Name', 'Temperature Warning', 'Color', 'w');
% Warning text
uicontrol('Parent', d, 'Style', 'text', 'Position', [20 100 410 80], ...
    'String', sprintf(['Water temperature is %.1f°C and is out of range.\n\n' ...
    'Ensure tank temperature has been restored to %.1f°C\n' ...
    'before proceeding.'], temp_C, target_temp), ...
    'FontSize', 11, 'BackgroundColor', 'w', 'ForegroundColor', 'k', ...
    'HorizontalAlignment', 'center');
% Continue button
uicontrol('Parent', d, 'Position', [150 30 150 40], ...
    'String', 'Check Again', 'FontSize', 12, ...
    'BackgroundColor', [0.94 0.94 0.94], 'ForegroundColor', 'k', ...
    'Callback', @(~,~) delete(d));
% Wait for user to press continue
uiwait(d);
end
