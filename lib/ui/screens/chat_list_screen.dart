import 'package:flutter/material.dart';
import '../../app_node.dart';
import '../../core/identity_manager.dart';
import '../theme/telegram_theme.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final IdentityManager identityManager;
  const ChatListScreen({super.key, required this.identityManager});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  StealthChatNode? _node;
  final List<ChatItem> _chats = [];

  @override
  void initState() {
    super.initState();
    _initializeNode();
  }

  Future<void> _initializeNode() async {
    // TODO: Initialize with storage
  }

  void _handleMessageReceived(String peerId, String message) {
    // TODO: Update chat list
  }

  void _addContact() {
    showDialog(
      context: context,
      builder: (context) => const AddContactDialog(),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        identityManager: widget.identityManager,
      ),
    );
  }

  void _showSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SearchSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chats',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _addContact,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: _chats.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: TelegramColors.lightTextSecondary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Chats Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add contacts to start chatting',
                    style: TextStyle(
                      color: TelegramColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _addContact,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Add Contact'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {},
              child: ListView.builder(
                itemCount: _chats.length,
                itemBuilder: (context, index) {
                  final chat = _chats[index];
                  return TelegramChatTile(
                    chat: chat,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            identityManager: widget.identityManager,
                            peerId: chat.peerId,
                            peerName: chat.name,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addContact,
        icon: const Icon(Icons.add),
        label: const Text('New Chat'),
      ),
    );
  }
}

class TelegramChatTile extends StatelessWidget {
  final ChatItem chat;
  final VoidCallback onTap;

  const TelegramChatTile({
    super.key,
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: TelegramColors.lightPrimary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            chat.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Text(
        chat.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        chat.lastMessage,
        style: TextStyle(
          color: TelegramColors.lightTextSecondary,
          overflow: TextOverflow.ellipsis,
        ),
        maxLines: 1,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            chat.timestamp,
            style: TextStyle(
              color: TelegramColors.lightTextSecondary,
              fontSize: 12,
            ),
          ),
          if (chat.unreadCount > 0)
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: TelegramColors.lightPrimary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  chat.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class SearchSheet extends StatelessWidget {
  const SearchSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Scan QR Code'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Add by Username'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class ChatItem {
  final String peerId;
  final String name;
  final String lastMessage;
  final String timestamp;
  final int unreadCount;

  ChatItem({
    required this.peerId,
    required this.name,
    required this.lastMessage,
    required this.timestamp,
    this.unreadCount = 0,
  });
}

class AddContactDialog extends StatelessWidget {
  const AddContactDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final _controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.person_add, color: TelegramColors.lightPrimary),
          const SizedBox(width: 8),
          const Text('Add Contact'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: TelegramColors.lightPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.qr_code_scanner),
            ),
            title: const Text('Scan QR Code'),
            subtitle: const Text('Scan contact\'s QR code'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Or enter peer ID manually'),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'stealthchat://...',
              prefixIcon: const Icon(Icons.code),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class SettingsDialog extends StatelessWidget {
  final IdentityManager identityManager;
  const SettingsDialog({super.key, required this.identityManager});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.settings, color: TelegramColors.lightPrimary),
          const SizedBox(width: 8),
          const Text('Settings'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TelegramColors.lightPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Peer ID',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  SelectionArea(
                    child: Text(
                      identityManager.exportPublicKeyString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Privacy & Security',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              secondary: const Icon(Icons.lock),
              title: const Text('Onion Routing'),
              subtitle: const Text('Route through 3 hops'),
              value: true,
              onChanged: (value) {},
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              secondary: const Icon(Icons.shield),
              title: const Text('Disappearing Messages'),
              subtitle: const Text('Auto-delete after 24h'),
              value: false,
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            const Text(
              'Network',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              secondary: const Icon(Icons.router),
              title: const Text('Act as Relay'),
              subtitle: const Text('Allow routing through you'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
