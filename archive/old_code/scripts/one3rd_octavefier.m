function [freqset, durs, ISI]  = one3rd_octavefier(minfreq,maxfreq)
%Create a set of frequencies that are separated by 1/3 octave and rounded
%to the nearest 5

numcycle = 1;
freqset = minfreq;

while freqset(end) < maxfreq
    freqset = [freqset; ceil(freqset(end)+(freqset(end)/3))];
end

if freqset(end) > maxfreq
    freqset= freqset(1:end-1);
end
db = 1;

% Round up or down to 5 or 10 which ever is closest
for ifreq = 1:length(freqset)
    tmp = freqset(ifreq);
    tmp5 = round(tmp/5)*5;
    tmp10 = round(tmp/10)*10;
    
    if abs(tmp-tmp5) > abs(tmp-tmp10)
        tmp = tmp10;
    else
        tmp = tmp5;
    end
    
    freqset(ifreq) = tmp;
end

% Calculate durations and Inter Stimulus Interval
durs = [];

for ifreq = 1:length(freqset)
    durs(ifreq) = (numcycle*(1/freqset(ifreq)))*1000; % convert to milliseconds
end

ISI = 650;