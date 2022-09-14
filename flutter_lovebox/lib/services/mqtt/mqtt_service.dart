import 'dart:async';

import 'package:logger/logger.dart';
import 'package:lovebox/services/mqtt/mqtt_config.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;

class MqttService {
  MqttService()
      : _logger = Logger(),
        _connectionStateStreamController = StreamController.broadcast(),
        _incomingMessageStreamController = StreamController.broadcast();

  final Logger _logger;
  final StreamController<MqttConnectionState> _connectionStateStreamController;
  final StreamController<MqttIncomingMessage> _incomingMessageStreamController;

  static Future<bool> testConnect(MqttConfig config) async {
    Logger logger = Logger();
    MqttClient mqttClient = config.client;
    mqttClient.logging(on: true);
    try {
      MqttClientConnectionStatus? status =
          await mqttClient.connect(config.username, config.password);
      if (status != null &&
          status.state == mqtt.MqttConnectionState.connected) {
        mqttClient.disconnect();
        return true;
      }
      return false;
    } on Exception catch (e, t) {
      logger.e("", e, t);
      return false;
    }
  }

  MqttClient? _client;

  Stream<MqttConnectionState> connectionState() {
    return _connectionStateStreamController.stream;
  }

  Stream<MqttIncomingMessage> incomingMessages() {
    return _incomingMessageStreamController.stream;
  }

  Future<void> connect() async {
    MqttConfig config = await MqttConfig.buildClientFromConfig();
    _client = config.client;
    _client!.logging(on: true);
    _client!.onConnected = _onConnectedIntern;
    _client!.onDisconnected = _onDisconnectedIntern;

    MqttClientConnectionStatus? status =
        await _client!.connect(config.username, config.password);
    if (status == null || status.state != MqttConnectionState.connected) {
      throw Exception("Failed to connect mqtt client");
    }
  }

  Future<void> disconnect() async {
    if (_client != null &&
        _client!.connectionStatus!.state ==
            mqtt.MqttConnectionState.connected) {
      _client!.disconnect();
    }
  }

  subscribe(String channel) {
    if (_client == null ||
        _client!.connectionStatus!.state !=
            mqtt.MqttConnectionState.connected) {
      return;
    }
    _client!.subscribe(channel, MqttQos.atMostOnce);
  }

  bool isConnected() {
    return _client!.connectionStatus!.state ==
        mqtt.MqttConnectionState.connected;
  }

  sendMessage(String topic, String message) {
    if (_client == null ||
        _client!.connectionStatus!.state !=
            mqtt.MqttConnectionState.connected) {
      return;
    }

    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client!.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  }

  /// Internal mqtt callback onConnected
  _onConnectedIntern() {
    _logger.d("Client connected");
    _connectionStateStreamController.add(MqttConnectionState.connected);
    _client!.updates!.listen(_onUpdateIntern);
  }

  /// Internal mqtt callback onDisconnected
  _onDisconnectedIntern() {
    _logger.d("Client disconnected");
    _connectionStateStreamController.add(MqttConnectionState.disconnected);
  }

  /// Internal mqtt callback onUpdate
  _onUpdateIntern(List<MqttReceivedMessage<MqttMessage>> eventList) {
    _logger.d("_onUpdateIntern received ${eventList.length} message(s)");
    for (var message in eventList) {
      if (message.payload is MqttPublishMessage) {
        var publishMessage = message.payload as MqttPublishMessage;
        String payload = MqttPublishPayload.bytesToStringAsString(
            publishMessage.payload.message);
        _incomingMessageStreamController
            .add(MqttIncomingMessage(message.topic, payload));
      }
    }
  }
}

class MqttIncomingMessage {
  final String topic;
  final String message;

  MqttIncomingMessage(this.topic, this.message);

  @override
  String toString() {
    return 'MqttIncomingMessage{topic: $topic, message: $message}';
  }
}
