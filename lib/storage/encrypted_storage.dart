import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:typed_data';

/// Encrypted database storage for messages and contacts
class EncryptedStorage {
  Database? _database;
  final String _encryptionKey;

  EncryptedStorage({required String encryptionKey})
      : _encryptionKey = encryptionKey;

  Future<void> initialize() async {
    final path = await _getDatabasePath();
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      // TODO: Enable SQLCipher encryption
      // This requires sqflite_sqlcipher package
    );
  }

  Future<String> _getDatabasePath() async {
    final directory = await getDatabasesPath();
    return join(directory, 'stealthchat.db');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts (
        peer_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        public_key BLOB NOT NULL,
        added_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chats (
        peer_id TEXT PRIMARY KEY,
        last_message TEXT,
        last_updated INTEGER NOT NULL,
        FOREIGN KEY (peer_id) REFERENCES contacts(peer_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chat_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        content_encrypted BLOB NOT NULL,
        nonce BLOB,
        timestamp INTEGER NOT NULL,
        is_read INTEGER DEFAULT 0,
        FOREIGN KEY (chat_id) REFERENCES chats(peer_id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_chat ON messages(chat_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_timestamp ON messages(timestamp)
    ''');
  }

  Future<void> saveContact(String peerId, String name, Uint8List publicKey) async {
    await _database!.insert(
      'contacts',
      {
        'peer_id': peerId,
        'name': name,
        'public_key': publicKey,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getContact(String peerId) async {
    final results = await _database!.query(
      'contacts',
      where: 'peer_id = ?',
      whereArgs: [peerId],
    );
    return results.isEmpty ? null : results.first;
  }

  Future<List<Map<String, dynamic>>> getAllContacts() async {
    return await _database!.query('contacts', orderBy: 'name ASC');
  }

  Future<void> saveMessage({
    required String chatId,
    required String senderId,
    required Uint8List contentEncrypted,
    Uint8List? nonce,
  }) async {
    await _database!.insert(
      'messages',
      {
        'chat_id': chatId,
        'sender_id': senderId,
        'content_encrypted': contentEncrypted,
        'nonce': nonce,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'is_read': 0,
      },
    );

    // Update chat last message
    await _database!.insert(
      'chats',
      {
        'peer_id': chatId,
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    return await _database!.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
  }

  Future<void> markMessagesAsRead(String chatId) async {
    await _database!.rawUpdate(
      'UPDATE messages SET is_read = 1 WHERE chat_id = ? AND is_read = 0',
      [chatId],
    );
  }

  Future<List<Map<String, dynamic>>> getChats() async {
    return await _database!.query(
      'chats',
      orderBy: 'last_updated DESC',
    );
  }

  Future<void> close() async {
    await _database?.close();
  }
}
