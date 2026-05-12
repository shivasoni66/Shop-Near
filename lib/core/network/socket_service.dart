import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_endpoints.dart';

class SocketService {
  IO.Socket? _socket; // Use a nullable private variable
  final _storage = const FlutterSecureStorage();

  // Getter for the socket with a safety check
  IO.Socket get socket {
    if (_socket == null) {
      throw Exception("Socket not initialized. Call connect() first.");
    }
    return _socket!;
  }

  Future<void> connect() async {
    final token = await _storage.read(key: 'jwt_token');

    // Use OptionBuilder for better type safety and configuration
    _socket = IO.io(
        ApiEndpoints.baseUrl.replaceFirst('/api', ''),
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({
              'token': token
            }) // Server-side expects 'token' in auth handshake
            .build());

    _socket?.connect();

    _socket?.onConnect((_) {
      print('Connected to Socket.IO server');
    });

    _socket?.onConnectError((err) => print('Socket connection error: $err'));
    _socket?.onDisconnect((_) => print('Disconnected from Socket.IO server'));
  }

  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
