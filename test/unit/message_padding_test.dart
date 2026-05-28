import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:stealthchat/core/message_padding.dart';
import 'package:stealthchat/config/constants.dart';

void main() {
  group('MessagePadding', () {
    test('pads empty message to one block', () {
      final empty = Uint8List(0);
      final padded = MessagePadding.pad(empty);
      expect(padded.length, BLOCK_SIZE);
    });

    test('pads small message to one block', () {
      final small = Uint8List(10);
      final padded = MessagePadding.pad(small);
      expect(padded.length, BLOCK_SIZE);
    });

    test('pads message to multiple blocks', () {
      final data = Uint8List(BLOCK_SIZE + 100);
      final padded = MessagePadding.pad(data);
      expect(padded.length, 2 * BLOCK_SIZE);
    });

    test('preserves original data', () {
      final original = Uint8List(50);
      for (int i = 0; i < 50; i++) {
        original[i] = i;
      }
      final padded = MessagePadding.pad(original);
      
      for (int i = 0; i < 50; i++) {
        expect(padded[i], original[i]);
      }
    });

    test('creates dummy message of correct size', () {
      final dummy = MessagePadding.createDummyMessage(1);
      expect(dummy.length, BLOCK_SIZE);
      
      final dummy2 = MessagePadding.createDummyMessage(2);
      expect(dummy2.length, 2 * BLOCK_SIZE);
    });
  });

  group('Constants', () {
    test('BLOCK_SIZE is 512', () {
      expect(BLOCK_SIZE, 512);
    });

    test('WSS_PORT is 443', () {
      expect(WSS_PORT, 443);
    });

    test('ONION_CHAIN_LENGTH is 3', () {
      expect(ONION_CHAIN_LENGTH, 3);
    });

    test('MessageType values are correct', () {
      expect(MessageType.realData, 0x01);
      expect(MessageType.dummy, 0x02);
      expect(MessageType.gossip, 0x03);
    });
  });
}
