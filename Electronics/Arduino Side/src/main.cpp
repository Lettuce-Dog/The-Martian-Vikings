#include <Arduino.h>

#define PIN_Y A0
#define PIN_X A1
#define PRESS 7

void setup() {
  Serial.begin(9600);

  pinMode(PIN_Y,INPUT);
  pinMode(PIN_X,INPUT);
  pinMode(PRESS,INPUT_PULLUP);
}

void loop() {
  float x = (analogRead(PIN_X) - 512) / 512.0;
  float y = (analogRead(PIN_Y) - 512) / 512.0;
  float press = digitalRead(PRESS);

  Serial.print(x, 3);
  Serial.print(',');
  Serial.print(y, 3);
  Serial.print(',');
  Serial.println(press, 1);
  delay(20);
}