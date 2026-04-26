#ifndef config_H
#define config_H
//GPIO porty
#define NUM_SENSORS  8    
#define EMITTER_PIN   16     
#define LEFT_MOTOR_FORWARD 11
#define LEFT_MOTOR_BACKWARD 12
#define RIGHT_MOTOR_FORWARD 13
#define RIGHT_MOTOR_BACKWARD 14
#define NEOPIXEL_PIN 48
#define NUM_PIXELS 1

//WIFI-Bluetooh
#define Host_name "LFiczo"
#define password_wifi "orka2314"
#define DEBUG
#define Serial_speed 115200

//globalne wartości co się zmieniają
extern float Kp;
extern float Ki;
extern float Kd;

extern float MaxSpeed;
extern float BaseSpeed;
extern float TurnSpeed;
extern float lost_threshold;

extern int ready;

#endif