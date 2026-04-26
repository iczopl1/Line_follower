#include <QTRSensors.h>
#include <Adafruit_NeoPixel.h>
#include <functional>
//bibloteki w folderze
#include "pid.h"
#include "motor_driver.h"
//define ustawienia portów w config.h
#include "config.h"
//Wybieracie sposób komunikacj na razie jest tylko wifi
#define USE_WIFI   // zakomentuj żeby używać BT
#ifdef USE_WIFI
  #include "COMUNICATION_WIFI.h"
#else
  #include "COMUNICATION_BT.h"
#endif
//domyślne wartości 

float Kp = 0.5; 
float Ki = 0.0;  
float Kd = 5;
float MaxSpeed = 80; 
float BaseSpeed = 50;
float TurnSpeed = 70;
float lost_threshold = 450; //po jakim czasie robot się zgubił
int lastError = 0;
int rightMotorSpeed = 0;
int leftMotorSpeed = 0;
int last_sighted = 0;
int lost;
int lost_sensors;
int last_detection_time = 0;
int ready = 0;

//zegary
unsigned long lastMillis;
static unsigned long lastPidTime;

// co ile wysyłać dane najlepiej wcale więć wpisać 100000000
int interval = 200;
//sensory
uint16_t sensorValues[NUM_SENSORS];
QTRSensors qtr;

//aktywacja PID
PID pid;

//ustawienia diody led
Adafruit_NeoPixel pixels(NUM_PIXELS, NEOPIXEL_PIN, NEO_GRB + NEO_KHZ800);

void setup()
{
  #ifdef DEBUG
  Serial.begin(Serial_speed);
  #endif
  pidInit(pid, Kp, Ki, Kd);
  pixels.begin();
  motor_init();
  //przekazanie funkcji w tym pliku by uniknąć kopiowania danych
  comunication_init(calibrate, request_sensorsRaw, request_params);
  //ustawienia sensorów 
  qtr.setTypeAnalog();
  // qtr.setSensorPins((const uint8_t[]){ 7, 4, 5, 10, 6, 8, 3, 9}, NUM_SENSORS);
  qtr.setSensorPins((const uint8_t[]){ 9, 3, 8, 6, 10, 5, 4, 7}, NUM_SENSORS);
  qtr.setEmitterPin(EMITTER_PIN);
}

void loop()
{
  // Czytaj pozycję czarnej linii

  int position = qtr.readLineBlack(sensorValues);

  // Zapamiętywanie ostatniej pozycji linii

if (sensorValues[0] >= 800 && sensorValues[NUM_SENSORS-1] < 800) {
    if (last_sighted != 1 && millis() - last_detection_time >= 100) {
      last_sighted = 1;
      last_detection_time = millis();
      pixels.setPixelColor(0, pixels.Color(0, 255, 0)); // Zielony dla lewej
      pixels.show();
    }
  } else if (sensorValues[0] < 800 && sensorValues[NUM_SENSORS-1] >= 800) {
    if (last_sighted != 2 && millis() - last_detection_time >= 100) {
      last_sighted = 2;
      last_detection_time = millis();
      pixels.setPixelColor(0, pixels.Color(255, 0, 0)); // Czerwony dla prawej
      pixels.show();
    }
  } 
  //sprawdzenie zgubienia robota
  lost_sensors = 0;
  lost = 0;
  for(int i = 0; i < NUM_SENSORS; i++){
    if(sensorValues[i] <= lost_threshold){
      lost_sensors += 1;
    }
  }
  if(lost_sensors >= NUM_SENSORS * 0.8){
    lost = 1;
  }

  // Regulator PID. Error nalezy ustawić w zalezności od ilości czujników np. dla 6 czujników max pozycja to 5000 dlatego srodek linii to 2500 a dla 8 czujników max pozycja to 7000 więc środek linii to 3500
  int error = position - 3500;
  //liczenie dt 
  unsigned long now = millis();
  float dt = (now - lastPidTime) / 1000.0;
  lastPidTime = now;
  if (lastPidTime == 0) lastPidTime = now;


  float motorSpeed = pidUpdate(pid, error, dt);
  //poprawka szybkich zmian error powinła pomuć na chujowych trasach
  float speedFactor = 1.0 - min(abs(error) / 3000.0, 0.7);
  rightMotorSpeed = (BaseSpeed + motorSpeed) * speedFactor;
  leftMotorSpeed  = (BaseSpeed - motorSpeed) * speedFactor;
  
  if (rightMotorSpeed > MaxSpeed ) rightMotorSpeed = MaxSpeed; 
  if (leftMotorSpeed > MaxSpeed ) leftMotorSpeed = MaxSpeed; 
  if (rightMotorSpeed < -MaxSpeed) rightMotorSpeed = -MaxSpeed; 
  if (leftMotorSpeed < -MaxSpeed) leftMotorSpeed = -MaxSpeed; 

  // Wysyłanie danych czujników co ustalony interwał czasu (ms)
  
  if (now - lastMillis >= interval) { 
    lastMillis = now;
    String pos = "Position: " + String(position);
    com_send(pos.c_str());
    com_send("!");
    #ifdef DEBUG
    Serial.print(pos);
    #endif
    request_sensorsRaw();
  }

  // Algorytm jazdy

  if(ready == 1){
    if(lost == 1 && last_sighted == 1){
      //zgóbiony w lewo
      motor_control(-TurnSpeed, TurnSpeed);
    }
    else if(lost == 1 && last_sighted == 2){
      //zgubiony w prawo
      motor_control(TurnSpeed, -TurnSpeed);
    }
    else{
      //pid iechanie
      motor_control(rightMotorSpeed, leftMotorSpeed);
    }
  }
  else{
    //stoi bo nie uruchomony
    motor_control(0, 0);
  }
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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