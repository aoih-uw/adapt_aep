function ex = init_dac(ex)
%% Initialize the Fireface Audio Interface (used here primarily as a D/A converter)

fs = ex.info.recording.sampling_rate_hz;
% Reset playrec if it is already initialized to start fresh
if playrec('isInitialised')
    playrec('reset');
end

% Get a list of connected devices
my_devices = playrec('getDevices');

% Find the index of the Fireface device
idx = find(strcmp({my_devices.name}, 'ASIO Fireface USB'));
if isempty(idx)
    error('ASIO Fireface USB not found');
else 
    my_devices = my_devices(idx); % remove all other devices
end

% Initialize!
playrec('init', fs, my_devices.deviceID, my_devices.deviceID, 8, 8);