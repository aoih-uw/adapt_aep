function temp_C = read_thermometer()
persistent s
% Open serialport if needed
if isempty(s)
    s = serialport("COM5", 9600);   % first call: open port, wait for Arduino to reboot
    pause(2);
end
writeline(s, "T");
temp_C = str2double(readline(s));

% Check if NaN
if isnan(temp_C)
    keyboard
end