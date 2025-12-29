function ex = setup()
ex = setup_ex(); % Initialize data structure
ex = make_tone_burst(ex); % Create sound stimulus template

% Load stimulus calibration variables
if isempty(ex.info.stimulus.calibration)
    try
        % Load existing calibration data
        load('calibration_data.mat', 'calibration_data'); %# edit this later...
        fprintf('Loaded existing calibration data.\n');
        ex.info.stimulus.calibration = calibration_data;
    catch
        error('No calibration data found');
    end
end

ex = init_hardware(ex); % Initialization
