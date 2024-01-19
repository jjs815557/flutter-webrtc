import 'package:socket_io_client/socket_io_client.dart';

class SocketService {
  Socket? socket;

  SocketService._();
  static final instance = SocketService._();

  init() {
    // init Socket
    socket = io('http://localhost:3000', {
      "transports": ['websocket'],
      "query": {"callerId": 'testID'}
    });

    // listen onConnect event
    socket!.onConnect((data) {
      // log("Socket connected !!");
    });

    // listen onConnectError event
    socket!.onConnectError((data) {
      // log("Connect Error $data");
    });

    // connect socket
    socket!.connect();
  }
  // void joinRoom(String roomName) {
  //   socket!.emit('connection', {'id': roomName});
  // }
}
