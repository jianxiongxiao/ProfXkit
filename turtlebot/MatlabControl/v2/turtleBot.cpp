#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
// #include <stdio.h>
#include <ncurses.h>
#include <string.h>
#include <stdint.h>

#include "turtleBot.h"
#include "math.h"
#include "limits.h"

#define COMPILE_MEX

#ifdef COMPILE_MEX
#include "mex.h"
#endif

pthread_t feedback_thread;
pthread_t control_thread;
turtleBot* robot = NULL;

//Helper function

// template<T>
// T reconstructVariable(uint8_t* data){
//
//
// }

uint16_t reconstruct_uint16(uint8_t* data){
  uint16_t var;
  var = data[0];
  var |= data[1] << 8;
  return var;
}

uint8_t reconstruct_uint8(uint8_t* data){
  return data[0];
}

char reconstruct_int8(uint8_t* data){
  return (char) data[0];
}

double calc_uint16_diff(uint16_t x, uint16_t y){
  double diff = (double)x - (double)y;
  if (fabs(diff) > 500) { //just set a random threshold
    diff = diff > 0 ? diff - 65536 : diff + 65536;
  }
  return diff;
}

short boundShort(double value){
  if (value > static_cast<double>(SHRT_MAX)) return SHRT_MAX;
  if (value < static_cast<double>(SHRT_MIN)) return SHRT_MIN;
  return static_cast<short>(value);
}


void* feedbackUpdate(void* p_robot){
  turtleBot* robot = (turtleBot*) p_robot;
  while(1){
    pthread_mutex_lock (&robot->thread_enabled_mutex);
    if (!robot->thread_enabled){
      break;
    }
    pthread_mutex_unlock (&robot->thread_enabled_mutex);
    pthread_mutex_lock (&robot->mutex);
    robot->updateSensors();
    pthread_mutex_unlock (&robot->mutex);
  }
  pthread_exit(NULL);
}

void* controlUpdate(void* p_robot){
  turtleBot* robot = (turtleBot*) p_robot;
  int counter = 0;
  while(1){
    pthread_mutex_lock (&robot->thread_enabled_mutex);
    if (!robot->thread_enabled){
      break;
    }
    pthread_mutex_unlock (&robot->thread_enabled_mutex);
    pthread_mutex_lock (&robot->mutex);
    robot->updatePosition();
    pthread_mutex_unlock (&robot->mutex);

    counter = counter > 10000? 0 : counter+1;
    if (counter % 50 == 0)    //TODO: improve control frequency
      robot->closedLoopUpdate();


    #ifndef COMPILE_MEX
    if (counter % 50 == 0){
      robotPosition* pos = robot->getPosition();
      // mexPrintf("x: %f, y: %f, angle: %f，", pos->x, pos->y, pos->angle_degree);
      // mexPrintf("btn:%d%d%d\n", robot->getButtonStatus(0),
      printf("counter: %d, x: %f, y: %f, angle: %f \n", counter, pos->x, pos->y, pos->angle_degree);
    }
    #endif

  }
  pthread_exit(NULL);
}


turtleBot::turtleBot(){
  rx_packet = new unsigned char[MAX_RX_LOAD];
  for (int i = 0; i < MAX_RX_LOAD; i++)
    rx_packet[i] = 0;
  tx_packet = new unsigned char[MAX_TX_LOAD];
  unsigned char packet[10] = {(unsigned char)HEADER0, (unsigned char)HEADER1,
    (unsigned char)0x06, (unsigned char)CMD, (unsigned char)0x04,
    0, 0, 0, 0, 0};
  memcpy(tx_packet, packet, MAX_TX_LOAD);
  info = new sensorsInfo;
  prev_info = new sensorsInfo;
  position = new robotPosition;
  goto_params = new goToParams;
  resetPosition();
  discarded_packets = 0;
  port_fd = -1;
  goto_enabled = false;
  thread_enabled = true;

}

turtleBot::~turtleBot(){
  delete info;
  delete prev_info;
  delete position;
  delete[] rx_packet;
  delete[] tx_packet;
}

