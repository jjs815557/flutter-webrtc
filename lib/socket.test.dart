import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketIoExample extends StatefulWidget {
  const SocketIoExample({super.key});

  @override
  State<SocketIoExample> createState() => _SocketIoExampleState();
}

class _SocketIoExampleState extends State<SocketIoExample> {
  late final IO.Socket socket;

  final _localRTCVideoRenderer = RTCVideoRenderer();
  final _remoteRTCVideoRenderer = RTCVideoRenderer();

  MediaStream? _localStream;
  RTCPeerConnection? _rtcPeerConnection;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    init();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _localRTCVideoRenderer.dispose();
    _remoteRTCVideoRenderer.dispose();
    _localStream?.dispose();
    _rtcPeerConnection?.dispose();
    socket.close();
  }

  Future init() async {
    await _localRTCVideoRenderer.initialize();
    await _remoteRTCVideoRenderer.initialize();

    await connectSocket();
    await joinRoom();
    setState(() {});
  }

  Future connectSocket() async {
    socket = IO.io(
        'http://localhost:3000',
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

  Future joinRoom() async {
    final config = {
      'iceServers': [
        {
          "url": [
            "stun:stun.l.google.com:193602",
            "stun:stun1.l.google.com:193602",
            "stun:stun2.l.google.com:193602"
          ]
        }
      ]
    };

    final sdpConstraints = {
      'mandatory': {
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      },
      'optional': []
    };

    _rtcPeerConnection =
        await createPeerConnection(config, sdpConstraints); // peer 객체 생성

    final mediaConstranints = {
      // 자신의 미디어 초기 설정 값
      'audio': true,
      'video': {'facingMode': 'user'}
    };

    _localStream = await Helper.openCamera(mediaConstranints); //자신의 미디어 장치 찾기
    _localStream!.getTracks().forEach((track) {
      // getTracks() 자신의 미디어 장치 목록
      _rtcPeerConnection!.addTrack(track, _localStream!);
    });
    _localRTCVideoRenderer.srcObject =
        _localStream; // RTCVideoView()화면에 출력해주는 스트림

    _rtcPeerConnection!.onIceCandidate = (ice) {
      _sendIce(ice);
    };

    _rtcPeerConnection!.onAddStream = (stream) {
      _remoteRTCVideoRenderer.srcObject = stream;
    };

    socket.emit('join');
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('webRTC test'),
        ),
        body: Column(
          children: [
            Expanded(child: RTCVideoView(_localRTCVideoRenderer)),
            Expanded(child: RTCVideoView(_remoteRTCVideoRenderer)),
          ],
        ),
      ),
    );
  }
}
