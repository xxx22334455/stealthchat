import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'core/identity_manager.dart';
import 'core/crypto_session.dart';
import 'core/relay_pool.dart';
import 'core/peer_discovery.dart';
import 'core/message_router.dart';
import 'core/traffic_obfuscator.dart';
import 'network/wss_client.dart';
import 'network/wss_server.dart';
import 'storage/encrypted_storage.dart';
import 'config/constants.dart';

/// Main application node - coordinates all components
class StealthChatNode {
  final IdentityManager _identityManager;
  final EncryptedStorage _storage;
  final RelayPool _relayPool;
  final PeerDiscovery _peerDiscovery;
  final MessageRouter _messageRouter;
  final TrafficObfuscator _trafficObfuscator;
  WssServer? _server;

  // Sessions
  final Map<String, CryptoSession> _sessions = {};

  // Callbacks
  final Function(String peerId, String message)? _onMessageReceived;
  final Function(String peerId)? _onPeerConnected;
  final Function(String peerId)? _onPeerDisconnected;

  bool _isRunning = false;

  StealthChatNode({
    required IdentityManager identityManager,
    required EncryptedStorage storage,
    Function(String peerId, String message)? onMessageReceived,
    Function(String peerId)? onPeerConnected,
    Function(String peerId)? onPeerDisconnected,
  })  : _identityManager = identityManager,
        _storage = storage,
        _onMessageReceived = onMessageReceived,
        _onPeerConnected = onPeerConnected,
        _onPeerDisconnected = onPeerDisconnected,
        _relayPool = RelayPool(
          onMessage: _handleRelayMessage,
          onRelayConnected: (id) => _onPeerConnected?.call(id),
          onRelayDisconnected: (id) => _onPeerDisconnected?.call(id),
        ),
        _peerDiscovery = PeerDiscovery(
          onGossipOut: (data) => _relayPool.broadcast(data),
        ),
        _messageRouter = MessageRouter(
          onSend: (data, target) => _sendThroughRelay(data, target),
        ),
        _trafficObfuscator = TrafficObfuscator(
          onSend: (data) => _relayPool.broadcast(data),
        );

  /// Initialize and start the node
  Future<void> start() async {
    if (_isRunning) return;

    await _identityManager.initialize();
    await _storage.initialize();

    // Connect to seed nodes
    await _relayPool.connectToSeeds();

    // Start traffic obfuscation
    _trafficObfuscator.start();

    _isRunning = true;
  }

  /// Stop the node
  Future<void> stop() async {
    if (!_isRunning) return;

    _trafficObfuscator.stop();
    _relayPool.disconnectAll();
    _server?.stop();
    await _storage.close();

    _isRunning = false;
  }

  /// Start relay server (optional)
  Future<void> startRelay({
    required X509Certificate certificate,
    required PrivateKey privateKey,
  }) async {
    _server = WssServer(
      certificate: certificate,
      privateKey: privateKey,
      onMessage: _handleRelayMessage,
      onClientConnected: (client) {
        // TODO: Handle new client connection
      },
      onClientDisconnected: (client) {
        // TODO: Handle client disconnection
      },
    );

    await _server!.start();
  }

  /// Send message to peer
  Future<void> sendMessage(String peerId, String text) async {
    final plaintext = Uint8List.fromList(text.codeUnits);
    _messageRouter.sendMessage(peerId, plaintext);
    _trafficObfuscator.onRealMessageSent();
  }

  /// Add contact
  Future<void> addContact(String peerId, String name, Uint8List publicKey) async {
    await _storage.saveContact(peerId, name, publicKey);
    _peerDiscovery.addPeer(peerId, '', publicKey);
    
    // TODO: Initiate key exchange
  }

  /// Handle incoming message from relay
  void _handleRelayMessage(String fromAddress, Uint8List data) {
    if (data.length < 1) return;

    final messageType = data[0];

    switch (messageType) {
      case MessageType.realData:
        _handleRealMessage(data.sublist(1));
        break;
      case MessageType.gossip:
        _peerDiscovery.handlePeerInfo(data.sublist(1));
        break;
      case MessageType.dummy:
        // Ignore dummy traffic
        break;
      default:
        // Unknown message type
        break;
    }
  }

  /// Handle real encrypted message
  void _handleRealMessage(Uint8List encryptedData) {
    // TODO: Determine which session to use
    // For now, try all sessions
    for (final entry in _sessions.entries) {
      try {
        final decrypted = entry.value.decrypt(encryptedData);
        final text = String.fromCharCodes(decrypted);
        _onMessageReceived?.call(entry.key, text);
        break;
      } catch (e) {
        // Try next session
      }
    }
  }

  /// Send through relay
  void _sendThroughRelay(Uint8List data, String? targetPeerId) {
    if (targetPeerId != null) {
      // TODO: Find relay for target peer
      _relayPool.broadcast(data);
    } else {
      _relayPool.broadcast(data);
    }
  }

  /// Establish session with peer
  void establishSession(String peerId, Uint8List theirPublicKey) {
    final session = CryptoSession(
      myPrivateKey: _identityManager.x25519PrivateKey,
      myPublicKey: _identityManager.x25519PublicKey,
      theirPublicKey: theirPublicKey,
    );
    _sessions[peerId] = session;
    _messageRouter.establishSession(peerId, theirPublicKey);
  }

  /// Get peer info
  PeerInfo? getPeerInfo(String peerId) {
    return _peerDiscovery.getPeer(peerId);
  }

  /// Get known peers
  Map<String, PeerInfo> get knownPeers => _peerDiscovery.knownPeers;

  bool get isRunning => _isRunning;
  String get peerId => _identityManager.peerId;
}