unsigned char turtleBot::readByte(){
  static unsigned char c;
  read(port_fd, &c, 1);
  return c;
}

double turtleBot::getWheelSpeed(bool wheel){
  if (discarded_packets < PACKETS_TO_DISCARD || info->used)
    return 0;
  info->used = true;
  double encoder_diff = 0;
  // double time_diff = calc_uint16_diff(info->time_stamp, prev_info->time_stamp);
  if (wheel){
    encoder_diff = calc_uint16_diff(info->right_encoder, prev_info->right_encoder);
  }else{
    encoder_diff = calc_uint16_diff(info->left_encoder, prev_info->left_encoder);
  }
  // return encoder_diff / time_diff;
  return encoder_diff;
}

void turtleBot::updatePosition(){
  if (discarded_packets < PACKETS_TO_DISCARD || info->used)
    return;

  info->used = true;
  double r_encoder_diff = calc_uint16_diff(info->right_encoder, prev_info->right_encoder);
  double l_encoder_diff = calc_uint16_diff(info->left_encoder, prev_info->left_encoder);

  if (fabs(r_encoder_diff) > 100.0 || fabs(l_encoder_diff) > 100.0){
    return;
  }

  // double time_diff = calc_uint16_diff(info->time_stamp, prev_info->time_stamp);
  // // store old info
  // memcpy(prev_info, info, sizeof(sensorsInfo));

  double delta_x = - (r_encoder_diff + l_encoder_diff) / 2.0f * sin(position->angle) * WHEEL_SCALE; //needs to be scaled
  double delta_y = (r_encoder_diff + l_encoder_diff) / 2.0f * cos(position->angle) * WHEEL_SCALE; //needs to be scaled
  double delta_angle = (r_encoder_diff - l_encoder_diff) / 2.0f / ROBOT_RADIUS * WHEEL_SCALE;

  // printf("%f, %f, %f \n", r_encoder_diff, l_encoder_diff, delta_angle);

  position->x += delta_x;
  position->y += delta_y;
  position->angle += delta_angle;

  //we need to check the angle
  if (position->angle > 2.0f * PI){
    position->angle -= 2.0f * PI;
  } else if (position->angle < 0){
    position->angle += 2.0f * PI;
  }

  position->angle_degree = position->angle / PI * 180.0f;
}

void turtleBot::resetPosition(){
  position->x = 0.f;
  position->y = 0.f;
  position->angle = 0.f;
  position->angle_degree = 0.f;
}

robotPosition* turtleBot::getPosition(){
  return position;
}

void turtleBot::setTargetPosition(goToParams* params){
  if (!goto_enabled){
    resetPosition();
    memcpy(goto_params, params, sizeof(goToParams));
    // goto_params = params;
    double orientation = atan2(-params->x, params->y) / PI * 180.0f;
    orientation = orientation < 0 ? orientation + 360.0f : orientation;
    if (params->heading == BACKWARD){
      orientation += 180.0f;
      orientation = orientation > 360.0f ? orientation - 360.0f : orientation;
    }
    goto_params->path_orientation = orientation;
    goto_enabled = true;
  }
}

bool turtleBot::getButtonStatus(int index){
  if (discarded_packets < PACKETS_TO_DISCARD)
    return false;
  return (info->buttons & (0x01 << index)) != 0;
}

bool turtleBot::zigzagToTarget(goToParams* target){
  double orientation = atan2(-(target->x - position->x), target->y - position->y) / PI * 180.0f;
  orientation = orientation < 0 ? orientation + 360.0f : orientation;
  // printf("orientation: %f \n", orientation);

  if (target->heading == BACKWARD){
    orientation += 180.0f;
    orientation = orientation > 360.0f ? orientation - 360.0f : orientation;
  }

  double orientation_error = orientation - position->angle_degree;
  if (fabs(orientation_error) > 180.0f){
    if (orientation_error > 0)
      orientation_error -= 360.0f;
    else
      orientation_error += 360.0f;
  }



  // tricky
  double dist_to_dest = -(target->x * position->x + target->y * position->y - (target->x*target->x + target->y*target->y))/
                          sqrt(target->x*target->x + target->y*target->y);

  if (fabs(position->x - target->x) < POS_TH && fabs(position->y - target->y) < POS_TH){
    return true;
  }

  double translational_speed = dist_to_dest * TRANSLATION_P;
  if (target->heading == BACKWARD)
    translational_speed = -dist_to_dest * TRANSLATION_P;

  // printf("translational: %f \n", translational_speed);

  translational_speed = fabs(translational_speed) > MAX_TRANS_SPEED ?
                        MAX_TRANS_SPEED * translational_speed / fabs(translational_speed) :
                        translational_speed;

  double rotational_speed = orientation_error * CORRECTION_P;
  rotational_speed = fabs(rotational_speed) > MAX_ROT_SPEED ?
                        MAX_CORR_SPEED * rotational_speed / fabs(rotational_speed) :
                        rotational_speed;


  setSpeed(translational_speed, rotational_speed);
  return false;
}

