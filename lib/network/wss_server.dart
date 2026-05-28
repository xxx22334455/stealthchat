import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:web_socket_channel/io.dart';
import '../config/constants.dart';

/// WSS server for relay functionality
/// Listens on port 443 with TLS
class WssServer {
  final String _host;
  final int _port;
  final X509Certificate? _certificate;
  final PrivateKey? _privateKey;

  HttpServer? _httpServer;
  final Map<String, IOWebSocketChannel> _clients = {};

  // Callbacks
  final Function(IOWebSocketChannel client, Uint8List data)? _onMessage;
  final Function(IOWebSocketChannel client)? _onClientConnected;
  final Function(IOWebSocketChannel client)? _onClientDisconnected;

  WssServer({
    String host = '0.0.0.0',
    int port = WSS_PORT,
    X509Certificate? certificate,
    PrivateKey? privateKey,
    Function(IOWebSocketChannel client, Uint8List data)? onMessage,
    Function(IOWebSocketChannel client)? onClientConnected,
    Function(IOWebSocketChannel client)? onClientDisconnected,
  })  : _host = host,
        _port = port,
        _certificate = certificate,
        _privateKey = privateKey,
        _onMessage = onMessage,
        _onClientConnected = onClientConnected,
        _onClientDisconnected = onClientDisconnected;

  /// Start server
  Future<bool> start() async {
    try {
      if (_certificate != null && _privateKey != null) {
        // Start with TLS
        _httpServer = await HttpServer.bindSecure(
          _host,
          _port,
          _certificate!,
          _privateKey!,
        );
      } else {
        // Start without TLS (for testing)
        _httpServer = await HttpServer.bind(_host, _port);
      }

      _httpServer!.transform(_webSocketTransformer).listen(_handleConnection);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Handle incoming WebSocket connection
  void _handleConnection(HttpRequest request) {
    final channel = IOWebSocketChannel.attach(request);
    final clientKey = channel.sink.hashCode.toString();
    _clients[clientKey] = channel;

    _onClientConnected?.call(channel);

    // Listen for messages
    channel.stream.listen(
      (data) {
        if (data is Uint8List) {
          _onMessage?.call(channel, data);
        }
      },
      onDone: () {
        _clients.remove(clientKey);
        _onClientDisconnected?.call(channel);
      },
      onError: (error) {
        // Handle error
      },
    );
  }

  /// Send message to specific client
  void sendToClient(String clientKey, Uint8List data) {
    final channel = _clients[clientKey];
    channel?.sink.add(data);
  }

  /// Broadcast message to all clients
  void broadcast(Uint8List data) {
    for (final channel in _clients.values) {
      channel.sink.add(data);
    }
  }

  /// Stop server
  void stop() {
    for (final channel in _clients.values) {
      channel.sink.close();
    }
    _clients.clear();
    _httpServer?.close();
  }

  /// Get connected client count
  int get clientCount => _clients.length;

  /// WebSocket transformer
  static WebSocketTransformer get _webSocketTransformer {
    return WebSocketTransformer();
  }
}
