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

// Files on LittleFs system. Upload of config.cfg is required before first run.
const char* configFileName = "/config.cfg";
const char* messageFileName = "/message.json";

/*
 * Remove stored payload file
 */
void clearPayloadFromStorage() {
  LittleFS.remove(messageFileName);
}

// Remove certificate files
/*void clearCertStorage() {
  LittleFS.remove(g_certIdxFileName);
}*/

/*
 * Try to read payload (Last received message) file from storage.
 * File is not required. On first startup the file is missing.
 * 
 * If a file was found, the content is loaded into messagePayload.
 */
void readPayloadFromStorage() {
  Serial.println("Trying to load message.json from storage");
  File file = LittleFS.open(messageFileName, "r");
  if (!file) {
    Serial.println("Payload file message.json not found");
    return;
  }

  Serial.print("Found file with size: ");
  Serial.println(file.size());

  uint8_t payloadString[file.size()] = "";
  file.read(payloadString, file.size());
  file.close();
  Serial.println((char*)payloadString);
  DeserializationError err = deserializeJson(messagePayload, payloadString);
  if (err) {
    Serial.print("Invalid json ");
    Serial.println(err.c_str());
    return;
  }

  // TODO Check if required fields are present
  onLoveMessage(true);
}

/*
 * Save received payload to file
 */
void savePayloadToStorage(byte* data, int length) {
  Serial.println("Saving message.json to storage");
  File file = LittleFS.open(messageFileName, "w");
  if (!file) {
    Serial.println("Failed to open file for writing");
    return;
  }

  Serial.print("Writing ");
  Serial.println(length);
  
  file.write(data, length);
  delay(100);
  file.close();
}

/*
 * Initialise LittleFS filesystem and load config file.
 */
void setupStorage() {
  LittleFS.begin();

  // Load config from littleFs config file
  File configFile = LittleFS.open(configFileName, "r");
  if (!configFile) {
    Serial.println("Could not open config file");
    for(;;);
    return;
  }
  String configString = configFile.readString();
  configFile.close();
  
  Serial.println("Loaded config:");
  Serial.println(configString);
  DeserializationError err = deserializeJson(config, configString);
  if (err) {
    Serial.println("Invalid json");
    Serial.println(err.c_str());
    for(;;);
    return;
  }
}
