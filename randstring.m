function str = randstring(Nchar)
% return a random string using A-Z for N charaters
% like the naming of SUN database

str = char(65+fix(26*rand(1,Nchar)));