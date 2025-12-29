function ex = load_stim_calibration(ex)

% Initialize calibration_data if not already loaded
if isempty(calibration_data)
    try
        % Try to load existing calibration data
        load('calibration_data.mat', 'calibration_data');
        fprintf('Loaded existing calibration data.\n');
    catch
        % If no calibration file exists, prompt user or use defaults
        error('No calibration data found');
    end
end