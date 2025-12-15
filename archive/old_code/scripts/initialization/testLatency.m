function [mythresh_samp,mylatency_samp] = testLatency(fs)
% Calculate system latency using the loopback system to know how long it
% takes for the stimulus to get sent out to the DAC and recieve the signal
% back from the DAC

% Generate 1V pulse to get output/rec delay.
    testsig = [zeros(1, fs) 1 1 1 -1 -1 -1 zeros(1, fs)]';
    testpage = playrec('playrec', testsig, 4, -1, 4);
    playrec('block', testpage);
    testrec = double(playrec('getRec', testpage));
    playrec('delPage', testpage);
    mythresh_samp = find(abs(testrec(:, 1) > 0.05), 1, 'first');
    mythresh_samp = mythresh_samp - fs;
    mylatency_samp = ceil(mythresh_samp);