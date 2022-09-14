import 'package:flutter/material.dart';
import 'package:lovebox/constants/constants.dart';
import 'package:lovebox/pages/home/tabs/image_message_screen.dart';
import 'package:lovebox/pages/home/tabs/saved_messages_screen.dart';
import 'package:lovebox/pages/home/tabs/text_message_screen.dart';
import 'package:lovebox/services/lovebox/lovebox_service.dart';
import 'package:lovebox/services/lovebox/lovebox_service_impl.dart';
import 'package:lovebox/services/mqtt/mqtt_service.dart';
import 'package:lovebox/wigets/connection_status.dart';
import 'package:lovebox/wigets/fade_through_indexed_stack.dart';
import 'package:lovebox/wigets/lid_status.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late LoveBox _loveBox;

  //Widget of target page
  late List<Widget> _pages;

  //Current page
  late int _selectedPage;

  @override
  void initState() {
    _loveBox = LoveBoxImpl(MqttService());
    _loveBox.connect();

    //MqttService.instance.connect();

    //Default selected page
    _selectedPage = 0;

    //Only init first page
    //Second page is sizedBox -> indicates unloaded page
    _pages = [
      TextMessagePage(
        loveBox: _loveBox,
      ),
      const SizedBox(),
      const SizedBox(),
    ];

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "LoveBox",
          style: TextStyle(fontFamily: "Love"),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: uiDefaultPadding),
            child: Center(
              child: LidStatus(
                loveBox: _loveBox,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: uiDefaultPadding),
            child: Center(
              child: LoveBoxConnectionStatus(
                loveBox: _loveBox,
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<LoveBoxState>(
              stream: _loveBox.watchConnectionState(),
              builder:
                  (BuildContext context, AsyncSnapshot<LoveBoxState> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildMqttLoading();
                }

                if (snapshot.hasData) {
                  if (snapshot.data! == LoveBoxState.error) {
                    return _buildMqttError();
                  } else if (snapshot.data! == LoveBoxState.connecting) {
                    return _buildMqttLoading();
                  }
                }

                return Container();
              }),
          Expanded(
              child: FadeThroughIndexedStack(
            index: _selectedPage,
            children: _pages,
          ))
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.text_fields),
            label: "Text",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.image),
            label: "Images",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.save),
            label: "Saved",
          ),
        ],
        currentIndex: _selectedPage,
        //selectedItemColor: Colors.amber[800],
        onTap: (index) {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() {
            // now check if the chosen page has already been built
            // if it hasn't, then it still is a SizedBox
            if (_pages[index] is SizedBox) {
              switch (index) {
                case 0:
                  _pages[index] = TextMessagePage(
                    loveBox: _loveBox,
                  );
                  break;
                case 1:
                  _pages[index] = ImageMessagePage(
                    loveBox: _loveBox,
                  );
                  break;
                case 2:
                  _pages[index] = SavedMessagesPage(
                    loveBox: _loveBox,
                  );
                  break;
              }
            }

            _selectedPage = index;
          });
        },
      ),
    );
  }

  Widget _buildMqttLoading() {
    return LinearProgressIndicator(
      color: Colors.red,
      backgroundColor: Colors.redAccent.withOpacity(0.5),
    );
  }

  Widget _buildMqttError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                radius: 20,
                child: const Icon(
                  Icons.signal_cellular_connected_no_internet_4_bar,
                  color: Colors.white,
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: Text(
                  "Connection to Mqtt broker failed. Maybe check your internet connection or configuration.",
                  style: Theme.of(context).textTheme.bodyText1,
                ),
              )
            ],
          ),
        ),
        const SizedBox(
          height: 12.0,
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: 24.0, right: 8.0, top: 8.0, bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  style: TextButton.styleFrom(
                    //padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    _loveBox.connect();
                  },
                  child: const Text("TRY AGAIN"))
            ],
          ),
        ),
        Container(
          height: 1,
          color: Colors.black12,
        ),
      ],
    );
  }
}
