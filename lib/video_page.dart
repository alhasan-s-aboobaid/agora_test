import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:http/http.dart' as http;

class VideoPage extends StatefulWidget {
  const VideoPage({Key? key}) : super(key: key);

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  String appId = "ee53689a4e864c05bf390abc9f8cbca3";
  String channelName = "maidscc";
  String token = "";
  int uid = 0;

  int? _remoteUid; // uid of the remote user
  bool _isJoined = false; // Indicates if the local user has joined the channel
  late RtcEngine agoraEngine; // Agora engine instance

  static final _users = <int>[];

  bool muted = false;
  bool localVideoMuted = false;
  bool muteAllAudios = false;

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(); // Global key to access the scaffold

  showMessage(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
      content: Text(message),
    ));
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: Scaffold(
          body: Stack(
            children: [
              _users.length == 0 && _isJoined ? Center(child: Text("Waiting for remote users"),) : SizedBox(),
              _viewRows(),
              localVideoMuted || !_isJoined ? const SizedBox(): Positioned(
                right: 4,
                  bottom: 4,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),clipBehavior: Clip.antiAlias,
                  child: Container(
                    height: 220,
                    width: 150,
                    decoration: BoxDecoration(border: Border.all(width: 2), color: Colors.white),
                    child: Center(child: _localPreview()),
                  ),
                ),
              ),
              Align(
                  alignment: !_isJoined ? Alignment.center : Alignment.bottomLeft,
                  child: _toolbar()),
            ],
          )),
    );
  }

  @override
  void initState() {
    super.initState();
    // Set up an instance of Agora engine
    setupVideoSDKEngine();
  }

  @override
  void dispose() async {
    await agoraEngine.leaveChannel();
    _users.clear();
    super.dispose();
  }


  Future<void> setupVideoSDKEngine() async {
    await [Permission.microphone, Permission.camera].request();

    var response = await http.get(Uri.parse("http://52.199.90.226:8080/rtc/maidscc/publisher/userAccount/0"));
    print("response ${response.body}");
    token = jsonDecode(response.body)["rtcToken"];
    print("response token $token");

    agoraEngine = createAgoraRtcEngine();
    await agoraEngine.initialize(RtcEngineContext(
      appId: appId,
    ));
    await agoraEngine.enableVideo();

    agoraEngine.registerEventHandler(RtcEngineEventHandler(
      onError: (err, msg) {
        showMessage("Error ${err.name} Error Code ${err.index}");
      },
      onJoinChannelSuccess: (connection, elapsed) {
        showMessage("Local user uid:${connection.localUid} joined the channel");
        setState(() {
          _isJoined = true;
        });
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        showMessage("Remote user uid:$remoteUid joined the channel");
        _users.add(remoteUid);
        setState(() {

        });
      },
      onUserOffline: (RtcConnection connection, int remoteUid,
          UserOfflineReasonType reason) {
        showMessage("Remote user uid:$remoteUid left the channel");
        _users.remove(remoteUid);
        setState(() {

        });
      },
    ));
    // set parameters for Agora Engine
   /* agoraEngine.setParameters('{\"che.video.lowBitRateStreamParameter\"' +
        ':{\"width\":320,\"height\":180,\"frameRate\":15,\"bitRate\":140}}');*/

  }

  void leave() async {
    setState(() {
      _isJoined = false;
      _remoteUid = null;
    });
    await agoraEngine.leaveChannel();
    _users.clear();
  }

  void join() async {
    await agoraEngine.startPreview();

    // Set channel options including the client role and channel profile
    ChannelMediaOptions options = const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        isAudioFilterable: true);

    await agoraEngine.joinChannel(
      token: token,
      channelId: channelName,
      options: options,
      uid: uid,
    );
  }

// Display local video preview
  Widget _localPreview() {
    if (_isJoined) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: agoraEngine,
          canvas: VideoCanvas(uid: uid),
        ),
      );
    } else {
      return const Text(
        '',
        textAlign: TextAlign.center,
      );
    }
  }

