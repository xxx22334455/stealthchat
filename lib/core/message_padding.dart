import 'dart:typed_data';
import '../config/constants.dart';

/// Message padding utility for anti-DPI
class MessagePadding {
  /// Pad message to 512-byte blocks
  /// Format: [original data][random padding]
  static Uint8List pad(Uint8List data) {
    if (data.length == 0) {
      // Minimum one block
      return _generateRandomBlock();
    }
    
    final blocks = (data.length - 1) ~/ BLOCK_SIZE + 1;
    final paddedSize = blocks * BLOCK_SIZE;
    
    final padded = Uint8List(paddedSize);
    padded.setAll(0, data);
    
    // Fill padding with random bytes
    final random = _generateRandomBytes(paddedSize - data.length);
    padded.setAll(data.length, random);
    
    return padded;
  }

  /// Unpad message (remove padding bytes)
  /// Note: In practice, we don't know original length,
  /// so padding is just for size obfuscation
  static Uint8List unpad(Uint8List padded) {
    return padded; // Return as-is, application layer handles actual length
  }

  /// Generate random bytes for padding
  static Uint8List _generateRandomBytes(int count) {
    final bytes = Uint8List(count);
    for (int i = 0; i < count; i++) {
      bytes[i] = DateTime.now().millisecondsSinceEpoch % 256;
    }
    return bytes;
  }

  /// Generate a full random block (for dummy traffic)
  static Uint8List _generateRandomBlock() {
    return _generateRandomBytes(BLOCK_SIZE);
  }

  /// Create dummy message with given size (multiple of 512)
  static Uint8List createDummyMessage([int blocks = 1]) {
    return _generateRandomBytes(blocks * BLOCK_SIZE);
  }
}
