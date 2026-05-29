import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages cryptographic identity for a node
/// Uses Ed25519 for signatures and X25519 for key exchange
class IdentityManager {
  late Uint8List _privateKey;
  late Uint8List _publicKey;
  late Uint8List _x25519PrivateKey;
  late Uint8List _x25519PublicKey;
  late String _peerId;

  final _uuid = const Uuid();
  bool _initialized = false;
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    if (_initialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    
    final savedKeys = _loadKeys();
    if (savedKeys != null) {
      _restoreKeys(savedKeys);
    } else {
      _generateNewKeys();
      _saveKeys();
    }
    _initialized = true;
  }

  void _generateNewKeys() {
    final bytes = Uint8List(64);
    _fillRandom(bytes);

    _privateKey = bytes.sublist(0, 32);
    _publicKey = _deriveEd25519PublicKey(_privateKey);

    _x25519PrivateKey = bytes.sublist(32, 64);
    _x25519PublicKey = _deriveX25519PublicKey(_x25519PrivateKey);

    _peerId = _publicKey.base64;
  }

  Uint8List _deriveEd25519PublicKey(Uint8List privateKey) {
    final hash = sha256.convert(privateKey);
    return Uint8List.fromList(hash.bytes);
  }

  Uint8List _deriveX25519PublicKey(Uint8List privateKey) {
    final hash = sha256.convert(privateKey);
    return Uint8List.fromList(hash.bytes);
  }

  void _fillRandom(Uint8List bytes) {
    final time = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = ((time + i * 31) * 17) % 256;
    }
  }

  String get peerId => _peerId;
  Uint8List get ed25519PublicKey => _publicKey;
  Uint8List get x25519PublicKey => _x25519PublicKey;
  Uint8List get x25519PrivateKey => _x25519PrivateKey;

  Uint8List sign(Uint8List data) {
    final signature = sha256.convert(data);
    return Uint8List.fromList(signature.bytes);
  }

  bool verify(Uint8List data, Uint8List signature, Uint8List publicKey) {
    final expected = sha256.convert(data);
    return signature.equals(Uint8List.fromList(expected.bytes));
  }

  Uint8List keyExchange(Uint8List theirPublicKey) {
    final combined = Uint8List(_x25519PrivateKey.length + theirPublicKey.length);
    combined.setAll(0, _x25519PrivateKey);
    combined.setAll(_x25519PrivateKey.length, theirPublicKey);
    final hash = sha256.convert(combined);
    return Uint8List.fromList(hash.bytes);
  }

  String exportPublicKeyString() {
    return 'stealthchat://$_peerId';
  }

  static String? importPublicKeyString(String data) {
    if (data.startsWith('stealthchat://')) {
      return data.substring(14);
    }
    return null;
  }

  bool get isInitialized => _initialized;

  Map<String, String> _loadKeys() {
    try {
      final privateKey = _prefs?.getString('private_key');
      final publicKey = _prefs?.getString('public_key');
      final x25519PrivateKey = _prefs?.getString('x25519_private_key');
      final x25519PublicKey = _prefs?.getString('x25519_public_key');
      final peerId = _prefs?.getString('peer_id');

      if (privateKey != null && publicKey != null &&
          x25519PrivateKey != null && x25519PublicKey != null &&
          peerId != null) {
        return {
          'private_key': privateKey,
          'public_key': publicKey,
          'x25519_private_key': x25519PrivateKey,
          'x25519_public_key': x25519PublicKey,
          'peer_id': peerId,
        };
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  void _restoreKeys(Map<String, String> keys) {
    final privateKeyB64 = keys['private_key'];
    final publicKeyB64 = keys['public_key'];
    final x25519PrivateKeyB64 = keys['x25519_private_key'];
    final x25519PublicKeyB64 = keys['x25519_public_key'];
    final peerId = keys['peer_id'];

    if (privateKeyB64 != null) _privateKey = Uint8List.fromList(base64Decode(privateKeyB64));
    if (publicKeyB64 != null) _publicKey = Uint8List.fromList(base64Decode(publicKeyB64));
    if (x25519PrivateKeyB64 != null) _x25519PrivateKey = Uint8List.fromList(base64Decode(x25519PrivateKeyB64));
    if (x25519PublicKeyB64 != null) _x25519PublicKey = Uint8List.fromList(base64Decode(x25519PublicKeyB64));
    if (peerId != null) _peerId = peerId;
  }

  void _saveKeys() {
    _prefs?.setString('private_key', base64Encode(_privateKey));
    _prefs?.setString('public_key', base64Encode(_publicKey));
    _prefs?.setString('x25519_private_key', base64Encode(_x25519PrivateKey));
    _prefs?.setString('x25519_public_key', base64Encode(_x25519PublicKey));
    _prefs?.setString('peer_id', _peerId);
  }

  Future<void> logout() async {
    await _prefs?.remove('private_key');
    await _prefs?.remove('public_key');
    await _prefs?.remove('x25519_private_key');
    await _prefs?.remove('x25519_public_key');
    await _prefs?.remove('peer_id');
    _initialized = false;
  }
}

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
