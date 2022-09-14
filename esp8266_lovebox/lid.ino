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

// Light sensor threshold
#define LID_OPEN_THRESHOLD 60

#define LID_OPEN 1
#define LID_CLOSED 0

// Tick rate for sensor level checking
#define LID_TICK_RATE_HUNDRETS 5

// Sensor pin
#define LDR A0

int lidStatus = LID_CLOSED;
int lidTick = 0;

bool isLidClosed() {
  return lidStatus == LID_CLOSED;
}

/*
 * Read light level from sensor and emit events based on read value.
 */
void updateLightLevel() {
  int light = analogRead(A0);
  if(light > LID_OPEN_THRESHOLD) {
    if(lidStatus == LID_CLOSED) {
      lidStatus = LID_OPEN;
      onLidOpen();
    }
  }
  else {
    if(lidStatus == LID_OPEN) {
      lidStatus = LID_CLOSED;
      onLidClose();
    }
  }
}

/*
 * Loop is called in intervals of LOOP_TICK_RATE_MS. We do not 
 * need to check this often for a light level change, so check only
 * every 500ms
 */
void loopLid() {
  lidTick++;
  if(lidTick > LID_TICK_RATE_HUNDRETS) {
    lidTick = 0;
    updateLightLevel();
  }
}
