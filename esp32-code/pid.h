#ifndef PID_H
#define PID_H
#include <Arduino.h>
#include "config.h"

struct PID {
    float kp;
    float ki;
    float kd;

    float integral;
    float prevError;
};

void pidInit(PID &pid, float kp, float ki, float kd);
float pidUpdate(PID &pid, float error, float dt);

#endif