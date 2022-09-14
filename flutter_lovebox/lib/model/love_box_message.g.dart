// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'love_box_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoveBoxMessage _$LoveBoxMessageFromJson(Map<String, dynamic> json) =>
    LoveBoxMessage(
      json['type'] as int,
      json['blinking'] as int,
      json['payload'] as String,
    );

Map<String, dynamic> _$LoveBoxMessageToJson(LoveBoxMessage instance) =>
    <String, dynamic>{
      'type': instance.type,
      'blinking': instance.blinking,
      'payload': instance.payload,
    };
