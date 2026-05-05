#include "motor_driver.h"
#include <Arduino.h>
#include "config.h"

void motor_init(){
  pinMode(LEFT_MOTOR_FORWARD, OUTPUT);
  pinMode(LEFT_MOTOR_BACKWARD, OUTPUT);
  pinMode(RIGHT_MOTOR_FORWARD, OUTPUT);
  pinMode(RIGHT_MOTOR_BACKWARD, OUTPUT);
  
  analogReadResolution(12);
}
void setMotor(int forwardPin, int backwardPin, int speed){
    speed = constrain(speed, -255, 255);

    if(speed > 0){
        analogWrite(forwardPin, speed);
        analogWrite(backwardPin, 0);
    }
    else if(speed < 0){
        analogWrite(forwardPin, 0);
        analogWrite(backwardPin, -speed);
    }
    else{
        analogWrite(forwardPin, 0);
        analogWrite(backwardPin, 0);
    }
}

void motor_control(int left, int right){
    setMotor(LEFT_MOTOR_FORWARD, LEFT_MOTOR_BACKWARD, left);
    setMotor(RIGHT_MOTOR_FORWARD, RIGHT_MOTOR_BACKWARD, right);
}
