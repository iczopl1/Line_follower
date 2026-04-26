#ifndef COMUNICATION_WIFI_H
#define COMUNICATION_WIFI_H

#include <Arduino.h>
#include <functional>
#include <AsyncUDP.h>
#include <WiFi.h>
#include "config.h"

extern AsyncUDP udp;

void comunication_init(
    std::function<void()> calibrate_cb,
    std::function<void()> sensors_cb,
    std::function<void()> params_cb
);

void com_send(const String& message);

#endif