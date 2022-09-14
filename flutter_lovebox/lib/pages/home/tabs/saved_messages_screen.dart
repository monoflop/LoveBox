import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;
import 'package:lovebox/constants/constants.dart';
import 'package:lovebox/helper/image_encoder.dart';
import 'package:lovebox/helper/snackbar_helper.dart';
import 'package:lovebox/model/love_box_message.dart';
import 'package:lovebox/services/lovebox/lovebox_service.dart';
import 'package:lovebox/services/storage_service.dart';
import 'package:lovebox/wigets/divider.dart';
import 'package:lovebox/wigets/message_status_dialog.dart';

class SavedMessagesPage extends StatefulWidget {
  final LoveBox loveBox;

  const SavedMessagesPage({required this.loveBox, Key? key}) : super(key: key);

  @override
  SavedMessagesPageState createState() => SavedMessagesPageState();
}

class SavedMessagesPageState extends State<SavedMessagesPage> {
  late StreamSubscription _subscription;

  @override
  void initState() {
    _subscription = StorageService.instance.storageUpdate().listen((event) {
      setState(() {
        //Refresh page
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LoveBoxMessage>>(
        future: StorageService.instance.load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              List<LoveBoxMessage> list = snapshot.data!;
              if (list.isNotEmpty) {
                return _buildData(list);
              } else {
                return _buildEmpty();
              }
            } else if (snapshot.hasError) {
              _buildError();
            }
          }
          return Container();
        });
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(uiDefaultPadding),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.save,
              color: Colors.grey,
              size: 80.0,
            ),
            SizedBox(
              height: uiDefaultPadding,
            ),
            Text(
              "Your saved messages appear here",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return const Center(
      child: Text("Error loading"),
    );
  }

  Widget _buildData(List<LoveBoxMessage> list) {
    return ListView.separated(
      padding: const EdgeInsets.all(uiDefaultPadding),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Dismissible(
            key: Key(jsonEncode(item.toJson())),
            direction: DismissDirection.startToEnd,
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: Theme.of(context).primaryColor,
                ),
                Padding(
                  padding: const EdgeInsets.all(uiDefaultPadding),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: const [
                        Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: uiDefaultPadding,
                        ),
                        Text(
                          "Remove",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
            onDismissed: (direction) async {
              await StorageService.instance.remove(list.elementAt(index));
              if (!mounted) {
                return;
              }
              SnackBarHelper.showInfoMessage(context, "Message deleted");
            },
            child: SavedMessage(widget.loveBox, item));
      },
      separatorBuilder: (context, index) => const HorizontalDivider(),
    );
  }
}

class SavedMessage extends StatelessWidget {
  final LoveBox _loveBox;
  final LoveBoxMessage _loveBoxMessage;

  const SavedMessage(this._loveBox, this._loveBoxMessage, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(uiDefaultPadding),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _loveBoxMessage.type == LoveBoxMessage.typeText
              ? const Icon(Icons.text_fields)
              : MessageImage(payload: _loveBoxMessage.payload),
          const SizedBox(
            width: uiDefaultPadding,
          ),
          _loveBoxMessage.type == LoveBoxMessage.typeText
              ? Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _loveBoxMessage.payload,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(
                        height: 4.0,
                      ),
                      const Text(
                        "Text message",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Expanded(child: Container()),
          const SizedBox(
            width: uiDefaultPadding,
          ),
          IconButton(
            icon: const Icon(
              Icons.send,
              color: Colors.red,
            ),
            tooltip: "Send message",
            onPressed: () {
              MessageStatusDialog.showStatusDialog(
                  context, _loveBox, _loveBoxMessage);
            },
          )
        ],
      ),
    );
  }
}

class MessageImage extends StatefulWidget {
  final String payload;

  const MessageImage({required this.payload, Key? key}) : super(key: key);

  @override
  State<MessageImage> createState() => _MessageImageState();
}

class _MessageImageState extends State<MessageImage> {
  late Future<Uint8List> imageBytesFuture;

  @override
  void initState() {
    imageBytesFuture = Future(() async {
      image_lib.Image image = ImageEncoder.decodeImage(widget.payload);
      return Future.value(Uint8List.fromList(image_lib.encodeBmp(image)));
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: imageBytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasData) {
          return Image.memory(
            snapshot.requireData,
            isAntiAlias: false,
            filterQuality: FilterQuality.none,
          );
        }
        return Container();
      },
    );
  }
}
