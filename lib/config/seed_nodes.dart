/// Seed nodes for initial peer discovery
/// Format: {'peerId': 'wss://host:443/ws'}
class SeedNodes {
  static const Map<String, String> seeds = {
    'relay_1': 'wss://46.36.221.136:443/ws',
  };

  static List<String> getAddresses() => seeds.values.toList();

  static String? getAddressForPeer(String peerId) => seeds[peerId];
}
