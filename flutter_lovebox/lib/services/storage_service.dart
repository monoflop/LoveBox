import 'dart:async';
import 'dart:convert';

import 'package:lovebox/model/love_box_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _preferenceKey = "loveMessageList";
  static final StorageService instance = StorageService._privateConstructor();

  final StreamController<void> _storageUpdateStreamController =
      StreamController.broadcast();

  StorageService._privateConstructor();

  Stream<void> storageUpdate() {
    return _storageUpdateStreamController.stream;
  }

  Future<List<LoveBoxMessage>> load() async {
    var preferences = await SharedPreferences.getInstance();
    var list = preferences.getStringList(_preferenceKey);
    if (list == null) {
      return [];
    }

    return List<LoveBoxMessage>.from(
        list.map((json) => LoveBoxMessage.fromJson(jsonDecode(json))));
  }

  add(LoveBoxMessage loveBoxMessage) async {
    List<LoveBoxMessage> list = await load();
    list.insert(0, loveBoxMessage);
    _save(list);
    _storageUpdateStreamController.add(null);
  }

  remove(LoveBoxMessage loveBoxMessage) async {
    List<LoveBoxMessage> list = await load();
    list.remove(loveBoxMessage);
    _save(list);
    _storageUpdateStreamController.add(null);
  }

  _save(List<LoveBoxMessage> list) async {
    List<String> serializedList =
        List<String>.from(list.map((message) => jsonEncode(message.toJson())));

    var preferences = await SharedPreferences.getInstance();
    preferences.setStringList(_preferenceKey, serializedList);
  }
}
