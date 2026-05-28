import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:web_socket_channel/io.dart';
import '../config/constants.dart';

/// WSS client for connecting to peers and relays
/// Uses platform TLS stack for browser-like fingerprint
class WssClient {
  final String _url;
  final X509Certificate? _trustedCertificate;
  IOWebSocketChannel? _channel;
  StreamSubscription? _subscription;

  // Callbacks
  final Function(Uint8List data)? _onMessage;
  final Function()? _onConnected;
  final Function(dynamic error)? _onError;
  final Function()? _onClosed;

  WssClient({
    required String url,
    X509Certificate? trustedCertificate,
    Function(Uint8List data)? onMessage,
    Function()? onConnected,
    Function(dynamic error)? onError,
    Function()? onClosed,
  })  : _url = url,
        _trustedCertificate = trustedCertificate,
        _onMessage = onMessage,
        _onConnected = onConnected,
        _onError = onError,
        _onClosed = onClosed;

  /// Connect to WSS endpoint
  Future<bool> connect() async {
    try {
      // Use platform TLS with default settings (browser-like fingerprint)
      final uri = Uri.parse(_url);
      
      SecurityContext? securityContext;
      if (_trustedCertificate != null) {
        // Add trusted certificate for self-signed cert validation
        securityContext = SecurityContext.defaultContext;
        // TODO: Add certificate to security context for pinning
      }

      final channel = await IOWebSocketChannel.connect(
        _url,
        context: securityContext,
        // Custom headers to look like browser
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Origin': 'https://${uri.host}',
          'Host': uri.host,
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
