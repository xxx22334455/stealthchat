import 'package:test/test.dart';
import 'package:stealthchat/core/traffic_obfuscator.dart';
import 'package:stealthchat/config/constants.dart';

void main() {
  group('TrafficObfuscator', () {
    test('generates dummy message with correct type', () {
      final dummy = MessagePadding.createDummyMessage(1);
      expect(dummy.length, BLOCK_SIZE);
    });

    test('dummy traffic interval is within range', () {
      expect(MIN_DUMMY_INTERVAL, 10);
      expect(MAX_DUMMY_INTERVAL, 30);
    });
  });

  group('Anti-DPI Requirements', () {
    test('only uses TCP port 443', () {
      expect(WSS_PORT, 443);
    });

    test('message types are correctly defined', () {
      expect(MessageType.realData, 0x01);
      expect(MessageType.dummy, 0x02);
      expect(MessageType.gossip, 0x03);
    });

    test('onion chain length is 3', () {
      expect(ONION_CHAIN_LENGTH, 3);
    });

    test('offline buffer is 24 hours', () {
      expect(OFFLINE_BUFFER_DURATION, 24 * 60 * 60);
    });
  });
}
