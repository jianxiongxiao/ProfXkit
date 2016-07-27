#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
//#include <stdio.h>
//#include <stdlib.h>
#include <ncurses.h>
#include <string.h>
#include "mex.h"

#define TURTLEBOT

#define START_BYTE          0xAA
#define END_BYTE            0xBB

//for turtlebot
#define HEADER0             0xAA
#define HEADER1             0x55
#define CMD                 0x01

int port_fd;

#ifndef TURTLEBOT
unsigned char packet[4] = {(unsigned char)START_BYTE, 0, 0, (unsigned char)END_BYTE};
#else
unsigned char packet[10] = {(unsigned char)HEADER0, (unsigned char)HEADER1,
  (unsigned char)0x06, (unsigned char)CMD, (unsigned char)0x04,
  0, 0, 0, 0, 0};
#endif


#ifndef TURTLEBOT
void set_speed(int translational_speed, int rotational_speed){
  if(translational_speed >= 0){
    packet[1] = (unsigned char)translational_speed;
  }else{
    packet[1] = (unsigned char)(-translational_speed);
    packet[1] = packet[1] | 0b10000000;
  }

  if(rotational_speed >= 0){
    packet[2] = (unsigned char)rotational_speed;
  }else{
    packet[2] = (unsigned char)(-rotational_speed);
    packet[2] = packet[2] | 0b10000000;
  }
  write(port_fd, packet, 4);
}

#else

void set_speed(short speed, short radius){
  unsigned char checksum = 0;
  packet[5] = (unsigned char)(speed & 0x00FF);
  packet[6] = (unsigned char)(speed >> 8);
  packet[7] = (unsigned char)(radius & 0x00FF);
  packet[8] = (unsigned char)(radius >> 8);
  for (int i = 2; i < 9; i++){
    checksum ^= packet[i];
  }
  packet[9] = checksum;
  write(port_fd, packet, 10);
}
#endif


int init_serial_input (char* port) {
  int fd = 0;
  struct termios options;

  fd = open(port, O_RDWR | O_NOCTTY | O_NDELAY);
  if (fd == -1)
    return fd;
  fcntl(fd, F_SETFL, 0);    // clear all flags on descriptor, enable direct I/O
  tcgetattr(fd, &options);   // read serial port options
  //set baud rate
  #ifndef TURTLEBOT
  cfsetispeed(&options, B9600);
  cfsetospeed(&options, B9600);
  #else
  //!!!! PAY ATTENTION !!!!
  cfsetispeed(&options, B115200);
  cfsetospeed(&options, B115200);
  #endif
  options.c_cflag |= (CLOCAL | CREAD);
  options.c_cflag &= ~PARENB;
  options.c_cflag &= ~CSTOPB;
  options.c_cflag &= ~CSIZE;
  options.c_cflag |= CS8;
  tcsetattr(fd, TCSANOW, &options);
  return fd;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  char* cmd = mxArrayToString(prhs[0]);
  if (!strcmp(cmd, "open") && nrhs == 2){
    char* port = mxArrayToString(prhs[1]);
    if (port_fd <= 0){
      port_fd = init_serial_input (port);
      // port_fd = 100;
    }else{
      mexPrintf("port already opened!\n");
    }
    mexPrintf("port opened: %d \n", port_fd);
  } else if (!strcmp(cmd, "set_speed") && nrhs == 3){
    double* arg1 = (double*) mxGetData(prhs[1]);
    double* arg2 = (double*) mxGetData(prhs[2]);
    if (port_fd <= 0){
      mexPrintf("Serial port not initialized \n");
    }else{
      mexPrintf("set speed: %d, %d \n", (short)arg1[0], (short)arg2[0]);
      set_speed((short)arg1[0], (short)arg2[0]);
    }
  }

  return;
}
