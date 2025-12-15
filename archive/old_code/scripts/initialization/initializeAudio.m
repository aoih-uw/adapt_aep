function audioInitSuccess = initializeAudio(fs)
audioInitSuccess = 0;

if playrec('isInitialised')
    playrec('reset');
end

mydevs = playrec('getDevices');
if length(mydevs) > 1
    mydevs(2:end) = [];
end

% Check to make sure that Fireface is online
if ~strcmp(mydevs.name, 'ASIO Fireface USB')
    if ~strfind(mydevs.name, 'Fireface')
        errordlg('The Fireface is not recognized. Is it plugged in? Is it on?');
        error('The Fireface is not recognized. Check to make sure that it is plugged in and turned on');
    end
    if ~strfind(mydevs.name, 'ASIO')
        errordlg('The Fireface is recognized, but it appears an older version of PlayRec was called.');
        error('The Fireface is recognized, but it appears an older version of PlayRec was called.');
    end
end

playrec('init', fs, 0, 0, 8, 8);
audioInitSuccess = 1;