function ex = test_latency(ex)
% Calculate system latency using loopback system to know how long it takes
% for stimulus to get sent ot to the DAC and receive the signal back from the DAC
% playrec(command, output signal, 4 output channels, -1 record same number of samples in output signal, 4 input channels)
% playrec('playrec') returns pageNumber, which you need to get by using 'getRec'

fs = ex.info.recording.sampling_rate_hz;

% Generage a 1V pulse to get detlay
test_signal = [zeros(1, fs) 1 1 1 -1 -1 -1 zeros(1, fs)]';

test_page = playrec('playrec',test_signal, 4, -1, 4);
playrec('block',test_page) % blocks all other functionality until recording is done
test_rec = double(playrec('getRec'),test_page); % Retrieve recorded data and convert into double precision
playrec('delPage',test_page); % delete data to free memory

my_threshold_sample = find(abs(test_rec(:,1)) > 0.05, 1, 'first'); % find the first sample in channel 1 where absolute value exceeds 0.05 V

% Error check: verify pulse was detected
if isempty(my_threshold_sample)
    error('No signal detected. Check loopback connection.');
end

my_threshold_sample = my_threshold_sample - fs; % Remove that initial 1 second offest that was added to the signal

% Verify latency is positive
if my_threshold_sample <= 0
    error('Invalid latency detected.');
end

my_latency_sample = ceil(my_threshold_sample);

% Display results to command window
fprintf('\nLatency in samples: %d\nLatency in seconds: %.4f\n', my_latency_sample, my_latency_sample/fs);

ex.info.recording.latency_samples = my_latency_sample;