bool turtleBot::rotateToTargetAngle(double target){ //in degree
  double error  = target - position->angle_degree;
  if (fabs(error) > 180.0f){
    if (error > 0)
      error -= 360.0f;
    else{
      error += 360.0f;
    }
  }

  // printf("error: %f \n", error);
  if (fabs(error) < ANGLE_TH){
    return true;
  }

  double rotational_speed = error * ROTATION_P;
  rotational_speed = fabs(rotational_speed) > MAX_ROT_SPEED ?
                MAX_ROT_SPEED * rotational_speed / fabs(rotational_speed) :
                rotational_speed;

  setSpeed(0.0f, rotational_speed);

  return false;
}


void turtleBot::closedLoopUpdate(){
  static int state = 0;
  // printf("angle: %f \n", goto_params->angle_degree);
  if (goto_enabled && discarded_packets >= PACKETS_TO_DISCARD){
    switch (state){
      case rotatingToTargetPos:
        // printf("rotating \n");
        if (rotateToTargetAngle(goto_params->path_orientation))
          state = goingStraight;
        break;
      case goingStraight:
        // printf("going straight\n");
        if (zigzagToTarget(goto_params))
          state = rotatingToTargetAngle;
        break;
      case rotatingToTargetAngle:
        // printf("rotating \n");
        if (rotateToTargetAngle(goto_params->angle_degree)){
          state = rotatingToTargetPos;
          goto_enabled = false;
          setSpeed(0.0f, 0.0f);
        }
        break;
    }
  }
}

bool turtleBot::detectHeader(const unsigned char incoming){
  static int header_ind = 0;
  bool found = false;
  switch (header_ind) {
    case 0:
      if (incoming == HEADER0){
        header_ind++;
      }
      break;
    case 1:
      if (incoming == HEADER1){
        header_ind = 0;
        found = true;
      }
      break;
    default:
      return false;
  }
  return found;
}

bool turtleBot::deserializePacket(unsigned char* data){
  if (reconstruct_uint8(data) != SENSOR_ID)
    return false;
  data += 1;
  if (reconstruct_uint8(data) != LENGTH_PACKED)
    return false;
  data += 1;
  // store old info
  memcpy(prev_info, info, sizeof(sensorsInfo));

  info->time_stamp = reconstruct_uint16(data); data += 2;
  info->bumper = reconstruct_uint8(data); data += 1;
  info->wheel_drop = reconstruct_uint8(data); data += 1;
  info->cliff = reconstruct_uint8(data); data += 1;
  info->left_encoder = reconstruct_uint16(data); data += 2;
  info->right_encoder = reconstruct_uint16(data); data += 2;
  info->left_pwm = reconstruct_int8(data); data += 1;
  info->right_pwm = reconstruct_int8(data); data += 1;
  info->buttons = reconstruct_uint8(data); data += 1;
  info->charger = reconstruct_uint8(data); data += 1;
  info->battery = reconstruct_uint8(data); data += 1;
  info->over_current = reconstruct_uint8(data);
  info->used = false;
  // printf("l_enc: %d, r_enc: %d, bumper: %d, buttons: %d, battery: %d\n",
  //   info->left_encoder, info->right_encoder, info->bumper, info->buttons, info->battery);
  return true;
}

