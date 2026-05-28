import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../core/crypto_session.dart';
import '../core/message_padding.dart';
import '../config/constants.dart';

/// Routes messages through the network with encryption and padding
class MessageRouter {
  final Map<String, CryptoSession> _sessions = {};
  final Function(Uint8List data, String? targetPeerId)? _onSend;

  MessageRouter({required Function(Uint8List data, String? targetPeerId) onSend})
      : _onSend = onSend;

  /// Send encrypted message to peer
  void sendMessage(String peerId, Uint8List plaintext) {
    // Get or create session
    var session = _sessions[peerId];
    if (session == null) {
      // TODO: Initialize session with peer's public key
      // session = CryptoSession(...);
      // _sessions[peerId] = session;
      throw Exception('Session not established with peer: $peerId');
    }

    // Encrypt message
    final encrypted = session.encrypt(plaintext);

    // Pad to 512-byte blocks
    final padded = MessagePadding.pad(encrypted);

    // Prepend message type
    final message = Uint8List(1 + padded.length);
    message[0] = MessageType.realData;
    message.setAll(1, padded);

    // Send through relay pool
    _onSend!(message, peerId);
  }

  /// Receive and decrypt message
  Uint8List? receiveMessage(String fromPeerId, Uint8List data) {
    if (data.length < 1) return null;

    final messageType = data[0];
    if (messageType != MessageType.realData) return null;

    // Get or create session
    var session = _sessions[fromPeerId];
    if (session == null) {
      // TODO: Initialize session
      throw Exception('Session not established with peer: $fromPeerId');
    }

    // Remove padding and decrypt
    final padded = data.sublist(1);
    final decrypted = session.decrypt(padded);

    return decrypted;
  }

  /// Send gossip message (peer discovery)
  void sendGossip(Uint8List data) {
    final padded = MessagePadding.pad(data);
    final message = Uint8List(1 + padded.length);
    message[0] = MessageType.gossip;
    message.setAll(1, padded);

    _onSend!(message, null); // Broadcast to all connected peers
  }

  /// Handle incoming gossip message
  void handleGossip(Uint8List data) {
    if (data.length < 1) return;

    final messageType = data[0];
    if (messageType != MessageType.gossip) return;

    // Process gossip data
    final gossipData = data.sublist(1);
    // TODO: Update peer discovery with new peer info
  }

  /// Establish session with peer
  void establishSession(String peerId, Uint8List theirPublicKey) {
    // TODO: Initialize crypto session
    // session = CryptoSession(myPrivateKey: ..., myPublicKey: ..., theirPublicKey: theirPublicKey);
    // _sessions[peerId] = session;
  }

  /// Get session for peer
  CryptoSession? getSession(String peerId) {
    return _sessions[peerId];
  }
}

/// Onion routing implementation for enhanced anonymity
class OnionRouter {
  final int _chainLength = ONION_CHAIN_LENGTH;

  /// Build onion-encrypted message
  /// Layers: [outermost (relay 3)][relay 2][innermost (relay 1 -> final destination)]
  Uint8List buildOnion(Uint8List payload, List<OnionLayer> layers) {
    var current = payload;

    // Wrap payload in layers (reverse order)
    for (int i = layers.length - 1; i >= 0; i--) {
      final layer = layers[i];
      current = _encryptLayer(current, layer);
    }

    return current;
  }

  /// Peel one layer from onion
  (Uint8List, String)? peelOnion(Uint8List onion, Uint8List myPrivateKey) {
    // TODO: Decrypt layer with private key
    // Returns (decrypted payload, next hop peer ID)
    return null;
  }

  /// Encrypt a single onion layer
  Uint8List _encryptLayer(Uint8List payload, OnionLayer layer) {
    // TODO: Encrypt with relay's public key
    // Include next hop information in plaintext portion
    return payload;
  }
}

/// Represents one layer of onion routing
class OnionLayer {
  final String relayPeerId;
  final Uint8List relayPublicKey;
  final String? nextHopPeerId; // Null for final layer

  OnionLayer({
    required this.relayPeerId,
    required this.relayPublicKey,
    this.nextHopPeerId,
  });
}
