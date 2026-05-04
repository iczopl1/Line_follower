#ifndef COMUNICATION_WIFI_H
#define COMUNICATION_WIFI_H

#include <Arduino.h>
#include <functional>
#include <AsyncUDP.h>
#include <WiFi.h>
#include "config.h"
#include <QTRSensors.h> // Include QTRSensors for qtr object

extern AsyncUDP udp;

// External global variables from esp32-code.ino
extern float Kp;
extern float Ki;
extern float Kd;
extern float MaxSpeed;
extern float BaseSpeed;
extern float TurnSpeed;
extern float lost_threshold;
extern int lastError; // Not explicitly used by these functions, but good to keep consistent
extern int rightMotorSpeed;
extern int leftMotorSpeed;
extern int last_sighted;
extern int lost;
extern int last_detection_time;
extern int ready;
extern uint16_t sensorValues[NUM_SENSORS]; // NUM_SENSORS from config.h
extern QTRSensors qtr; // QTRSensors object

void comunication_init(); // No longer takes function pointers
void com_send(const String& message);

// Moved function prototypes
void calibrate();
void request_sensorsRaw();
void request_params();

#endif