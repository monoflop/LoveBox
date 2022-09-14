import 'dart:convert';
import 'dart:typed_data';

import 'package:binary/binary.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;

class ImageEncoder {
  static const deviceScreenWidth = 128;
  static const deviceScreenHeight = 64;
  static const deviceVideoBuffer = 1024;
  static const colorWhite = 255;
  static const colorBlack = 0;

  static String encodeImage(image_lib.Image image) {
    Uint8List encodedList = Uint8List(deviceVideoBuffer);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        //Calculate target byte
        int byteIndex = (y * deviceScreenWidth + x) ~/ 8;

        //Calculate target bit
        int bitIndex = ((y * deviceScreenWidth + x) % 8).toInt();
        bitIndex = 7 - bitIndex;

        bool whitePixel = Color(image.getPixel(x, y)) == Colors.white;
        Uint8 byte = Uint8(encodedList.elementAt(byteIndex));
        if (whitePixel) {
          byte = byte.setBit(bitIndex);
        } else {
          byte = byte.clearBit(bitIndex);
        }

        encodedList[byteIndex] = byte.value;
      }
    }
    String base64 = base64Encode(encodedList);
    //return "$base64==";
    return base64;
  }

  static image_lib.Image decodeImage(String base64) {
    image_lib.Image image =
        image_lib.Image(deviceScreenWidth, deviceScreenHeight);
    image = image.fill(Colors.black.value);

    Uint8List encodedList = base64Decode(base64);
    if (encodedList.length != deviceVideoBuffer) {
      throw Exception("Invalid buffer size");
    }

    for (int byteIndex = 0; byteIndex < encodedList.length; byteIndex++) {
      Uint8 byte = Uint8(encodedList.elementAt(byteIndex));
      for (int bitIndex = 0; bitIndex < 8; bitIndex++) {
        int pixelIndex = byteIndex * 8 + bitIndex;
        int imageX = pixelIndex % deviceScreenWidth;
        int imageY = pixelIndex ~/ deviceScreenWidth;
        //print("index $pixelIndex x: $imageX y: $imageY");
        if (byte.isSet(7 - bitIndex)) {
          image.setPixel(imageX, imageY, Colors.white.value);
        }
      }
    }

    return image;
  }
}
