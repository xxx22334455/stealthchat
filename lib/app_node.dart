import 'dart:async';
import 'dart:typed_data';
import 'core/identity_manager.dart';
import 'core/crypto_session.dart';
import 'core/relay_pool.dart';
import 'core/peer_discovery.dart';
import 'core/message_router.dart';
import 'core/traffic_obfuscator.dart';
import 'storage/encrypted_storage.dart';
import 'config/constants.dart';

/// Main application node - coordinates all components
class StealthChatNode {
  final IdentityManager _identityManager;
  final EncryptedStorage _storage;
  late final RelayPool _relayPool;
  late final PeerDiscovery _peerDiscovery;
  late final MessageRouter _messageRouter;
  late final TrafficObfuscator _trafficObfuscator;

  final Map<String, CryptoSession> _sessions = {};

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
        _onPeerDisconnected = onPeerDisconnected {
    _initializeComponents();
  }

  void _initializeComponents() {
    _relayPool = RelayPool(
      onMessage: _handleRelayMessage,
      onRelayConnected: _onPeerConnected,
      onRelayDisconnected: _onPeerDisconnected,
    );
    _peerDiscovery = PeerDiscovery(
      onGossipOut: (data) => _relayPool.broadcast(data),
    );
    _messageRouter = MessageRouter(
      onSend: _sendThroughRelay,
    );
    _trafficObfuscator = TrafficObfuscator(
      onSend: (data) => _relayPool.broadcast(data),
    );
  }

  Future<void> start() async {
    if (_isRunning) return;

    await _identityManager.initialize();
    await _storage.initialize();

    await _relayPool.connectToSeeds();
    _trafficObfuscator.start();

    _isRunning = true;
  }

  Future<void> stop() async {
    if (!_isRunning) return;

    _trafficObfuscator.stop();
    _relayPool.disconnectAll();
    await _storage.close();

    _isRunning = false;
  }

  Future<void> sendMessage(String peerId, String text) async {
    final plaintext = Uint8List.fromList(text.codeUnits);
    _messageRouter.sendMessage(peerId, plaintext);
    _trafficObfuscator.onRealMessageSent();
  }

  Future<void> addContact(String peerId, String name, Uint8List publicKey) async {
    await _storage.saveContact(peerId, name, publicKey);
    _peerDiscovery.addPeer(peerId, '', publicKey);
  }

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
        break;
      default:
        break;
    }
  }

  void _handleRealMessage(Uint8List encryptedData) {
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

  void _sendThroughRelay(Uint8List data, String? targetPeerId) {
    _relayPool.broadcast(data);
  }

  void establishSession(String peerId, Uint8List theirPublicKey) {
    final session = CryptoSession(
      myPrivateKey: _identityManager.x25519PrivateKey,
      myPublicKey: _identityManager.x25519PublicKey,
      theirPublicKey: theirPublicKey,
    );
    _sessions[peerId] = session;
    _messageRouter.establishSession(peerId, theirPublicKey);
  }

  PeerInfo? getPeerInfo(String peerId) {
    return _peerDiscovery.getPeer(peerId);
  }

  Map<String, PeerInfo> get knownPeers => _peerDiscovery.knownPeers;

  bool get isRunning => _isRunning;
  String get peerId => _identityManager.peerId;
}
