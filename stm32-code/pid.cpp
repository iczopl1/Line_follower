#include "pid.h"
#include <Arduino.h>
#include "config.h"

void pidInit(PID &pid, float kp, float ki, float kd) {
    pid.kp = kp;
    pid.ki = ki;
    pid.kd = kd;
    pid.integral = 0;
    pid.prevError = 0;
}

float pidUpdate(PID &pid, float error, float dt) {
    pid.integral += error * dt;
    float derivative = (error - pid.prevError) / dt;
    pid.prevError = error;

    return pid.kp * error + pid.ki * pid.integral + pid.kd * derivative;
}