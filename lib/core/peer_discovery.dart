import 'dart:typed_data';
import '../config/constants.dart';

/// Peer discovery via gossip protocol inside WSS tunnels
/// No UDP or DHT - all discovery happens over encrypted WSS
class PeerDiscovery {
  // Known peers: peerId -> {address, publicKey, lastSeen}
  final Map<String, PeerInfo> _knownPeers = {};

  // Callbacks
  final Function(String peerId, PeerInfo info)? _onPeerFound;
  final Function(Uint8List gossipData)? _onGossipOut;

  PeerDiscovery({
    Function(String peerId, PeerInfo info)? onPeerFound,
    Function(Uint8List gossipData)? onGossipOut,
  })  : _onPeerFound = onPeerFound,
        _onGossipOut = onGossipOut;

  /// Add a known peer
  void addPeer(String peerId, String address, Uint8List publicKey) {
    _knownPeers[peerId] = PeerInfo(
      peerId: peerId,
      address: address,
      publicKey: publicKey,
      lastSeen: DateTime.now(),
    );

    // Propagate to other peers via gossip
    _propagatePeer(peerId);
  }

  /// Look up peer by ID
  PeerInfo? getPeer(String peerId) {
    return _knownPeers[peerId];
  }

  /// Request peer info from connected relays
  void requestPeer(String peerId) {
    final request = _buildRequestMessage(peerId);
    _onGossipOut?.call(request);
  }

  /// Handle incoming peer info
  void handlePeerInfo(Uint8List data) {
    // Parse peer info from gossip message
    // TODO: Implement parsing
  }

  /// Propagate peer info via gossip
  void _propagatePeer(String peerId) {
    final peer = _knownPeers[peerId];
    if (peer == null) return;

    final gossipData = _buildGossipMessage(peer);
    _onGossipOut?.call(gossipData);
  }

  /// Build gossip message
  Uint8List _buildGossipMessage(PeerInfo peer) {
    // Format: [peerId length (2)][peerId][address length (2)][address][publicKey (32)]
    final peerIdBytes = Uint8List.fromList(peer.peerId.codeUnits);
    final addressBytes = Uint8List.fromList(peer.address.codeUnits);

    final data = Uint8List(2 + peerIdBytes.length + 2 + addressBytes.length + 32);
    int offset = 0;

    // Peer ID
    data[offset] = (peerIdBytes.length >> 8) & 0xFF;
    data[offset + 1] = peerIdBytes.length & 0xFF;
    offset += 2;
    data.setAll(offset, peerIdBytes);
    offset += peerIdBytes.length;

    // Address
    data[offset] = (addressBytes.length >> 8) & 0xFF;
    data[offset + 1] = addressBytes.length & 0xFF;
    offset += 2;
    data.setAll(offset, addressBytes);
    offset += addressBytes.length;

    // Public key
    data.setAll(offset, peer.publicKey);

    return data;
  }

  /// Build peer request message
  Uint8List _buildRequestMessage(String peerId) {
    final peerIdBytes = Uint8List.fromList(peerId.codeUnits);
    final data = Uint8List(2 + peerIdBytes.length);

    data[0] = (peerIdBytes.length >> 8) & 0xFF;
    data[1] = peerIdBytes.length & 0xFF;
    data.setAll(2, peerIdBytes);

    return data;
  }

  /// Clean up stale peers
  void cleanupStalePeers(int maxAgeSeconds) {
    final now = DateTime.now();
    final toRemove = <String>[];

    for (final entry in _knownPeers.entries) {
      final age = now.difference(entry.value.lastSeen).inSeconds;
      if (age > maxAgeSeconds) {
        toRemove.add(entry.key);
      }
    }

    for (final peerId in toRemove) {
      _knownPeers.remove(peerId);
    }
  }

  /// Get all known peers
  Map<String, PeerInfo> get knownPeers => Map.unmodifiable(_knownPeers);

  /// Get peer count
  int get peerCount => _knownPeers.length;
}

/// Peer information
class PeerInfo {
  final String peerId;
  final String address;
  final Uint8List publicKey;
  final DateTime lastSeen;

  PeerInfo({
    required this.peerId,
    required this.address,
    required this.publicKey,
    required this.lastSeen,
  });

  /// Update last seen time
  PeerInfo refresh() {
    return PeerInfo(
      peerId: peerId,
      address: address,
      publicKey: publicKey,
      lastSeen: DateTime.now(),
    );
  }
}
