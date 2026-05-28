import 'dart:async';
import 'dart:typed_data';
import '../config/constants.dart';

/// Generates dummy traffic to maintain constant traffic pattern
class TrafficObfuscator {
  final Function(Uint8List data)? _onSend;
  Timer? _dummyTimer;
  bool _isRunning = false;

  TrafficObfuscator({Function(Uint8List data)? onSend}) : _onSend = onSend;

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _scheduleNextDummy();
  }

  void stop() {
    _isRunning = false;
    _dummyTimer?.cancel();
  }

  void _scheduleNextDummy() {
    if (!_isRunning) return;

    final interval = MIN_DUMMY_INTERVAL +
        (DateTime.now().millisecondsSinceEpoch % (MAX_DUMMY_INTERVAL - MIN_DUMMY_INTERVAL));

    _dummyTimer = Timer(Duration(seconds: interval), () {
      _sendDummyPacket();
      _scheduleNextDummy();
    });
  }

  void _sendDummyPacket() {
    if (_onSend == null) return;

    final dummyData = _generateRandomBytes(BLOCK_SIZE);
    final message = Uint8List(1 + dummyData.length);
    message[0] = MessageType.dummy;
    message.setAll(1, dummyData);

    _onSend!(message);
  }

  void onRealMessageSent() {
    _dummyTimer?.cancel();
    _scheduleNextDummy();
  }

  void dispose() {
    stop();
  }

  Uint8List _generateRandomBytes(int count) {
    final bytes = Uint8List(count);
    for (int i = 0; i < count; i++) {
      bytes[i] = DateTime.now().millisecondsSinceEpoch % 256;
    }
    return bytes;
  }
}
