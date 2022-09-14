import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lovebox/constants/constants.dart';
import 'package:lovebox/helper/snackbar_helper.dart';
import 'package:lovebox/pages/home/home_page.dart';
import 'package:lovebox/services/mqtt/mqtt_config.dart';
import 'package:lovebox/services/mqtt/mqtt_service.dart';
import 'package:lovebox/wigets/password_text_form_field.dart';

class MqttSettingsPage extends StatefulWidget {
  const MqttSettingsPage({Key? key}) : super(key: key);

  @override
  MqttSettingsPageState createState() => MqttSettingsPageState();
}

class MqttSettingsPageState extends State<MqttSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  String? _url;
  int? _port;
  String? _username;
  String? _password;

  bool _testRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            "MQTT broker setup",
          ),
        ),
        //Required data: url, port, username, password
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            if (_testRunning)
              LinearProgressIndicator(
                color: Colors.red,
                backgroundColor: Colors.redAccent.withOpacity(0.5),
              ),
            Expanded(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(uiDefaultPadding),
                  child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                          width: maxContentWidth,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                TextFormField(
                                  textInputAction: TextInputAction.next,
                                  keyboardType: TextInputType.url,
                                  maxLines: 1,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: "URL",
                                  ),
                                  // The validator receives the text that the user has entered.
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter URL";
                                    }

                                    Uri? uri = Uri.tryParse(value);
                                    if (uri == null) {
                                      return "Please enter valid URL";
                                    }

                                    return null;
                                  },
                                  onSaved: (value) {
                                    _url = value!;
                                  },
                                ),
                                const SizedBox(
                                  height: uiDefaultPadding,
                                ),
                                TextFormField(
                                  textInputAction: TextInputAction.next,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  maxLength: 5,
                                  maxLines: 1,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: "Port (TLS)",
                                  ),
                                  // The validator receives the text that the user has entered.
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter port";
                                    }

                                    int? port = int.tryParse(value);
                                    if (port == null ||
                                        port < 1 ||
                                        port > 65535) {
                                      return "Please enter valid port 1 - 65535";
                                    }

                                    return null;
                                  },
                                  onSaved: (value) {
                                    _port = int.parse(value!);
                                  },
                                ),
                                const SizedBox(
                                  height: uiDefaultPadding,
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        textInputAction: TextInputAction.next,
                                        maxLines: 1,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: "Username",
                                        ),
                                        // The validator receives the text that the user has entered.
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return "Please enter username";
                                          }
                                          return null;
                                        },
                                        onSaved: (value) {
                                          _username = value!;
                                        },
                                      ),
                                    ),
                                    const SizedBox(
                                      width: uiDefaultPadding,
                                    ),
                                    Expanded(
                                      child: PasswordTextFormField(
                                          onSaved: (value) {
                                        _password = value!;
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: uiDefaultPadding,
                                ),
                                OutlinedButton(
                                    onPressed: _testRunning
                                        ? null
                                        : () {
                                            FocusScope.of(context).unfocus();
                                            _testSettings();
                                          },
                                    child: const Center(
                                      child: Text("TEST"),
                                    )),
                                ElevatedButton(
                                  onPressed: _testRunning
                                      ? null
                                      : () {
                                          FocusScope.of(context).unfocus();
                                          _saveSettings();
                                        },
                                  child: const Center(child: Text("SAVE")),
                                ),
                              ],
                            ),
                          )))),
            ),
          ],
        ));
  }

  _testSettings() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      //Indicate ui that the test starts
      setState(() {
        _testRunning = true;
      });

      //Run connection test
      MqttService.testConnect(MqttConfig.buildClient(
              _url!, _port!, _username!, _password!,
              autoReconnect: false))
          .then((value) {
        setState(() {
          _testRunning = false;
        });
        if (value) {
          SnackBarHelper.showSuccessMessage(context, "Connection successful");
        } else {
          SnackBarHelper.showErrorMessage(context, "Connection failed");
        }
      }).onError((error, stackTrace) {
        setState(() {
          _testRunning = false;
        });

        SnackBarHelper.showErrorMessage(context, "Connection failed");
      });
    }
  }

  _saveSettings() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      //Save config and navigate to home page
      MqttConfig.saveConfig(_url!, _port!, _username!, _password!,
              autoReconnect: true)
          .then((value) => Navigator.of(context)
                  .pushReplacement(MaterialPageRoute(builder: (context) {
                return const HomePage();
              })));
    }
  }
}
