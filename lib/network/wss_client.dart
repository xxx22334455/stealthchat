import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:web_socket_channel/io.dart';
import '../config/constants.dart';

/// WSS client for connecting to peers and relays
/// Uses platform TLS stack for browser-like fingerprint
class WssClient {
  final String _url;
  IOWebSocketChannel? _channel;
  StreamSubscription? _subscription;

  // Callbacks
  final Function(Uint8List data)? _onMessage;
  final Function()? _onConnected;
  final Function(dynamic error)? _onError;
  final Function()? _onClosed;

  WssClient({
    required String url,
    Function(Uint8List data)? onMessage,
    Function()? onConnected,
    Function(dynamic error)? onError,
    Function()? onClosed,
  })  : _url = url,
        _onMessage = onMessage,
        _onConnected = onConnected,
        _onError = onError,
        _onClosed = onClosed;

  /// Connect to WSS endpoint
  Future<bool> connect() async {
    try {
      // Use platform TLS with default settings (browser-like fingerprint)
      final channel = await IOWebSocketChannel.connect(
        _url,
        // Custom headers to look like browser
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Origin': 'https://${Uri.parse(_url).host}',
        },
      );

      _channel = channel;

      // Listen for messages
      _subscription = channel.stream.listen(
        (data) {
          if (data is Uint8List) {
            _onMessage?.call(data);
          }
        },
        onError: (error) {
          _onError?.call(error);
        },
        onDone: () {
          _onClosed?.call();
        },
      );

      _onConnected?.call();
      return true;
    } catch (e) {
      _onError?.call(e);
      return false;
    }
  }

  /// Send binary message
  void send(Uint8List data) {
    _channel?.sink.add(data);
  }

  /// Send text message
  void sendText(String text) {
    _channel?.sink.add(text);
  }

  /// Close connection
  void close() {
    _subscription?.cancel();
    _channel?.sink.close();
  }

  /// Check if connected
  bool get isConnected => _channel != null;
}
