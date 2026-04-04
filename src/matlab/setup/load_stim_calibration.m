function ex = load_stim_calibration(ex)

% Initialize calibration_data if not already loaded
if isempty(ex.calibration)
    try
        % Build the calibration directory path
        filename_root = ex.info.animal.filename_root;
        [~, filename_root] = fileparts(filename_root);
        cal_dir = fullfile('..', '..', 'data', 'calibration');
        
        % Find matching calibration files for this animal
        pattern = fullfile(cal_dir, strcat(filename_root, '_calibration_*.mat'));
        files = dir(pattern);
        
        if isempty(files)
            error('No calibration data found for animal: %s', filename_root);
        end
        
        % Load the most recent calibration file
        [~, idx] = max([files.datenum]);
        filepath = fullfile(cal_dir, files(idx).name);
        
        load(filepath, 'calibration');
        ex.info.calibration = calibration;
        fprintf('\nLoaded calibration file: %s\n', files(idx).name);
        
    catch ME
        error('No calibration data found: %s', ME.message);
    end
end