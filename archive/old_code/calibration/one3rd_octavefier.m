function [freqset, durs, ISI]  = one3rd_octavefier(freqset)
%Create a set of frequencies that are separated by 1/3 octave and rounded
%to the nearest 5

% Calculate durations and Inter Stimulus Interval
durs = [];

for ifreq = 1:length(freqset)
    durs(ifreq) = 400; % convert to milliseconds
end
