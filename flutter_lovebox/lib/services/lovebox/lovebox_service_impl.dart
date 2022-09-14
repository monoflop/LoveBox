import 'dart:async';
import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:lovebox/helper/extended_ascii_helper.dart';
import 'package:lovebox/model/love_box_message.dart';
import 'package:lovebox/services/lovebox/lovebox_exception.dart';
import 'package:lovebox/services/lovebox/lovebox_service.dart';
import 'package:lovebox/services/mqtt/mqtt_service.dart';
import 'package:mqtt_client/mqtt_client.dart';

class LoveBoxImpl extends LoveBox {
  static const String messageChannel = "loveMessageTopic";
  static const String controlOutChannel = "controlOutMessageTopic";
  static const String controlInChannel = "controlInMessageTopic";

  LoveBoxImpl(this._mqttService)
      : _logger = Logger(),
        _loveBoxStateStreamController = StreamController.broadcast(),
        _controlMessageStreamController = StreamController.broadcast();

  final Logger _logger;
  final MqttService _mqttService;
  final StreamController<LoveBoxState> _loveBoxStateStreamController;
  final StreamController<LoveBoxControlMessage> _controlMessageStreamController;

  StreamSubscription<MqttConnectionState>? _mqttStateSubscription;
  StreamSubscription<MqttIncomingMessage>? _mqttIncomingMessageSubscription;

  _onMqttConnectionStateChange(MqttConnectionState state) {
    //Emit connection state as LoveBoxState messages
    _logger.d("Connection state change from mqtt $state");
    if (state == MqttConnectionState.connecting) {
      _loveBoxStateStreamController.add(LoveBoxState.connecting);
    } else if (state == MqttConnectionState.connected) {
      _loveBoxStateStreamController.add(LoveBoxState.connected);
    } else if (state == MqttConnectionState.disconnected ||
        state == MqttConnectionState.faulted) {
      _loveBoxStateStreamController.add(LoveBoxState.error);
    }
  }

  _onMqttIncomingMessage(MqttIncomingMessage mqttIncomingMessage) {
    _logger.d("Received message $mqttIncomingMessage");
    if (mqttIncomingMessage.topic == controlOutChannel) {
      LoveBoxControlMessage controlMessage;
      try {
        controlMessage =
            LoveBoxControlMessage.values.byName(mqttIncomingMessage.message);
      } on ArgumentError catch (_) {
        controlMessage = LoveBoxControlMessage.unknown;
      }
      _controlMessageStreamController.add(controlMessage);
    }
  }

  @override
  Future<void> connect() async {
    //Cancel subscription if already in use
    _mqttStateSubscription?.cancel();
    _mqttIncomingMessageSubscription?.cancel();

    //Subscribe to connection state changes and incoming messages
    _mqttStateSubscription =
        _mqttService.connectionState().listen(_onMqttConnectionStateChange);
    _mqttIncomingMessageSubscription =
        _mqttService.incomingMessages().listen(_onMqttIncomingMessage);

    try {
      //Connect
      await _mqttService.connect();

      //Subscribe
      _mqttService.subscribe(controlOutChannel);
    } on Exception catch (e, t) {
      _logger.e("", e, t);
      _loveBoxStateStreamController.add(LoveBoxState.error);
    }
  }

  @override
  Future<void> disconnect() async {
    _mqttStateSubscription?.cancel();
    _mqttIncomingMessageSubscription?.cancel();

    try {
      //Disconnect
      _mqttService.disconnect();
    } on Exception catch (e, t) {
      _logger.e("", e, t);
      _loveBoxStateStreamController.add(LoveBoxState.error);
    }
  }

  @override
  Future<void> sendControlMessage(
      LoveBoxControlMessage loveBoxControlMessage) async {
    _mqttService.sendMessage(controlInChannel, loveBoxControlMessage.name);
  }

  @override
  Future<void> sendMessage(LoveBoxMessage loveBoxMessage) async {
    //For text messages first try to encode special characters
    if (loveBoxMessage.type == LoveBoxMessage.typeText) {
      loveBoxMessage = LoveBoxMessage(
          loveBoxMessage.type,
          loveBoxMessage.blinking,
          ExtendedAsciiHelper.utfToCp437(loveBoxMessage.payload));
    }

    String message = jsonEncode(loveBoxMessage.toJson());
    _mqttService.sendMessage(messageChannel, message);

    //Wait for loveBox response
    await for (LoveBoxControlMessage message in watchControlMessages().timeout(
        const Duration(seconds: 5),
        onTimeout: (sink) => sink.close())) {
      if (message == LoveBoxControlMessage.messageReceived) {
        return;
      }
    }
    throw LoveBoxException("Timeout: LoveBox did not respond");
  }

  @override
  Stream<LoveBoxState> watchConnectionState() {
    return _loveBoxStateStreamController.stream;
  }

  @override
  Stream<LoveBoxControlMessage> watchControlMessages() {
    return _controlMessageStreamController.stream;
  }

  @override
  bool isConnected() {
    return _mqttService.isConnected();
  }
}
