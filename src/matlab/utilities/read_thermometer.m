function temp_C = read_thermometer(port)
persistent s
if isempty(s)
    s = serialport(port, 9600);
    pause(2);
end
writeline(s, "T");
temp_C = str2double(readline(s));

% Check if NaN
if isnan(temp_C)
    keyboard
end