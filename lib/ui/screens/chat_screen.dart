import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/identity_manager.dart';
import '../../core/crypto_session.dart';
import '../../core/message_padding.dart';
import '../../config/constants.dart';

class ChatScreen extends StatefulWidget {
  final IdentityManager identityManager;
  final String peerId;
  final String peerName;

  const ChatScreen({
    super.key,
    required this.identityManager,
    required this.peerId,
    required this.peerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _messages = <ChatMessage>[];
  CryptoSession? _session;

  @override
  void initState() {
    super.initState();
    // TODO: Initialize or load crypto session
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isMine: true,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
      ));
    });

    _messageController.clear();

    // TODO: Encrypt and send
    _markAsSent();
  }

  void _markAsSent() {
    setState(() {
      if (_messages.isNotEmpty) {
        _messages.last = _messages.last.copyWith(status: MessageStatus.sent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showPeerInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return MessageBubble(message: _messages[index]);
              },
            ),
          ),
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  void _showPeerInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Peer Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${widget.peerName}'),
            const SizedBox(height: 8),
            Text('Peer ID:'),
            SelectionArea(
              child: Text(
                widget.peerId,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isMine;
  final DateTime timestamp;
  final MessageStatus status;

  ChatMessage({
    required this.text,
    required this.isMine,
    required this.timestamp,
    required this.status,
  });

  ChatMessage copyWith({
    String? text,
    bool? isMine,
    DateTime? timestamp,
    MessageStatus? status,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isMine: isMine ?? this.isMine,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}

enum MessageStatus { sending, sent, delivered, read }

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isMine
              ? Theme.of(context).primaryColor
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: Theme.of(context).textTheme.caption,
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case MessageStatus.sent:
        return Icon(Icons.check, size: 16);
      case MessageStatus.delivered:
        return Icon(Icons.check_double, size: 16);
      case MessageStatus.read:
        return Icon(Icons.check_double, size: 16, color: Colors.blue);
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
