import 'dart:async';
import 'dart:typed_data';
import '../network/wss_client.dart';
import '../config/constants.dart';
import '../config/seed_nodes.dart';

/// Manages pool of WSS connections to relay peers
class RelayPool {
  final Map<String, WssClient> _relays = {};
  final int _maxRelays = 5;

  // Callbacks
  final Function(String peerId, Uint8List data)? _onMessage;
  final Function(String peerId)? _onRelayConnected;
  final Function(String peerId)? _onRelayDisconnected;

  RelayPool({
    Function(String peerId, Uint8List data)? onMessage,
    Function(String peerId)? onRelayConnected,
    Function(String peerId)? onRelayDisconnected,
  })  : _onMessage = onMessage,
        _onRelayConnected = onRelayConnected,
        _onRelayDisconnected = onRelayDisconnected;

  /// Connect to seed nodes
  Future<void> connectToSeeds() async {
    final addresses = SeedNodes.getAddresses();

    for (final address in addresses) {
      if (_relays.length >= _maxRelays) break;

      await _connectToRelay(address);
    }
  }

  /// Connect to specific relay
  Future<bool> _connectToRelay(String address) async {
    try {
      final client = WssClient(
        url: address,
        onMessage: (data) {
          _onMessage?.call(address, data);
        },
        onConnected: () {
          _relays[address] = client;
          _onRelayConnected?.call(address);
        },
        onError: (error) {
          // Handle error
        },
        onClosed: () {
          _relays.remove(address);
          _onRelayDisconnected?.call(address);
        },
      );

      final success = await client.connect();
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Send message through a relay
  void send(String relayAddress, Uint8List data) {
    final relay = _relays[relayAddress];
    relay?.send(data);
  }

  /// Broadcast message to all relays
  void broadcast(Uint8List data) {
    for (final relay in _relays.values) {
      relay.send(data);
    }
  }

  /// Get available relay addresses
  List<String> get availableRelays => _relays.keys.toList();

  /// Disconnect from all relays
  void disconnectAll() {
    for (final relay in _relays.values) {
      relay.close();
    }
    _relays.clear();
  }

  /// Get relay count
  int get relayCount => _relays.length;
}
