import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:lovebox/pages/home/home_page.dart';
import 'package:lovebox/pages/mqtt_settings_page.dart';
import 'package:lovebox/services/mqtt/mqtt_config.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  MainPageState createState() => MainPageState();
}

//Check if a configuration is available and load either settings page or home page
class MainPageState extends State<MainPage> {
  late Future<bool> _configFuture;

  @override
  void initState() {
    _configFuture = MqttConfig.hasValidConfig();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _configFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        } else {
          //Hide splash screen
          FlutterNativeSplash.remove();
          if (snapshot.hasData && snapshot.data!) {
            return const HomePage();
          } else {
            return const MqttSettingsPage();
          }
        }
      },
    );
  }
}
