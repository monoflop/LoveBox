import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lovebox/services/lovebox/lovebox_service.dart';
import 'package:visibility_aware_state/visibility_aware_state.dart';

class LidStatus extends StatefulWidget {
  final LoveBox loveBox;

  const LidStatus({required this.loveBox, Key? key}) : super(key: key);

  @override
  LidStatusState createState() => LidStatusState();
}

class LidStatusState extends VisibilityAwareState<LidStatus> {
  late StreamSubscription<LoveBoxControlMessage> _subscription;
  bool _lidOpen = false;

  @override
  void initState() {
    _subscription = widget.loveBox.watchControlMessages().listen((message) {
      if (message == LoveBoxControlMessage.lidOpen) {
        setState(() {
          _lidOpen = true;
        });
      } else if (message == LoveBoxControlMessage.lidClosed) {
        setState(() {
          _lidOpen = false;
        });
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  void onVisibilityChanged(WidgetVisibility visibility) {
    if (visibility == WidgetVisibility.VISIBLE) {
      _refresh();
    }
    super.onVisibilityChanged(visibility);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: "Lid Open / Closed",
      onPressed: () {
        _refresh();
      },
      icon: _lidOpen
          ? const Icon(
              Icons.visibility,
            )
          : const Icon(Icons.visibility_off),
    );
  }

  _refresh() {
    widget.loveBox.sendControlMessage(LoveBoxControlMessage.lidStatus);
  }
}
