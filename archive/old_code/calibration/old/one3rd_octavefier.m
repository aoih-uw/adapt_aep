function [freqset, durs, ISI]  = one3rd_octavefier(minfreq,maxfreq)
%Create a set of frequencies that are separated by 1/3 octave and rounded
%to the nearest 5

octave_ratio = 2^(1/3); % Divide an octave (2f) into 3 equal parts (1/3) Take the cube root of 2 to know by what percentage the next freq is higher than the previous one
num_steps = floor(log(maxfreq / minfreq) / log(octave_ratio));

% Generate frequency array
frequencies = zeros(1, num_steps + 1);
for i = 0:num_steps
    frequencies(i + 1) = round(minfreq * (octave_ratio ^ i));
end

freqset = frequencies;

% Calculate durations and Inter Stimulus Interval
durs = [];

for ifreq = 1:length(freqset)
    durs(ifreq) = 400; % convert to milliseconds
end

ISI = 650;