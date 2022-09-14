import 'package:flutter/material.dart';
import 'package:lovebox/constants/constants.dart';
import 'package:lovebox/helper/snackbar_helper.dart';
import 'package:lovebox/model/love_box_message.dart';
import 'package:lovebox/services/lovebox/lovebox_service.dart';
import 'package:lovebox/services/storage_service.dart';
import 'package:lovebox/wigets/message_status_dialog.dart';

class TextMessagePage extends StatelessWidget {
  TextMessagePage({required this.loveBox, Key? key})
      : _formKey = GlobalKey<FormState>(),
        _editingController = TextEditingController(),
        super(key: key);

  final GlobalKey<FormState> _formKey;
  final LoveBox loveBox;
  final TextEditingController _editingController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(uiDefaultPadding),
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: maxContentWidth,
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _editingController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.sentences,
                  onFieldSubmitted: (String string) {
                    _submit(context);
                  },
                  decoration: InputDecoration(
                    hintText: "Love message",
                    suffixIcon: IconButton(
                      onPressed: _editingController.clear,
                      icon: const Icon(Icons.clear),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: uiDefaultPadding,
              ),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                        onPressed: () {
                          _editingController.text += "\u0001";
                        },
                        child: const Text("\u263A")),
                  ),
                  const SizedBox(
                    width: uiDefaultPadding,
                  ),
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                        onPressed: () {
                          _editingController.text += "\u0002";
                        },
                        child: const Text("\u263B")),
                  ),
                  const SizedBox(
                    width: uiDefaultPadding,
                  ),
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                        onPressed: () {
                          _editingController.text += "\u2665";
                        },
                        child: const Text("\u2665")),
                  )
                ],
              ),
              const SizedBox(
                height: uiDefaultPadding,
              ),
              ElevatedButton(
                  onPressed: () {
                    _submit(context);
                  },
                  child: const Center(child: Text("SEND"))),
              OutlinedButton(
                  onPressed: () async {
                    await StorageService.instance.add(LoveBoxMessage.text(
                      _editingController.text,
                    ));

                    SnackBarHelper.showInfoMessage(context, "Message saved");
                  },
                  child: const Center(
                    child: Text("SAVE"),
                  ))
            ],
          ),
        ),
      ),
    );
  }

  _submit(BuildContext context) {
    MessageStatusDialog.showStatusDialog(
        context,
        loveBox,
        LoveBoxMessage.text(
          _editingController.text,
        ));
  }
}
