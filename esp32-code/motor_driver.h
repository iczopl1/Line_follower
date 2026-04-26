#ifndef motor_H
#define motor_H
#include <Arduino.h>
#include "config.h"
void motor_init();
void motor_control(int left, int right);

#endif