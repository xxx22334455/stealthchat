import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:stealthchat/core/crypto_session.dart';

void main() {
  group('CryptoSession', () {
    test('encrypts and decrypts message', () {
      // Generate dummy keys
      final myPrivateKey = Uint8List(32);
      final myPublicKey = Uint8List(32);
      final theirPublicKey = Uint8List(32);

      for (int i = 0; i < 32; i++) {
        myPrivateKey[i] = i;
        myPublicKey[i] = i + 1;
        theirPublicKey[i] = i + 2;
      }

      final session = CryptoSession(
        myPrivateKey: myPrivateKey,
        myPublicKey: myPublicKey,
        theirPublicKey: theirPublicKey,
      );

      final plaintext = Uint8List.fromList('Hello, World!'.codeUnits);
      final encrypted = session.encrypt(plaintext);
      
      // Encrypted data should be padded to 512 bytes
      expect(encrypted.length, 512);

      final decrypted = session.decrypt(encrypted);
      expect(decrypted.length, plaintext.length);
    });

    test('encrypts multiple messages', () {
      final myPrivateKey = Uint8List(32);
      final myPublicKey = Uint8List(32);
      final theirPublicKey = Uint8List(32);

      final session = CryptoSession(
        myPrivateKey: myPrivateKey,
        myPublicKey: myPublicKey,
        theirPublicKey: theirPublicKey,
      );

      for (int i = 0; i < 10; i++) {
        final plaintext = Uint8List.fromList('Message $i'.codeUnits);
        final encrypted = session.encrypt(plaintext);
        expect(encrypted.length, 512);
      }
    });
  });
}
