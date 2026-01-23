fucntion ex = init_audio(ex)

% Audio hardware
fprintf('Initializing audio hardware...\n');
playrec('init',fs,0,0,8,8);

% Allow time for audio hardware to fully initialize
pause(2);

% Test audio path with a brief silent signal to ensure readiness
test_signal = zeros(1, round(fs * 0.1)); % 100ms of silence
test_page = playrec('playrec', test_signal', 1, -1, 3);
playrec('block', test_page);
playrec('delPage', test_page);
fprintf('Audio hardware ready.\n');