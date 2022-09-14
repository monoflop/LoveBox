/*
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
 
#include "Servo.h"

#define SERVO_IDLE_ANGLE 90
#define SERVO_MAX_ANGLE_UP 140
#define SERVO_MAX_ANGLE_DOWN 40

// Servo pin
const uint8_t servo_pin = D0;

// Current servo angle
int servoAngle = SERVO_IDLE_ANGLE;

// Server is rotating
bool pulsingEnabled = false;

// Servo rotating direction
bool countUp = true;

Servo myservo;

/*
 * Start servo movement
 */
void startHeartServo() {
  pulsingEnabled = true;
}

/*
 * Stop servo movement and reset state
 */
void stopHeartServo() {
  servoAngle = SERVO_IDLE_ANGLE;
  pulsingEnabled = false;
  countUp = true;
  myservo.write(servoAngle);
}

/*
 * Setup server
 */
void setupServo() {
  servoAngle = SERVO_IDLE_ANGLE;

  // Attach servo object and set initial angle.
  myservo.attach(servo_pin);
  myservo.write(servoAngle);
}

/*
 * Loop servo
 * Increment servo angle in SERVO_MAX_ANGLE_UP, SERVO_MAX_ANGLE_DOWN range
 */
void loopServo() {
  if(pulsingEnabled) {
    if(countUp) {
      servoAngle += 5;
    }
    else {
      servoAngle -= 5;
    }
  
    Serial.print("Setting servo angle ");
    Serial.println(servoAngle);
    
    myservo.write(servoAngle);
  
    if(servoAngle == SERVO_MAX_ANGLE_UP) {
      countUp = false;
    }
    else if(servoAngle == SERVO_MAX_ANGLE_DOWN) {
      countUp = true;
    }
  }
}
