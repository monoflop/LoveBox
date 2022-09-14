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

// Wait time after each frame
#define FRAME_DELAY 50

/*
 * Show all boot frames with FRAME_DELAY.
 * 50ms delay prodcuces a semi fluent animation.
 */
void animateBootScreen()
{
  uint8_t * frames[] = {FRAME_1, FRAME_2, FRAME_3, FRAME_4, FRAME_5, FRAME_6, FRAME_7, FRAME_8};
  uint8_t frameCount = 8;
  for(int i = 0; i < frameCount; i++)
  {
    display.clearDisplay();
    display.drawBitmap(0, 0, frames[i], SCREEN_WIDTH, SCREEN_HEIGHT, WHITE);
    display.display();
    delay(FRAME_DELAY);
  }
}

/*
 * Draw final frame of boot screen with horizontal divider 
 * and centered one line of text.
 */
void drawBootScreenWithText(const char* text)
{
  display.clearDisplay();
  display.drawBitmap(0, 0, FRAME, SCREEN_WIDTH, SCREEN_HEIGHT, WHITE);
  display.setTextSize(1);
  display.setTextColor(WHITE);
  display.setCursor(0, 0);
  
  // Use full "Code Page 437"
  display.cp437(true);
  
  drawHorizontalCenteredString(text, 55);
  display.display();
}

/*
 * Draw simple string centered on screen.
 * Payload is a unencoded string.
 */
void drawSimpleTextPayload(const char* payload)
{
    // Clear the buffer
    display.clearDisplay();
    // Start at top-left corner
    display.setCursor(0, 0);
    drawCenteredString(payload);
    display.display();
}

/*
 * Draw bitmap payload.
 * Payload is an base64 encoded bitmap.
 */
void drawBitmapPayload(const char* payload)
{
    //Convert base64 payload to bitmap
    uint8_t binary[BASE64::decodeLength(payload)];
    BASE64::decode(payload, binary);

    // Clear the buffer
    display.clearDisplay();

    //Draw bitmap
    display.drawBitmap(0, 0, binary, SCREEN_WIDTH, SCREEN_HEIGHT, WHITE);
    display.display();
}

void drawHorizontalCenteredString(const char *buf, int vertical)
{
    int16_t x1, y1;
    uint16_t w, h;
    display.getTextBounds(buf, 0, 0, &x1, &y1, &w, &h);
    display.setCursor(SCREEN_WIDTH / 2 - w / 2, vertical);
    display.print(buf);
}

void drawCenteredString(const char *buf)
{
    int16_t x1, y1;
    uint16_t w, h;
    display.getTextBounds(buf, 0, 0, &x1, &y1, &w, &h);
    display.setCursor(SCREEN_WIDTH / 2 - w / 2, SCREEN_HEIGHT / 2 - h / 2);
    display.print(buf);
}
