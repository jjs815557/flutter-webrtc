import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  TextEditingController inputController = TextEditingController();

  IO.Socket? socket;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    connectToServer();
  }

  void connectToServer() {
    socket = IO.io('http://localhost:3000/', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket!.connect();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("P2P Call App"),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: inputController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'roomName',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () {
                // //socket 실행하기
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (_) => CallScreen(
                //       roomName: inputController.text,
                //     ),
                //   ),
                // );
              },
              child: Text('참가하기'),
            ),
          ],
        ),
      ),
    );
  }
}
