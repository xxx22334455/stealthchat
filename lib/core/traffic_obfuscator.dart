import 'dart:async';
import 'dart:typed_data';
import '../config/constants.dart';

/// Generates dummy traffic to maintain constant traffic pattern
/// This prevents DPI from detecting idle periods
class TrafficObfuscator {
  final Function(Uint8List data)? _onSend;
  Timer? _dummyTimer;
  bool _isRunning = false;

  TrafficObfuscator({Function(Uint8List data)? onSend}) {
    _onSend = onSend;
  }

  /// Start dummy traffic generation
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _scheduleNextDummy();
  }

  /// Stop dummy traffic generation
  void stop() {
    _isRunning = false;
    _dummyTimer?.cancel();
  }

  /// Schedule next dummy packet
  void _scheduleNextDummy() {
    if (!_isRunning) return;

    // Random interval between 10-30 seconds
    final interval = MIN_DUMMY_INTERVAL +
        (DateTime.now().millisecondsSinceEpoch % (MAX_DUMMY_INTERVAL - MIN_DUMMY_INTERVAL));

    _dummyTimer = Timer(Duration(seconds: interval), () {
      _sendDummyPacket();
      _scheduleNextDummy();
    });
  }

  /// Send a dummy packet
  void _sendDummyPacket() {
    if (_onSend == null) return;

    // Create dummy message: [type=0x02][padded random data]
    final dummyData = MessagePadding.createDummyMessage();
    final message = Uint8List(1 + dummyData.length);
    message[0] = MessageType.dummy;
    message.setAll(1, dummyData);

    _onSend!(message);
  }

  /// Send real message (resets dummy timer)
  void onRealMessageSent() {
    // Optionally reset dummy timer to avoid predictable patterns
    _dummyTimer?.cancel();
    _scheduleNextDummy();
  }

  /// Dispose resources
  void dispose() {
    stop();
  }
}

/// Message padding utility for anti-DPI
class MessagePadding {
  /// Pad message to 512-byte blocks
  static Uint8List pad(Uint8List data) {
    if (data.length == 0) {
      return _generateRandomBlock();
    }
    
    final blocks = (data.length - 1) ~/ BLOCK_SIZE + 1;
    final paddedSize = blocks * BLOCK_SIZE;
    
    final padded = Uint8List(paddedSize);
    padded.setAll(0, data);
    
    final random = _generateRandomBytes(paddedSize - data.length);
    padded.setAll(data.length, random);
    
    return padded;
  }

  /// Generate random bytes
  static Uint8List _generateRandomBytes(int count) {
    final bytes = Uint8List(count);
    for (int i = 0; i < count; i++) {
      bytes[i] = DateTime.now().millisecondsSinceEpoch % 256;
    }
    return bytes;
  }

  /// Generate random block
  static Uint8List _generateRandomBlock() {
    return _generateRandomBytes(BLOCK_SIZE);
  }

  /// Create dummy message
  static Uint8List createDummyMessage([int blocks = 1]) {
    return _generateRandomBytes(blocks * BLOCK_SIZE);
  }
}
