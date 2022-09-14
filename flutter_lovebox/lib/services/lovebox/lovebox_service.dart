import 'package:lovebox/model/love_box_message.dart';

enum LoveBoxState { connecting, connected, error }

enum LoveBoxControlMessage {
  unknown,
  ping,
  pong,
  lidOpen,
  lidClosed,
  lidStatus,
  messageReceived,
}

abstract class LoveBox {
  Stream<LoveBoxState> watchConnectionState();
  Stream<LoveBoxControlMessage> watchControlMessages();
  bool isConnected();
  Future<void> connect();
  Future<void> disconnect();
  Future<void> sendMessage(LoveBoxMessage loveBoxMessage);
  Future<void> sendControlMessage(LoveBoxControlMessage loveBoxControlMessage);
}
