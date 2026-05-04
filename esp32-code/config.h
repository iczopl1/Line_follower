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

// Extern variables - definitions are in esp32-code.ino
extern float Kp;
extern float Ki;
extern float Kd;
extern float MaxSpeed;
extern float BaseSpeed;
extern float TurnSpeed;
extern float lost_threshold;
extern int lastError;
extern int rightMotorSpeed;
extern int leftMotorSpeed;
extern int last_sighted;
extern int lost;
extern int last_detection_time;
extern int ready;
extern uint16_t sensorValues[NUM_SENSORS];
extern QTRSensors qtr;

#endif
