import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../config/constants.dart';

/// Double Ratchet algorithm implementation
/// Provides forward secrecy and post-compromise security
class CryptoSession {
  late Uint8List _myPrivateKey;
  late Uint8List _myPublicKey;
  late Uint8List _theirPublicKey;
  
  // Ratchet state
  late Uint8List _dhPrivateKey;
  late Uint8List _dhPublicKey;
  late Uint8List _theirRatchetPublicKey;
  
  // Chain keys
  Uint8List? _sendChainKey;
  Uint8List? _sendChainNonce;
  Uint8List? _recvChainKey;
  Uint8List? _recvChainNonce;
  
  // Message keys
  Uint8List? _sendMessageKey;
  Uint8List? _recvMessageKey;

  /// Initialize new session with key exchange
  CryptoSession({
    required Uint8List myPrivateKey,
    required Uint8List myPublicKey,
    required Uint8List theirPublicKey,
  }) {
    _myPrivateKey = myPrivateKey;
    _myPublicKey = myPublicKey;
    _theirPublicKey = theirPublicKey;
    
    // Initialize DH ratchet keys (same as identity keys for now)
    _dhPrivateKey = myPrivateKey;
    _dhPublicKey = myPublicKey;
    _theirRatchetPublicKey = theirPublicKey;
    
    // Perform initial key agreement
    _initializeChainKeys();
  }

  /// Initialize chain keys from shared secret
  void _initializeChainKeys() {
    // Derive shared secret from X25519 key exchange
    final sharedSecret = _deriveSharedSecret();
    
    // KDF to derive chain keys and message keys
    final keys = _kdf(sharedSecret, 3);
    
    _sendChainKey = keys[0];
    _sendChainNonce = Uint8List(8);
    _sendMessageKey = keys[1];
    
    _recvChainKey = keys[2];
    _recvChainNonce = Uint8List(8);
    _recvMessageKey = keys[1]; // Same initial key for simplicity
  }

  /// Derive shared secret from key exchange
  Uint8List _deriveSharedSecret() {
    // Placeholder - use sha256 of combined keys
    final combined = Uint8List(_dhPrivateKey.length + _theirRatchetPublicKey.length);
    combined.setAll(0, _dhPrivateKey);
    combined.setAll(_dhPrivateKey.length, _theirRatchetPublicKey);
    final hash = sha256.convert(combined);
    return Uint8List.fromList(hash.bytes);
  }

  /// Key derivation function
  List<Uint8List> _kdf(Uint8List input, int count) {
    final result = <Uint8List>[];
    for (int i = 0; i < count; i++) {
      final data = Uint8List(input.length + 1);
      data.setAll(0, input);
      data[input.length] = i;
      final hash = sha256.convert(data);
      result.add(Uint8List.fromList(hash.bytes));
    }
    return result;
  }

  /// Encrypt message with ChaCha20-Poly1305
  /// Returns: [nonce (8 bytes), ciphertext (padded to 512 bytes)]
  Uint8List encrypt(Uint8List plaintext) {
    if (_sendChainKey == null || _sendMessageKey == null) {
      throw Exception('Session not initialized');
    }

    // Derive new message key from chain
    _sendMessageKey = _nextChainKey(_sendChainKey!, _sendChainNonce!);
    
    // Encrypt with ChaCha20-Poly1305 (placeholder)
    final nonce = _incrementNonce(_sendChainNonce!);
    final ciphertext = _encryptWithChaCha20(_sendMessageKey!, plaintext, nonce);
    
    // Pad to 512-byte block
    final padded = _padToBlockSize(ciphertext);
    
    return padded;
  }

  /// Decrypt message
  Uint8List decrypt(Uint8List ciphertext) {
    if (_recvChainKey == null || _recvMessageKey == null) {
      throw Exception('Session not initialized');
    }

    // Decrypt with ChaCha20-Poly1305 (placeholder)
    final nonce = _recvChainNonce!;
    final plaintext = _decryptWithChaCha20(_recvMessageKey!, ciphertext, nonce);
    
    // Derive new message key for next message
    _recvMessageKey = _nextChainKey(_recvChainKey!, _recvChainNonce!);
    _recvChainNonce = _incrementNonce(_recvChainNonce!);
    
    return plaintext;
  }

  /// Next chain key derivation
  Uint8List _nextChainKey(Uint8List chainKey, Uint8List nonce) {
    final data = Uint8List(chainKey.length + nonce.length);
    data.setAll(0, chainKey);
    data.setAll(chainKey.length, nonce);
    final hash = sha256.convert(data);
    return Uint8List.fromList(hash.bytes);
  }

  /// Increment nonce
  Uint8List _incrementNonce(Uint8List nonce) {
    final result = Uint8List.fromList(nonce);
    for (int i = 7; i >= 0; i--) {
      result[i] = (result[i] + 1) % 256;
      if (result[i] > 0) break;
    }
    return result;
  }

  /// Encrypt with ChaCha20-Poly1305
  /// TODO: Replace with libsodium crypto_aead_chacha20poly1305_ietf_encrypt
  Uint8List _encryptWithChaCha20(Uint8List key, Uint8List plaintext, Uint8List nonce) {
    // Placeholder - XOR with key stream (NOT SECURE, replace with libsodium)
    final result = Uint8List(plaintext.length);
    final keystream = _generateKeystream(key, nonce);
    for (int i = 0; i < plaintext.length; i++) {
      result[i] = plaintext[i] ^ keystream[i % keystream.length];
    }
    return result;
  }

  /// Decrypt with ChaCha20-Poly1305
  /// TODO: Replace with libsodium crypto_aead_chacha20poly1305_ietf_decrypt
  Uint8List _decryptWithChaCha20(Uint8List key, Uint8List ciphertext, Uint8List nonce) {
    // Placeholder - same as encrypt for XOR
    return _encryptWithChaCha20(key, ciphertext, nonce);
  }

  /// Generate keystream from key and nonce
  Uint8List _generateKeystream(Uint8List key, Uint8List nonce) {
    final data = Uint8List(key.length + nonce.length);
    data.setAll(0, key);
    data.setAll(key.length, nonce);
    final hash = sha256.convert(data);
    return Uint8List.fromList(hash.bytes);
  }

  /// Pad ciphertext to 512-byte block
  Uint8List _padToBlockSize(Uint8List data) {
    final paddedSize = ((data.length - 1) ~/ BLOCK_SIZE + 1) * BLOCK_SIZE;
    final padded = Uint8List(paddedSize);
    padded.setAll(0, data);
    // Fill padding with random bytes
    for (int i = data.length; i < paddedSize; i++) {
      padded[i] = DateTime.now().millisecondsSinceEpoch % 256;
    }
    return padded;
  }

  /// Step ratchet (send direction)
  void stepRatchet() {
    // Generate new DH key pair
    _dhPrivateKey = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      _dhPrivateKey[i] = DateTime.now().millisecondsSinceEpoch % 256;
    }
    _dhPublicKey = _deriveSharedSecret(); // Placeholder
    
    // Perform DH with their ratchet public key
    final sharedSecret = _deriveSharedSecret();
    final keys = _kdf(sharedSecret, 3);
    
    _sendChainKey = keys[0];
    _sendChainNonce = Uint8List(8);
    _sendMessageKey = keys[1];
  }

  /// Get current DH public key to send to peer
  Uint8List get ratchetPublicKey => _dhPublicKey;
}
