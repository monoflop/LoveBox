import 'package:flutter/material.dart';
import 'package:lovebox/constants/constants.dart';
import 'package:lovebox/model/love_box_message.dart';
import 'package:lovebox/services/lovebox/lovebox_exception.dart';
import 'package:lovebox/services/lovebox/lovebox_service.dart';

class MessageStatusDialog extends StatefulWidget {
  final LoveBox loveBox;
  final LoveBoxMessage loveBoxMessage;

  const MessageStatusDialog(
      {required this.loveBox, required this.loveBoxMessage, Key? key})
      : super(key: key);

  @override
  MessageStatusDialogState createState() => MessageStatusDialogState();

  static void showStatusDialog(
      BuildContext context, LoveBox loveBox, LoveBoxMessage loveBoxMessage) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return MessageStatusDialog(
            loveBox: loveBox, loveBoxMessage: loveBoxMessage);
      },
    );
  }
}

class MessageStatusDialogState extends State<MessageStatusDialog> {
  late Future<void> _messageFuture;

  @override
  void initState() {
    _messageFuture = widget.loveBox.sendMessage(widget.loveBoxMessage);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
        future: _messageFuture,
        builder: (buildContext, snapshot) {
          List<Widget> list = [];
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              LoveBoxException exception = LoveBoxException("Unknown");
              if (snapshot.error! is LoveBoxException) {
                exception = snapshot.error! as LoveBoxException;
              }
              list = _buildError(exception);
            } else {
              list = _buildSuccess();
            }
          } else {
            list = _buildLoading();
          }

          return AlertDialog(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: list,
            ),
          );
        });
  }

  List<Widget> _buildLoading() {
    return const [
      SizedBox(
        height: uiDefaultPadding,
      ),
      CircularProgressIndicator(),
      SizedBox(
        height: uiDefaultPadding,
      ),
      Text(
        "Loading...",
        style: TextStyle(fontSize: 14),
      ),
      SizedBox(
        height: uiDefaultPadding,
      ),
    ];
  }

  List<Widget> _buildSuccess() {
    return [
      const SizedBox(
        height: uiDefaultPadding,
      ),
      const Text(
        "Success!",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      const SizedBox(
        height: uiDefaultPadding / 2,
      ),
      const Text(
        "LoveBox has received the message.",
        style: TextStyle(fontSize: 14),
      ),
      const SizedBox(
        height: uiDefaultPadding,
      ),
      TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("OK")),
    ];
  }

  List<Widget> _buildError(LoveBoxException exception) {
    return [
      const SizedBox(
        height: uiDefaultPadding,
      ),
      const Text(
        "Error!",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      const SizedBox(
        height: uiDefaultPadding / 2,
      ),
      Text(
        exception.message,
        style: const TextStyle(fontSize: 14),
      ),
      const SizedBox(
        height: uiDefaultPadding,
      ),
      TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("OK")),
    ];
  }
}