void turtleBot::fetchPacket(const unsigned char incoming){
  static int state = 0;
  static int count = 0;
  static unsigned char payload_size = 0;
  switch (state) {
    case waitForHeader:
      if (detectHeader(incoming)){
        state = waitForPayloadSize;
      }
      break;
    case waitForPayloadSize:
      payload_size = incoming;
      state = waitForPayload;
      break;
    case waitForPayload:
      if (count < payload_size + 2){ // two dummy bytes
        rx_packet[count++] = incoming;
      }else{
        deserializePacket(rx_packet);
        // reinitialize
        count = 0;
        payload_size = 0;
        for (int i = 0; i < MAX_RX_LOAD; i++)
          rx_packet[i] = 0;
        state = waitForHeader;
        if (discarded_packets < PACKETS_TO_DISCARD)
          discarded_packets++;
       }
      break;
    // TODO: test if checksum is correct
  }
}

void turtleBot::updateSensors(){
  fetchPacket(readByte());
}

void turtleBot::setSpeedBasic(short speed, short radius){
  if (fabs(speed) < 10){
    speed = 0;
  }

  // printf("setting speed: %d, %d \n", speed, radius);
  unsigned char checksum = 0;
  tx_packet[5] = (unsigned char)(speed & 0x00FF);
  tx_packet[6] = (unsigned char)(speed >> 8);
  tx_packet[7] = (unsigned char)(radius & 0x00FF);
  tx_packet[8] = (unsigned char)(radius >> 8);
  for (int i = 2; i < 9; i++){
    checksum ^= tx_packet[i];
  }
  tx_packet[9] = checksum;
  write(port_fd, tx_packet, 10);
}

void turtleBot::setSpeed(const double &vx, const double &wz) {
  // vx: in m/s
  // wz: in rad/s
  const double epsilon = 0.0001;
  double speed, radius;
  double bias = ROBOT_RADIUS * 2.0f / 1000.0f;

  // Special Case #1 : Straight Run
  if(fabs(wz) < epsilon ) {
    radius = 0.0f;
    speed  = 1000.0f * vx;
    setSpeedBasic(boundShort(speed), boundShort(radius));
    return;
  }

  radius = vx * 1000.0f / wz;
  // Special Case #2 : Pure Rotation or Radius is less than or equal to 1.0 mm
  if(fabs(vx) < epsilon || fabs(radius) <= 1.0f ) {
    speed  = 1000.0f * bias * wz / 2.0f;
    radius = 1.0f;
    setSpeedBasic(boundShort(speed), boundShort(radius));
    return;
  }

  // General Case :
  if( radius > 0.0f ) {
    speed  = (radius + 1000.0f * bias / 2.0f) * wz;
  } else {
    speed  = (radius - 1000.0f * bias / 2.0f) * wz;
  }
  setSpeedBasic(boundShort(speed), boundShort(radius));
  return;
}


bool turtleBot::initSerial(string port) {
  int fd = 0;
  struct termios options;

  fd = open(port.c_str(), O_RDWR | O_NOCTTY | O_NDELAY);
  if (fd == -1){
    return false;
  }
  fcntl(fd, F_SETFL, 0);    // clear all flags on descriptor, enable direct I/O
  tcgetattr(fd, &options);   // read serial port options
  //set baud rate
  //!!!! PAY ATTENTION TO THE BAUDRATE!!!!
  cfsetispeed(&options, B115200);
  cfsetospeed(&options, B115200);
  options.c_cflag |= (CLOCAL | CREAD);
  options.c_cflag &= ~PARENB;
  options.c_cflag &= ~CSTOPB;
  options.c_cflag &= ~CSIZE;
  options.c_cflag |= CS8;
  tcsetattr(fd, TCSANOW, &options);
  port_fd = fd;
  thread_enabled = true;
  return true;
}

bool turtleBot::checkSerial(){
  if (port_fd <= 0){
    return false;
  }
  return true;
}

bool turtleBot::closeSerial(){
  if (checkSerial()){
    close(port_fd);
    port_fd = -1;
    return true;
  }
  return false;
}

