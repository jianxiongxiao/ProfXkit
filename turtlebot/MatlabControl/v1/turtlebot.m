% Code to control TurtleBot2 wheels using Matlab
% Written by Linguang Zhang

% compile
if exist(['serial_comm.' mexext], 'file') ~= 3
    mex serial_comm.c
end

% initialize
% /dev/tty.usbmodem1451
% /dev/tty.HC-06-DevB
% /dev/tty.usbserial-kobuki_A901PEWI
serial_comm('open', '/dev/tty.usbserial-kobuki_A901PEWI');

% set speed
serial_comm('set_speed', 100, 0)