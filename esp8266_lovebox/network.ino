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

#define MQTT_PACKET_BUFFER_SIZE 2048

// For cert and mqtt setup look at this guide: https://console.hivemq.cloud/clients/arduino-esp8266
// Cert files, currently not used.
//TODO cert loading causes crash (maybe out of ram?)
//TODO remove all unennessary certs.
/*const char* g_certIdxFileName = "/certs.idx";
const char* g_certArFileName = "/certs.ar";
BearSSL::CertStore certStore;*/

WiFiClientSecure espClient;
PubSubClient* mqttClient;

/*
 * Setup wifi and mqtt client
 */
void setupNetwork() {
  //Setup wifi
  const char* ssid = config["wifi_ssid"];
  const char* pass = config["wifi_pass"];
  setupWifi(ssid, pass);

  // Setup ntp time
  //setDateTime();

  // Load and setup certs
  /*int numCerts = certStore.initCertStore(LittleFS, g_certIdxFileName, g_certArFileName);
  Serial.printf("Number of CA certs read: %d\n", numCerts);
  if (numCerts == 0) {
    Serial.printf("No certs found. Did you run certs-from-mozilla.py and upload the LittleFS directory before running?\n");
    for(;;); // Don't proceed, loop forever
    return; // Can't connect to anything w/o certs!
  }*/
  BearSSL::WiFiClientSecure *bear = new BearSSL::WiFiClientSecure();
  //bear->setCertStore(&certStore);
  bear->setInsecure();

  //Setup mqttClient
  const char* mqttServer = config["mqtt_server"];
  int mqttPort = config["mqtt_port"];
  mqttClient = new PubSubClient(*bear);
  mqttClient->setBufferSize(MQTT_PACKET_BUFFER_SIZE);
  mqttClient->setServer(mqttServer, mqttPort);
  mqttClient->setCallback(mqttCallback);
}

/*
 * 
 */
void loopNetwork() {
  if (!mqttClient->connected()) {
    mqttReconnect();
  }
  mqttClient->loop();
}

/*
 * Setup wifi and wait for connection.
 */
void setupWifi(const char* ssid, const char* pass) {
  delay(10);
  
  Serial.print("WiFi Connecting to ");
  Serial.println(ssid);

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, pass);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  randomSeed(micros());

  Serial.println("WiFi connected");
}

/*
 * Setup time and date from ntp server
 * Correct time is needed for cert verification
 */
/*void setDateTime() {
  configTime(TZ_Europe_Berlin, "pool.ntp.org", "time.nist.gov");

  Serial.print("Waiting for NTP time sync: ");
  time_t now = time(nullptr);
  while (now < 8 * 3600 * 2) {
    delay(100);
    Serial.print(".");
    now = time(nullptr);
  }
  Serial.println();

  struct tm timeinfo;
  gmtime_r(&now, &timeinfo);
  Serial.printf("%s %s", tzname[0], asctime(&timeinfo));
}*/

/*
 * MQTT callback
 * Listen to messages on mqtt_topic and mqtt_control_in_topic topics
 * TODO add json validation
 * 
 * mqtt_topic:
 * Love messages arrive over this channel. Message format JSON:
 * type: Integer | 1 = Plain Text, 2 = Bitmap
 * blinking: Integer | Is ignored at the moment
 * payload: String | If type = 1 -> Plain text, type 2 = Base64 Bitmap
 * If the message was successfully parsed, we responde with "messageReceived"
 * over the mqtt_control_out_topic topic.
 * 
 * mqtt_control_in_topic:
 * Control messages arrive over this channel. Message format is plain text.
 * "ping" : Send "pong" over mqtt_control_out_topic back.
 * "lid" : Send lid status back over mqtt_control_out_topic.
 *         Lid open   -> lidOpen
 *         Lid closed -> lidClosed
 * 
 */
void mqttCallback(char* topic, byte* payload, unsigned int length) {
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("] ");
  for (int i = 0; i < length; i++) {
    Serial.print((char)payload[i]);
  }
  Serial.println();

  const char* mqttTopic = config["mqtt_topic"];
  const char* mqttControlInTopic = config["mqtt_control_in_topic"];
  const char* mqttControlOutTopic = config["mqtt_control_out_topic"];

  // If message arrived in loveMessage topic, we try to parse the message
  if(strcmp(topic, mqttTopic) == 0) {
    // Use const char* cast, because otherwise deserializeJson modifies the buffer
    DeserializationError err = deserializeJson(messagePayload, (const char*)payload, length);
    if (err) {
      Serial.print("Invalid json ");
      Serial.println(err.c_str());
      return;
    }
  
    //Save payload
    savePayloadToStorage(payload, length);
  
    //Callback
    onLoveMessage(false);

    mqttClient->publish(mqttControlOutTopic, "messageReceived");
  }

  //If message arrived in control topic, we execute the control command
  else if(strcmp(topic, mqttControlInTopic) == 0) {
    char command[length + 1] = "";
    strncpy(command, (const char*)payload, length);
    command[length] = '\0';
    if(strcmp(command, "ping") == 0) {
      Serial.println("Received 'ping' command");
      mqttClient->publish(mqttControlOutTopic, "pong");
    }
    else if(strcmp(command, "lid") == 0) {
      Serial.println("Received 'lid' command");
      if(isLidClosed()) {
        mqttClient->publish(mqttControlOutTopic, "lidClosed");
      }
      else {
        mqttClient->publish(mqttControlOutTopic, "lidOpen");
      }
    }
  }
}

/*
 * Connect to MQTT server.
 */
void mqttReconnect() {
  onReconnecting();
  
  // Get config
  // ClientId has to bee unique, otherwhise hiveMq disconnects client
  const char* mqttClientId = "ESP8266Client - MyClient 2";
  const char* mqttUser = config["mqtt_user"];
  const char* mqttPass = config["mqtt_pass"];
  const char* mqttTopic = config["mqtt_topic"];
  const char* mqttControlInTopic = config["mqtt_control_in_topic"];
  
  // Loop until we are connected
  while (!mqttClient->connected()) {
    Serial.println("Mqtt trying to connect");

    // Connect
    if (mqttClient->connect(mqttClientId, mqttUser, mqttPass)) {
      Serial.println("Mqtt connected");
      onConnected();
      mqttClient->subscribe(mqttTopic);
      mqttClient->subscribe(mqttControlInTopic);
    } else {
      Serial.print("Mqtt connection failed. state: ");
      Serial.println(mqttClient->state());
      Serial.println("Mqtt waiting");
      delay(5000);
    }
  }
}

/*
 * Send lovebox command over mqtt_control_out_topic topic
 */
void loveBoxSendCommand(const char* command) {
  const char* mqttControlOutTopic = config["mqtt_control_out_topic"];
   mqttClient->publish(mqttControlOutTopic, command);
}
