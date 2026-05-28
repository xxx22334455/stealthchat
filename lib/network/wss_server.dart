import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:web_socket_channel/io.dart';
import '../config/constants.dart';

/// WSS server for relay functionality
class WssServer {
  final String _host;
  final int _port;

  HttpServer? _httpServer;
  final Map<String, IOWebSocketChannel> _clients = {};

  final Function(String clientId, Uint8List data)? _onMessage;
  final Function(String clientId)? _onClientConnected;
  final Function(String clientId)? _onClientDisconnected;

  WssServer({
    String host = '0.0.0.0',
    int port = WSS_PORT,
    Function(String clientId, Uint8List data)? onMessage,
    Function(String clientId)? onClientConnected,
    Function(String clientId)? onClientDisconnected,
  })  : _host = host,
        _port = port,
        _onMessage = onMessage,
        _onClientConnected = onClientConnected,
        _onClientDisconnected = onClientDisconnected;

  Future<bool> start() async {
    try {
      _httpServer = await HttpServer.bind(_host, _port);
      _httpServer!.transform(_webSocketTransformer).listen(_handleConnection);
      return true;
    } catch (e) {
      return false;
    }
  }

  void _handleConnection(WebSocket socket) {
    final clientKey = socket.hashCode.toString();
    _clients[clientKey] = IOWebSocketChannel.fromWebSocket(socket);

    _onClientConnected?.call(clientKey);

    IOWebSocketChannel.fromWebSocket(socket).stream.listen(
      (data) {
        if (data is Uint8List) {
          _onMessage?.call(clientKey, data);
        }
      },
      onDone: () {
        _clients.remove(clientKey);
        _onClientDisconnected?.call(clientKey);
      },
    );
  }

  void sendToClient(String clientKey, Uint8List data) {
    final channel = _clients[clientKey];
    channel?.sink.add(data);
  }

  void broadcast(Uint8List data) {
    for (final channel in _clients.values) {
      channel.sink.add(data);
    }
  }

  void stop() {
    for (final channel in _clients.values) {
      channel.sink.close();
    }
    _clients.clear();
    _httpServer?.close();
  }

  int get clientCount => _clients.length;

  static WebSocketTransformer get _webSocketTransformer {
    return WebSocketTransformer();
  }
}
