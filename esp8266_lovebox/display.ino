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

#include "localization.hpp"
 
// OLED display width, height, in pixels
#define SCREEN_WIDTH 128 
#define SCREEN_HEIGHT 64

// Declaration for an SSD1306 display connected to I2C (SDA, SCL pins)
#define OLED_RESET 0

// If the display is enabled for this many ticks, we simply turn it of
#define DISPLAY_TIMEOUT_TICKS 600

// Display
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

bool displayEnabled = true;
int displayTimeoutTick = 0;

/*
 * Turn display on / off
 */
void toggleDisplay(bool enabled) {
  displayEnabled = enabled;
  if(enabled) {
    display.ssd1306_command(SSD1306_DISPLAYON);
  }
  else {
    display.ssd1306_command(SSD1306_DISPLAYOFF);
  }
}

/*
 * Setup display
 * and show "boot animation"
 */
void setupDisplay() {
  // Initialise display
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("SSD1306 allocation failed");
    for(;;); // Don't proceed, loop forever
  }

  // Show boot animation
  animateBootScreen();
  drawBootScreenWithText(bootScreenLoading);
}


/*
 * Loop display
 * count ticks and disable display after max tick count was reached
 */
void loopDisplay() {
  if(displayEnabled) {
    if(displayTimeoutTick >= DISPLAY_TIMEOUT_TICKS) {
      Serial.println("Timeout -> Display disabled");
      toggleDisplay(false);
    }
    else {
      displayTimeoutTick++;
    }
  }
  else {
    displayTimeoutTick = 0;
  }
}
