import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lovebox/services/lovebox/lovebox_service.dart';
import 'package:visibility_aware_state/visibility_aware_state.dart';

class LoveBoxConnectionStatus extends StatefulWidget {
  final LoveBox loveBox;

  const LoveBoxConnectionStatus({required this.loveBox, Key? key})
      : super(key: key);

  @override
  LoveBoxConnectionStateStatus createState() => LoveBoxConnectionStateStatus();
}

class LoveBoxConnectionStateStatus
    extends VisibilityAwareState<LoveBoxConnectionStatus> {
  late StreamSubscription<LoveBoxControlMessage> _subscription;
  Timer? _timer;
  bool _connected = false;

  @override
  void initState() {
    /*subscription = MqttService.instance.controlMessages().listen((event) {
      if (event == "pong") {
        setState(() {
          _connected = true;
          //Restart timer
        });
      }
    });*/
    _subscription = widget.loveBox.watchControlMessages().listen((message) {
      if (message == LoveBoxControlMessage.pong) {
        setState(() {
          _connected = true;
          //Restart timer
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer!.cancel();
    }
    _subscription.cancel();
    super.dispose();
  }

  @override
  void onVisibilityChanged(WidgetVisibility visibility) {
    if (visibility == WidgetVisibility.VISIBLE) {
      print("Visible");
      _refresh();
      _timer = Timer.periodic(
        const Duration(seconds: 30),
        (Timer timer) {
          //_refresh();
        },
      );
    } else if (visibility == WidgetVisibility.INVISIBLE) {
      print("Invisible");
      if (_timer != null) {
        _timer!.cancel();
      }
    }
    super.onVisibilityChanged(visibility);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: "LoveBox responded to ping",
      onPressed: () {
        _refresh();
      },
      icon: _connected
          ? const Icon(
              //Icons.favorite,
              Icons.signal_cellular_4_bar,
            )
          : const Icon(
              //Icons.favorite_border
              Icons.signal_cellular_off),
    );
  }

  _refresh() {
    print("refresh");
    setState(() {
      _connected = false;
    });
    if (widget.loveBox.isConnected()) {
      widget.loveBox.sendControlMessage(LoveBoxControlMessage.ping);
    }
    /*if (MqttService.instance.isConnected()) {
      MqttService.instance.sendControlMessage("ping");
    }*/
  }
}
