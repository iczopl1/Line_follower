#include <Arduino.h>
#include <WiFi.h>
#include <AsyncUDP.h>
#include <functional>

#include "config.h"
#include "COMUNICATION_WIFI.h"

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

AsyncUDP udp;

void comunication_init(){

  String ssid  = Host_name;
  String password = password_wifi;
  WiFi.softAP(ssid,password);
  if(udp.listen(1234)) {
    Serial.print("UDP Listening on IP: ");
    Serial.println(WiFi.localIP());
  }
  // Handler otrzymanych pakietów
  udp.onPacket([](AsyncUDPPacket packet) {
      char* tmpStr = (char*) malloc(packet.length() + 1);
      memcpy(tmpStr, packet.data(), packet.length());
      tmpStr[packet.length()] = '\0'; // ensure null termination
      String message = String(tmpStr);
      String firstTwoLetters = message.substring(0, 2);
      free(tmpStr);

      Serial.println(message);
          if(message == "Cal"){
              calibrate();
          }
          if(message == "Reset"){
              ESP.restart();
          }
          if(message == "Start"){
              ready = 1;
          }
          if(message == "Stop"){
              ready = 0;
          }
          if(message == "Sensors"){
              request_sensorsRaw();
          }
          if(message == "Params"){
              request_params();
          }
          if(firstTwoLetters == "Kp"){
            String numericalPart = message.substring(4);
            float numericalValue = numericalPart.toFloat();
            Kp = numericalValue;
          }
          if(firstTwoLetters == "Ki"){
            String numericalPart = message.substring(4);
            float numericalValue = numericalPart.toFloat();
            Ki = numericalValue;
          }
          if(firstTwoLetters == "Kd"){
            String numericalPart = message.substring(4);
            float numericalValue = numericalPart.toFloat();
            Kd = numericalValue;
          }
          if(firstTwoLetters == "Ma"){
            String numericalPart = message.substring(4);
            float numericalValue = numericalPart.toFloat();
            MaxSpeed = numericalValue;
          }
          if(firstTwoLetters == "Ba"){
            String numericalPart = message.substring(4);
            float numericalValue = numericalPart.toFloat();
            BaseSpeed = numericalValue;
          }
          if(firstTwoLetters == "Tu"){
            String numericalPart = message.substring(4);
            float numericalValue = numericalPart.toFloat();
            TurnSpeed = numericalValue;
          }
          if(firstTwoLetters == "Th"){
            String numericalPart = message.substring(4);
            float numericalValue = numericalPart.toFloat();
            lost_threshold = numericalValue;
          }
    });
}
void com_send(const String& message){
    udp.broadcast(message.c_str());
}

// Funkcja kalibracji. "C" jest uywane przez aplikację na telefonie do określenia czy kalibracja się skończyła
void calibrate(){
  qtr.resetCalibration();
  for (uint16_t i = 0; i < 400; i++){
    qtr.calibrate();
  }
  for (uint8_t i = 0; i < NUM_SENSORS; i++){
    com_send(String(qtr.calibrationOn.minimum[i]));
    #ifdef DEBUG
    Serial.print(String(qtr.calibrationOn.minimum[i]));
    Serial.print(' ');
    #endif
  }
  com_send("C");
  com_send("C");
  com_send("C");
}
// Wysyła wartości kazdego czujnika do aplikacji
void request_sensorsRaw(){
  String sensors = "Sensor ";
  for (uint8_t i = 0; i < NUM_SENSORS; i++)
  {
    sensors += String(sensorValues[i]) + " ";
  }
  sensors += "Last: " + String(last_sighted) + " Lost: " + String(lost);
  #ifdef DEBUG
  Serial.print(sensors);
  #endif
  com_send(sensors);
}
// Wysyła aktualne parametry do aplikacji
void request_params(){
  String params = "Kp: " + String(Kp) + " Ki: " + String(Ki) + " Kd: " + String(Kd) + " Max: " + String(MaxSpeed) + " Base: " + String(BaseSpeed) + " Turn: " + String(TurnSpeed) + " Lost_th: " + String(lost_threshold);
  #ifdef DEBUG
  Serial.println(params);
  #endif
  com_send(params);
}

