/*
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter/material.dart';

class AgoraUIPage extends StatefulWidget {
  const AgoraUIPage({Key? key}) : super(key: key);

  @override
  State<AgoraUIPage> createState() => _AgoraUIPageState();
}

class _AgoraUIPageState extends State<AgoraUIPage> {
  String appId = "ee53689a4e864c05bf390abc9f8cbca3";
  String channelName = "maidscc";
  String tempToken = "007eJxTYFj9xcRURHtG06neY5m8PGd0H4o/5/Ity02XeSxz5ahDrqkCQ2qqqbGZhWWiSaqFmUmygWlSmrGlQWJSsmWaRXJScqLxnYgtyQ2BjAyH7rizMDJAIIjPzpCbmJlSnJzMwAAAXnYgYQ==";
  String token = "006ee53689a4e864c05bf390abc9f8cbca3IAAe1aQ7EKsI5Z17xRSdAG8i9VKVdyAvhG6P9OLxghEVqwx+f9gAAAAAIgBml9Gaj26+YwQAAQAfK71jAgAfK71jAwAfK71jBAAfK71j";

  int uid = 0;

  late final AgoraClient client;

  @override
  void initState() {
    super.initState();
    client = AgoraClient(
      agoraConnectionData: AgoraConnectionData(
        appId: appId,
        channelName: channelName,
        tempToken: token,
        uid: uid,
      ),
    );
    initAgora();
  }

  void initAgora() async {
    await client.initialize();
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Agora UI Kit'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              AgoraVideoViewer(
                client: client,
                layoutType: Layout.floating,
                enableHostControls: true,
                showAVState: true,
                showNumberOfUsers: true,
                floatingLayoutContainerHeight:
                    MediaQuery.of(context).size.height * .5,
                floatingLayoutContainerWidth:
                    MediaQuery.of(context).size.width * .5,

              ),
              AgoraVideoButtons(
                client: client,
                autoHideButtonTime: 2,
                autoHideButtons: true,
                onDisconnect: () {
                  setState(() {

                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
