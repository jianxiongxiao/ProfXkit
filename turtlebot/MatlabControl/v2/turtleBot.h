#ifndef SERIAL_COMM_H
#define SERIAL_COMM_H

#include <pthread.h>
#include <stdint.h>
#include <string>
#include <stdlib.h>

using namespace std;

//for turtlebot
#define HEADER0             0xAA
#define HEADER1             0x55
#define CMD                 0x01
#define SENSOR_ID           0x01
#define LENGTH_PACKED       0x0F
#define MAX_RX_LOAD         128
#define MAX_TX_LOAD         10
#define PACKETS_TO_DISCARD  5

#define LEFT_WHEEL          0
#define RIGHT_WHEEL         1

#define TOWARD              0
#define BACKWARD            1


#define WHEEL_SCALE         0.08529209049         // 2 * PI * 35mm / (2 * pi / 0.002436916871363930187454f)
                                                  // = 35mm * 0.002436916871363930187454f
#define ROBOT_RADIUS        115.0
// bias(0.23), // wheelbase, wheel_to_wheel, in [m]
// wheel_radius(0.035), // radius of main wheel, in [m]

#define PI                  M_PI


//control paramas
#define ROTATION_P          0.2
#define TRANSLATION_P       0.08
#define CORRECTION_P        0.2//0.2

#define MAX_ROT_SPEED       0.5 //  m/s
#define MAX_TRANS_SPEED     0.1 //  rad/s
#define MAX_CORR_SPEED      0.1//0.1 //

#define ANGLE_TH            2.0
#define POS_TH              3.0


enum packetFinderState{
  waitForHeader,
  waitForPayloadSize,
  waitForPayload
};

enum controlState{
  rotatingToTargetPos,
  goingStraight,
  rotatingToTargetAngle
};



typedef struct sensorsInfo {
  uint16_t time_stamp;
  uint8_t bumper;
  uint8_t wheel_drop;
  uint8_t cliff;
  uint16_t left_encoder;
  uint16_t right_encoder;
  char left_pwm;
  char right_pwm;
  uint8_t buttons;
  uint8_t charger;
  uint8_t battery;
  uint8_t over_current;
  bool used;
} sensorsInfo;

typedef struct robotPosition {
  double x;
  double y;
  double angle; //right hand rule, in radians
  double angle_degree;
} robotPosition;

typedef struct goToParams{
  double x;
  double y;
  double angle_degree;
  bool heading;
  double path_orientation;
  double translational_speed;
  double rotational_speed;
} goToParams;


class turtleBot{
public:
turtleBot();
~turtleBot();

// /dev/tty.usbmodem1451
// /dev/tty.HC-06-DevB
// /dev/tty.usbserial-kobuki_A901PEWI
bool initSerial(string port);
bool closeSerial();
bool checkSerial();
void updateSensors();  // need to be continuously called, consider threading
bool getButtonStatus(int index);
bool zigzagToTarget(goToParams* target);
bool rotateToTargetAngle(double target);

double getWheelSpeed(bool wheel);
void updatePosition();
robotPosition* getPosition();
void resetPosition();
void setTargetPosition(goToParams* params);
void closedLoopUpdate();
void setSpeedBasic(short speed, short radius);
void setSpeed(const double &vx, const double &wz);
sensorsInfo* info;

pthread_mutex_t mutex;
pthread_mutex_t thread_enabled_mutex;
bool thread_enabled;

private:
int port_fd;
sensorsInfo* prev_info;
robotPosition* position;
goToParams* goto_params;
unsigned char* rx_packet;
unsigned char* tx_packet;
int discarded_packets;
bool goto_enabled;


unsigned char readByte();
bool detectHeader(const unsigned char incoming);
void fetchPacket(const unsigned char incoming);
bool deserializePacket(unsigned char* data);

};

#endif
