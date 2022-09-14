import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MqttConfig {
  static const clientName = "LoveBox-App";

  static const _prefKeyUrl = "prefKeyUrl";
  static const _prefKeyPort = "prefKeyPort";
  static const _prefKeyUsername = "prefKeyUsername";
  static const _prefKeyPassword = "prefKeyPassword";
  static const _prefKeyAutoReconnect = "prefKeyAutoReconnect";

  final MqttClient client;
  final String username;
  final String password;

  MqttConfig(this.client, this.username, this.password);

  static MqttConfig buildClient(
      String url, int port, String username, String password,
      {bool autoReconnect = true}) {
    MqttServerClient serverClient =
        MqttServerClient.withPort(url, clientName, port);
    serverClient.secure = true;
    serverClient.securityContext = SecurityContext.defaultContext;
    serverClient.keepAlivePeriod = 30;
    serverClient.autoReconnect = autoReconnect;
    serverClient.resubscribeOnAutoReconnect = false;
    return MqttConfig(serverClient, username, password);
  }

  static Future<MqttConfig> buildClientFromConfig() async {
    var preferences = await SharedPreferences.getInstance();
    MqttServerClient serverClient = MqttServerClient.withPort(
        preferences.getString(_prefKeyUrl)!,
        clientName,
        preferences.getInt(_prefKeyPort)!);
    serverClient.secure = true;
    serverClient.securityContext = SecurityContext.defaultContext;
    serverClient.keepAlivePeriod = 30;
    serverClient.autoReconnect = preferences.getBool(_prefKeyAutoReconnect)!;
    serverClient.resubscribeOnAutoReconnect = false;
    return MqttConfig(serverClient, preferences.getString(_prefKeyUsername)!,
        preferences.getString(_prefKeyPassword)!);
  }

  static Future<void> saveConfig(
      String url, int port, String username, String password,
      {bool autoReconnect = true}) async {
    var preferences = await SharedPreferences.getInstance();
    preferences.setString(_prefKeyUrl, url);
    preferences.setInt(_prefKeyPort, port);
    preferences.setString(_prefKeyUsername, username);
    preferences.setString(_prefKeyPassword, password);
    preferences.setBool(_prefKeyAutoReconnect, autoReconnect);
  }

  static Future<bool> hasValidConfig() async {
    var preferences = await SharedPreferences.getInstance();
    return preferences.containsKey(_prefKeyUrl) &&
        preferences.containsKey(_prefKeyPort) &&
        preferences.containsKey(_prefKeyUsername) &&
        preferences.containsKey(_prefKeyPassword) &&
        preferences.containsKey(_prefKeyAutoReconnect);
  }
}
