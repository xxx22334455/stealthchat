import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/identity_manager.dart';
import '../theme/telegram_theme.dart';

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
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
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
    _scrollToBottom();

    // TODO: Encrypt and send
    Future.delayed(const Duration(milliseconds: 500), () {
      _markAsSent();
    });
  }

  void _markAsSent() {
    setState(() {
      if (_messages.isNotEmpty) {
        _messages.last = _messages.last.copyWith(status: MessageStatus.read);
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.peerName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showPeerInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xFF0F0F0F), const Color(0xFF1A1A1A)]
                      : [const Color(0xFFF0F2F5), const Color(0xFFE5E7EB)],
                ),
              ),
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: TelegramColors.lightTextSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              color: TelegramColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return TelegramMessageBubble(
                          message: _messages[index],
                        );
                      },
                    ),
            ),
          ),
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: isDark ? const Color(0xFF212121) : Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF383838) : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Message',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.emoji_emotions),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 24,
            backgroundColor: TelegramColors.lightPrimary,
            child: IconButton(
              icon: Icon(
                _messageController.text.isEmpty ? Icons.mic : Icons.send,
                color: Colors.white,
              ),
              onPressed: _sendMessage,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
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

class TelegramMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const TelegramMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isMine
                    ? (isDark ? TelegramColors.darkMessageOut : TelegramColors.lightMessageOut)
                    : (isDark ? TelegramColors.darkMessageIn : TelegramColors.lightMessageIn),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: TelegramColors.lightTextSecondary,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 2),
                    _buildStatusIcon(isDark),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(bool isDark) {
    final checkColor = message.status == MessageStatus.read
        ? TelegramColors.lightPrimary
        : TelegramColors.lightTextSecondary;
    
    switch (message.status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case MessageStatus.sent:
        return Icon(Icons.check, size: 16, color: checkColor);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 16, color: checkColor);
      case MessageStatus.read:
        return Icon(Icons.done_all, size: 16, color: TelegramColors.lightPrimary);
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
