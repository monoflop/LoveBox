/*
 * Lovebox project
 * 
 * This is my first Arduino project.
 * Best practices and conventions were skillfully ignored.
 * 
 * I have tried to put individual functionalities in their own .ino file.
 * For example, most of the display code is in display.ino.
 * 
 * ---------------------------
 * Board:
 * ---------------------------
 * esp8266
 * 
 * ---------------------------
 * Libraries:
 * ---------------------------
 * Adafruit GFX Library
 * Adafruit SSD1306
 * ArduinoJson
 * Base64_Codec
 * PubSubClient
 * ESP8266FS
 * ESP8266LittleFS
 * 
 * MIT License
 *
 * Copyright (c) 2022 Philipp Kutsch
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
#include <Arduino.h>
#include <ArduinoJson.h>
#include "base64.hpp"
#include "bitmaps.hpp"
#include "localization.hpp"

#include <FS.h>
#include <LittleFS.h>

#include <ESP8266WiFi.h>
//#include <CertStoreBearSSL.h>
#include <PubSubClient.h>
#include <time.h>
#include <TZ.h>

#include <SPI.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// Tick rate of the main loop
#define LOOP_TICK_RATE_MS 100

#define CONFIG_JSON_BUFFER_SIZE 512
#define PAYLOAD_JSON_BUFFER_SIZE 2048

#define CONTENT_TYPE_SIMPLE_TEXT 1
#define CONTENT_TYPE_BITMAP 2

// Config
DynamicJsonDocument config(CONFIG_JSON_BUFFER_SIZE);

// Payload
DynamicJsonDocument messagePayload(PAYLOAD_JSON_BUFFER_SIZE);

// TODO if we send binary data with invalid payload, the system crash loops

/*
 * Event: Reconnecting MQTT
 * 
 * Send by network.ino
 */
void onReconnecting() {
  drawBootScreenWithText(bootScreenConnecting);
}

/*
 * Event: MQTT connected
 * 
 * Send by network.ino
 */
void onConnected() {
  drawBootScreenWithText(bootScreenSuccess);

  //Load inital message from storage
  readPayloadFromStorage();
}

/*
 * Event: Lid was opended
 * 
 * Send by lid.ino
 */
void onLidOpen() {
  Serial.println("onLidOpen");

  //Turn display on
  toggleDisplay(true);

  //Stop heart servo
  stopHeartServo();

  //Send mqtt command
  loveBoxSendCommand("lidOpen");
}

/*
 * Event: Lid was closed
 * 
 * Send by lid.ino
 */
void onLidClose() {
  Serial.println("onLidClose");

  //Turn display off
  toggleDisplay(false);

  //Send mqtt command
  loveBoxSendCommand("lidClosed");
}

/*
 * New love message has arrived
 * 
 * The message is already deserialized and stored in messagePayload
 */
void onLoveMessage(bool fromStorage) {
  Serial.println("onLoveMessage");

  // Load data from JSON
  int type = messagePayload["type"];
  const char* payload = messagePayload["payload"];

  // Start heart servo if the lid is closed and an message
  // was received from network
  if(!fromStorage && isLidClosed()) {
    startHeartServo();
  }

  if((type == CONTENT_TYPE_SIMPLE_TEXT)) {
    Serial.println("CONTENT_TYPE_SIMPLE_TEXT");
    drawSimpleTextPayload(payload);
  }
  else if((type == CONTENT_TYPE_BITMAP)) {
    Serial.println("CONTENT_TYPE_BITMAP");
    drawBitmapPayload(payload);
  }
}

/*
 * Setup
 */
void setup() {
  delay(500);
  Serial.begin(115200);
  delay(500);
  Serial.println("\nStarted");

  setupDisplay();
  setupStorage();
  
  // For testing purpose
  // clearPayloadFromStorage();
  // clearCertStorage();
  
  setupNetwork();
  setupServo();
}

/*
 * Loop
 */
void loop() {
  loopDisplay();
  loopNetwork();
  loopLid();
  loopServo();
  delay(LOOP_TICK_RATE_MS);
}
