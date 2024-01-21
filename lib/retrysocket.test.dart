import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class RetrySocket extends StatefulWidget {
  const RetrySocket({super.key});

  @override
  State<RetrySocket> createState() => _RetrySocketState();
}

class _RetrySocketState extends State<RetrySocket> {
  late IO.Socket socket;
  final _localRTCVideoRenderer = RTCVideoRenderer();
  final _remoteRTCVideoRenderer = RTCVideoRenderer();

  MediaStream? _localStream;
  RTCPeerConnection? _rtcPeerConnection; //pc

// media status
  bool isAudioOn = true, isVideoOn = true, isFrontCameraSelected = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _localRTCVideoRenderer.initialize();
    _remoteRTCVideoRenderer.initialize();
    init();
  }

  Future init() async {
    // await _localRTCVideoRenderer.initialize();
    // await _remoteRTCVideoRenderer.initialize();

    await connectSocket();
    await joinRoom();
  }

  Future connectSocket() async {
    socket = IO.io(
        'http://192.168.200.135:3000',
        IO.OptionBuilder()
            .setTransports(['websocket']) // for Flutter or Dart VM
            .build());
    socket.onConnect((data) => print('연결 완료!'));

    socket.on('joined', (data) {
      _sendOffer();
    });

    socket.on('offer', (data) async {
      data = jsonDecode(data);
      await _gotOffer(RTCSessionDescription(data['sdp'], data['type']));
      await _sendAnswer();
    });

    socket.on('answer', (data) {
      data = jsonDecode(data);
      _gotAnswer(RTCSessionDescription(data['sdp'], data['type']));
    });

    socket.on('ice', (data) {
      data = jsonDecode(data);
      _gotIce(RTCIceCandidate(
          data['candidate'], data['sdpMid'], data['sdpMLineIndex']));
    });
  }

  Future _sendOffer() async {
    print('send offer');
    var offer = await _rtcPeerConnection!.createOffer();
    _rtcPeerConnection!.setLocalDescription(offer);
    socket.emit('offer', jsonEncode(offer.toMap()));
  }

  Future _gotOffer(RTCSessionDescription offer) async {
    print('got offer');
    _rtcPeerConnection!.setRemoteDescription(offer);
  }

  Future _sendAnswer() async {
    print('send answer');
    var answer = await _rtcPeerConnection!.createAnswer();
    _rtcPeerConnection!.setLocalDescription(answer);
    socket.emit('answer', jsonEncode(answer.toMap()));
  }

  Future _gotAnswer(RTCSessionDescription answer) async {
    print('got answer');
    _rtcPeerConnection!.setRemoteDescription(answer);
  }

  Future _sendIce(RTCIceCandidate ice) async {
    print('send ice');
    socket.emit('ice', jsonEncode(ice.toMap()));
  }

  Future _gotIce(RTCIceCandidate ice) async {
    print('got ice');
    _rtcPeerConnection!.addCandidate(ice);
  }

  Future joinRoom() async {
    final config = {
      'iceServers': [
        {"url": "stun:stun.l.google.com:19302"}
      ]
    };

    final sdpConstraints = {
      'mandatory': {
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      },
      'optional': []
    };

    final mediaConstraints = {
      // 자신의 미디어 초기 설정 값
      'audio': true,
      'video': {'facingMode': 'user'}
    };

    _rtcPeerConnection = await createPeerConnection(config, sdpConstraints);

    _localStream = await Helper.openCamera(mediaConstraints);
    _localStream!.getTracks().forEach((track) {
      _rtcPeerConnection!.addTrack(track, _localStream!);
    });

    _localRTCVideoRenderer.srcObject = _localStream;

    _rtcPeerConnection!.onIceCandidate = (ice) {
      _sendIce(ice);
    };

    _rtcPeerConnection!.onAddStream = (stream) {
      _remoteRTCVideoRenderer.srcObject = stream;
    };

    socket.emit('join');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('call page'),
        ),
        body: Column(
          children: [
            // Text(widget.roomName),
            // Expanded(
            //   child: Stack(
            //     children: [
            //       RTCVideoView(
            //         _remoteRTCVideoRenderer,
            //         objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            //       ),
            //       Positioned(
            //         right: 20,
            //         bottom: 20,
            //         child: SizedBox(
            //           height: 150,
            //           width: 120,
            //           child: RTCVideoView(
            //             _localRTCVideoRenderer,
            //             // mirror: isFrontCameraSelected,
            //             objectFit:
            //                 RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            //           ),
            //         ),
            //       )
            //     ],
            //   ),
            // ),
            Expanded(child: RTCVideoView(_localRTCVideoRenderer)),
            Expanded(child: RTCVideoView(_remoteRTCVideoRenderer)),
          ],
        ),
      ),
    );
  }
}
