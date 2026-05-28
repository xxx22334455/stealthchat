import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:ffi/ffi.dart';
import 'package:uuid/uuid.dart';

/// Manages cryptographic identity for a node
/// Uses Ed25519 for signatures and X25519 for key exchange
class IdentityManager {
  late Uint8List _privateKey; // Ed25519 private key (32 bytes)
  late Uint8List _publicKey; // Ed25519 public key (32 bytes)
  late Uint8List _x25519PrivateKey; // X25519 private key (32 bytes)
  late Uint8List _x25519PublicKey; // X25519 public key (32 bytes)
  late String _peerId;

  final _uuid = const Uuid();

  /// Initialize identity - generates new keys or loads from storage
  Future<void> initialize() async {
    // TODO: Load from encrypted storage if exists
    _generateNewKeys();
  }

  /// Generate new Ed25519 and X25519 key pairs
  void _generateNewKeys() {
    // Using crypto package for now - should replace with libsodium FFI
    final bytes = Uint8List(64);
    for (int i = 0; i < 64; i++) {
      bytes[i] = _randomByte();
    }

    // Ed25519 key pair (first 32 bytes)
    _privateKey = bytes.sublist(0, 32);
    _publicKey = _deriveEd25519PublicKey(_privateKey);

    // X25519 key pair (next 32 bytes)
    _x25519PrivateKey = bytes.sublist(32, 64);
    _x25519PublicKey = _deriveX25519PublicKey(_x25519PrivateKey);

    // Peer ID is base64 of Ed25519 public key
    _peerId = _publicKey.base64;
  }

  /// Derive Ed25519 public key from private key
  /// TODO: Replace with libsodium ed25519_keypair
  Uint8List _deriveEd25519PublicKey(Uint8List privateKey) {
    // Placeholder - use sha256 as temporary derivation
    // In production: use libsodium FFI
    final hash = sha256.convert(privateKey);
    return Uint8List.fromList(hash.bytes);
  }

  /// Derive X25519 public key from private key
  /// TODO: Replace with libsodium crypto_box_keypair
  Uint8List _deriveX25519PublicKey(Uint8List privateKey) {
    // Placeholder - use sha256 as temporary derivation
    final hash = sha256.convert(privateKey);
    return Uint8List.fromList(hash.bytes);
  }

  /// Generate random byte
  int _randomByte() {
    return DateTime.now().millisecondsSinceEpoch % 256;
  }

  /// Get peer ID (base64-encoded Ed25519 public key)
  String get peerId => _peerId;

  /// Get Ed25519 public key
  Uint8List get ed25519PublicKey => _publicKey;

  /// Get X25519 public key
  Uint8List get x25519PublicKey => _x25519PublicKey;

  /// Sign data with Ed25519 private key
  /// TODO: Implement with libsodium ed25519_sign
  Uint8List sign(Uint8List data) {
    // Placeholder - use HMAC as temporary signature
    final signature = sha256.convert(data);
    return Uint8List.fromList(signature.bytes);
  }

  /// Verify signature
  /// TODO: Implement with libsodium ed25519_sign_open
  bool verify(Uint8List data, Uint8List signature, Uint8List publicKey) {
    // Placeholder implementation
    final expected = sha256.convert(data);
    return signature.equals(Uint8List.fromList(expected.bytes));
  }

  /// Perform X25519 key exchange
  /// Returns shared secret
  /// TODO: Implement with libsodium crypto_box_beforenm
  Uint8List keyExchange(Uint8List theirPublicKey) {
    // Placeholder - use sha256 of both keys
    final combined = Uint8List(_x25519PrivateKey.length + theirPublicKey.length);
    combined.setAll(0, _x25519PrivateKey);
    combined.setAll(_x25519PrivateKey.length, theirPublicKey);
    final hash = sha256.convert(combined);
    return Uint8List.fromList(hash.bytes);
  }

  /// Export public key as QR code string
  String exportPublicKeyString() {
    return 'stealthchat://${_peerId}';
  }

  /// Import peer ID from string
  static String? importPublicKeyString(String data) {
    if (data.startsWith('stealthchat://')) {
      return data.substring(14);
    }
    return null;
  }
}

/// Extension for Uint8List comparison
extension Uint8ListExt on Uint8List {
  bool equals(Uint8List other) {
    if (length != other.length) return false;
    for (int i = 0; i < length; i++) {
      if (this[i] != other[i]) return false;
    }
    return true;
  }

  String get base64 {
    return base64Encode(this);
  }
}