#ifndef COMPILE_MEX
int main(){
  robot = new turtleBot();

  if (!robot->checkSerial()){
    if (!robot->initSerial("/dev/tty.usbserial-kobuki_A901PEWI")){
      printf("ERROR: Serial port initialization failed \n");
    }else{
      printf("Serial port opened \n");
      pthread_mutex_init(&robot->mutex, NULL);
      pthread_mutex_init(&robot->thread_enabled_mutex, NULL);
      int rc;
      rc = pthread_create(&feedback_thread, NULL, feedbackUpdate, (void*)robot);
      if (rc){
        printf("feedback thread initialization failed");
        return -1;
      }
      rc = pthread_create(&control_thread, NULL, controlUpdate, (void*)robot);
      if (rc){
        printf("control thread initialization failed");
        return -1;
      }
      goToParams params = {-100.0, -100.0, 0.0, TOWARD};
      robot->setTargetPosition(&params);
      while(1);
    }
  }
  return 0;
}

#else
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  if (robot == NULL){
    robot = new turtleBot();
  }
  char* cmd = mxArrayToString(prhs[0]);
  if (!strcmp(cmd, "openSerial") && nrhs == 1){
    if (!robot->checkSerial()){
      if (!robot->initSerial("/dev/tty.usbserial-kobuki_A901PEWI")){
        mexPrintf("ERROR: Serial port initialization failed \n");
      }else{
        mexPrintf("Serial port opened \n");
        pthread_mutex_init(&robot->mutex, NULL);
        pthread_mutex_init(&robot->thread_enabled_mutex, NULL);
        int rc;
        rc = pthread_create(&feedback_thread, NULL, feedbackUpdate, (void*)robot);
        if (rc){
          mexPrintf("feedback thread initialization failed");
          return;
        }
        rc = pthread_create(&control_thread, NULL, controlUpdate, (void*)robot);
        if (rc){
          mexPrintf("control thread initialization failed");
          return;
        }
      }
    }
  } else if (!strcmp(cmd, "help")){
    mexPrintf("Command list: \n"
    "turtleBot(\'openSerial\') - open turtlebot serial port \n"
    "turtleBot(\'setSpeed\', trans, rot) - set translational and rotational speed \n"
    "pos = turtleBot(\'getPosition\') - get turtleBot position, return value is [x; y; angle]\n"
    "turtleBot(\'goTo\', pos) - go to target position \n"
    "turtleBot(\'bye\') - shut down the turtlebot \n");
  } else{
    if (!robot->checkSerial()){
      mexPrintf("Serial port not initialized \n");
      return;
    }
    if (!strcmp(cmd, "setSpeed") && nrhs == 3){
      double* arg1 = (double*) mxGetData(prhs[1]);
      double* arg2 = (double*) mxGetData(prhs[2]);
      robot->setSpeed(arg1[0], arg2[0]);
    } else if (!strcmp(cmd, "getPosition") && nlhs == 1 && nrhs == 1){
      mwSize dims[2] = {3, 1};
      plhs[0] = mxCreateNumericArray(2, dims, mxDOUBLE_CLASS, mxREAL);
      double* pos = (double*) mxGetData(plhs[0]);
      robotPosition* p = robot->getPosition();
      pos[0] = p->x; pos[1] = p->y; pos[2] = p->angle_degree;
    } else if (!strcmp(cmd, "goTo") && nrhs == 2){
      double* pos = (double*) mxGetData(prhs[1]);
      goToParams params = {pos[0], pos[1], pos[2], pos[3]};
      robot->setTargetPosition(&params);
    } else if (!strcmp(cmd, "bye")) {
      robot->closeSerial();
      pthread_mutex_lock (&robot->thread_enabled_mutex);
      robot->thread_enabled = false;
      pthread_mutex_unlock (&robot->thread_enabled_mutex);

      pthread_mutex_destroy(&robot->mutex);
      pthread_mutex_destroy(&robot->thread_enabled_mutex);

      delete robot;
      robot = NULL;

      // pthread_exit(NULL);
    } else{
      mexPrintf("Command not found. Type turtleBot(\'help\')\n");
    }
  }

  return;
}
#endif
