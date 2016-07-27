% Command list: 
% turtleBot('openSerial') - open turtlebot serial port 
% turtleBot('setSpeed', trans, rot) - set translational and rotational speed 
% pos = turtleBot('getPosition') - get turtleBot position, return value is [x; y; angle]
% turtleBot('goTo', pos) - go to target position
% turtleBot('bye') - close serial and kill all threads

% compile
% mex turtleBot.cpp

% To get connected to the turtleBot, we need to open the serial port
turtleBot('openSerial');

% To simply set speed
% unit: translational speed - m/s, rotational speed - rad/s
turtleBot('setSpeed', trans, rot);

% To obtain the current position
pos = turtleBot('getPosition');
disp(pos);

% Go to a target position, pos = [x y angle heading].
% unit: x - mm y - mm angle - deg heading - TOWARD 0; BACKWARD 1
turtleBot('goTo', pos);

% IMPORTANT: remember to shutdown after finishing everything!
turtleBot('bye');

