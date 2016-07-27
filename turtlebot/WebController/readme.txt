Written by Linguang Zhang. Commands to compile and run:

cd libwebsockets-1.3-chrome37-firefox30/
mkdir build
cd build
cmake ..
make install
cd ../..
cc -o server serial_comm.c control.c -lwebsockets
./server

