/// Seed nodes for initial peer discovery
/// Format: {'peerId': 'wss://host:443/ws'}
/// In production, these should be updated via gossip protocol
class SeedNodes {
  static const Map<String, String> seeds = {
    // Add initial seed nodes here
    // Example: 'peer_id_here': 'wss://relay.example.com:443/ws'
  };

  /// Get all seed addresses
  static List<String> getAddresses() => seeds.values.toList();

  /// Get seed for specific peer ID
  static String? getAddressForPeer(String peerId) => seeds[peerId];
}
