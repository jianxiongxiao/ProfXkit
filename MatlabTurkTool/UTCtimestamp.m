function result = UTCtimestamp()


time_unix = java.lang.System.currentTimeMillis;

% http://stackoverflow.com/questions/12661862/converting-epoch-to-date-in-matlab

time_reference = datenum('1970', 'yyyy'); 
time_matlab = time_reference + time_unix / 8.64e7;
result = datestr(time_matlab, 'yyyy-mm-ddTHH:MM:SSZ');

