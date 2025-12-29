function ex = init_dac(ex)
% Initialize the Fireface Audio Interface (used here primarily as a D/A converter)

fs = ex.info.recording.sampling_rate_hz;
% Reset playrec if it is already initialized to start fresh
if playrec('isInitialised')
    playrec('reset');
end

% Get a list of connected devices
my_devices = playrec('getDevices');
if length(my_devices) > 1
    my_devices(2:end) = []; % remove all other devices
end

% Check to make sure that Fireface is online
if ~strcmp(my_devices.name, 'ASIO Fireface USB') % check that this is the only device initizlised
    if ~strfind(my_devices.name, 'Fireface')
        errordlg('The Fireface is not recognized. Is it plugged in? Is it on?');
        error('The Fireface is not recognized. Check to make sure that it is plugged in and turned on');
    end
    if ~strfind(my_devices.name, 'ASIO')
        errordlg('The Fireface is recognized, but it appears an older version of PlayRec was called.');
        error('The Fireface is recognized, but it appears an older version of PlayRec was called.');
    end
end

% Initialize!
playrec('init', fs, 0, 0, 8, 8);