// Display remote user's video
  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: agoraEngine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: channelName),
        ),
      );
    } else {
      String msg = '';
      if (_isJoined) msg = 'Waiting for a remote user to join';
      return Text(
        msg,
        textAlign: TextAlign.center,
      );
    }
  }

  List<Widget> _getRenderViews() {
    List<Widget> list = [];

    for (var uid in _users) {
      {
        list.add(AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: agoraEngine,
            canvas: VideoCanvas(uid: uid),
          ),
        ));
      }
    }
    return list;
  }
  Widget _videoView(view) {
    return Expanded(child: Container(child: view));
  }
  Widget _expandedVideoRow(List<Widget> views) {
    List<Widget> wrappedViews =
        views.map((Widget view) => _videoView(view)).toList();
    return Expanded(
        child: Row(
      children: wrappedViews,
    ));
  }
  Widget _viewRows() {
    List<Widget> views = _getRenderViews();
    switch (views.length) {
      case 1:
        return Column(
          children: <Widget>[_videoView(views[0])],
        );
      case 2:
        return Column(
          children: <Widget>[
            _expandedVideoRow([views[0]]),
            _expandedVideoRow([views[1]])
          ],
        );
      case 3:
        return Column(
          children: <Widget>[
            _expandedVideoRow(views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 3))
          ],
        );
      case 4:
        return Column(
          children: <Widget>[
            _expandedVideoRow(views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 4))
          ],
        );
      default:
    }
    return Container();
  }

  /// Toolbar layout
  Widget _toolbar() {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Visibility(
              visible: _isJoined,
              child: RawMaterialButton(
                onPressed: () => _muteVideo(),
                shape: const CircleBorder(),
                elevation: 2.0,
                fillColor: localVideoMuted ? Colors.blueAccent : Colors.white,
                padding: const EdgeInsets.all(12.0),
                child: Icon(
                  localVideoMuted ? Icons.videocam_off : Icons.videocam,
                  color: localVideoMuted ? Colors.white : Colors.blueAccent,
                  size: 20.0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Visibility(
              visible: _isJoined,
              child: RawMaterialButton(
                onPressed: () => _onToggleMute(),
                shape: const CircleBorder(),
                elevation: 2.0,
                fillColor: muted ? Colors.blueAccent : Colors.white,
                padding: const EdgeInsets.all(12.0),
                child: Icon(
                  muted ? Icons.mic_off : Icons.mic,
                  color: muted ? Colors.white : Colors.blueAccent,
                  size: 20.0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Visibility(
              visible: _isJoined,
              child: RawMaterialButton(
                onPressed: () => _muteRemoteAudio(),
                shape: const CircleBorder(),
                elevation: 2.0,
                fillColor: muteAllAudios ? Colors.blueAccent : Colors.white,
                padding: const EdgeInsets.all(12.0),
                child: Icon(
                  muteAllAudios ? Icons.volume_off : Icons.volume_up,
                  color: muteAllAudios ? Colors.white : Colors.blueAccent,
                  size: 20.0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Visibility(
              visible: _isJoined,
              child: RawMaterialButton(
                onPressed: () => _onSwitchCamera(),
                shape: const CircleBorder(),
                elevation: 2.0,
                fillColor: Colors.white,
                padding: const EdgeInsets.all(12.0),
                child: const Icon(
                  Icons.switch_camera,
                  color: Colors.blueAccent,
                  size: 20.0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            !_isJoined ? const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Press the below button to connect"),
            ) : const SizedBox(),
            RawMaterialButton(
              onPressed: () => _onCall(context),
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.white,
              padding: const EdgeInsets.all(12.0),
              child: Icon(
                _isJoined ? Icons.call_end : Icons.call,
                color: _isJoined ? Colors.red : Colors.blue,
                size: _isJoined ? 20.0 : 48,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCall(BuildContext context) {
    _isJoined ? leave() : join();
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    agoraEngine.muteLocalAudioStream(muted);
  }void _muteVideo() {
    setState(() {
      localVideoMuted= !localVideoMuted;
    });
    agoraEngine.muteLocalVideoStream(localVideoMuted);
  }
  void _muteRemoteAudio() {
    setState(() {
      muteAllAudios = !muteAllAudios;
    });
    agoraEngine.muteAllRemoteAudioStreams(muteAllAudios);
  }

  void _onSwitchCamera() {
    agoraEngine.switchCamera();
  }
}
