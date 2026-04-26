#include <Arduino.h>
#include <WiFi.h>
#include <AsyncUDP.h>
#include <functional>

#include "config.h"
#include "COMUNICATION_WIFI.h"
static std::function<void()> calibrate;
static std::function<void()> request_sensorsRaw;
static std::function<void()> request_params;
AsyncUDP udp;
void comunication_init(std::function<void()> calibrate_cb,std::function<void()> sensors_cb,std::function<void()> params_cb){

  calibrate = calibrate_cb;
  request_sensorsRaw = sensors_cb;
  request_params = params_cb;

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

