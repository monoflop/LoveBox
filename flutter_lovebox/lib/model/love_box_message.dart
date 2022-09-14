import 'package:json_annotation/json_annotation.dart';

part 'love_box_message.g.dart';

//flutter pub run build_runner build
@JsonSerializable(explicitToJson: true)
class LoveBoxMessage {
  static const int typeText = 1;
  static const int typeImage = 2;

  static const int blinkingDisabled = 0;
  static const int blinkingEnabled = 1;

  final int type;
  final int blinking;
  final String payload;

  LoveBoxMessage(this.type, this.blinking, this.payload);
  LoveBoxMessage.text(String text, {blinking = blinkingDisabled})
      : this(typeText, blinking, text);
  LoveBoxMessage.image(String base64Image, {blinking = blinkingDisabled})
      : this(typeImage, blinking, base64Image);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoveBoxMessage &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          blinking == other.blinking &&
          payload == other.payload;

  @override
  int get hashCode => type.hashCode ^ blinking.hashCode ^ payload.hashCode;

  factory LoveBoxMessage.fromJson(Map<String, dynamic> json) =>
      _$LoveBoxMessageFromJson(json);
  Map<String, dynamic> toJson() => _$LoveBoxMessageToJson(this);
}
