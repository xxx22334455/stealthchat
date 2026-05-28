import 'dart:async';
import 'dart:typed_data';
import 'package:web_socket_channel/io.dart';
import '../config/constants.dart';

/// WSS client for connecting to peers and relays
class WssClient {
  final String _url;
  IOWebSocketChannel? _channel;
  StreamSubscription? _subscription;

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

  Future<bool> connect() async {
    try {
      final uri = Uri.parse(_url);
      final channel = await IOWebSocketChannel.connect(
        _url,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Origin': 'https://${uri.host}',
          'Host': uri.host,
        },
      );

      _channel = channel;

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

  void send(Uint8List data) {
    _channel?.sink.add(data);
  }

  void sendText(String text) {
    _channel?.sink.add(text);
  }

  void close() {
    _subscription?.cancel();
    _channel?.sink.close();
  }

  bool get isConnected => _channel != null;
}
