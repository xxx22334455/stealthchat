import 'package:flutter/material.dart';
import '../../core/identity_manager.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final IdentityManager identityManager;
  const ChatListScreen({super.key, required this.identityManager});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  // TODO: Load from database
  final List<ChatItem> _chats = [];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StealthChat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _addContact,
            tooltip: 'Add Contact',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
            tooltip: 'Settings',
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
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan QR code or enter peer ID to add contacts',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(_chats[index].name[0].toUpperCase()),
                  ),
                  title: Text(_chats[index].name),
                  subtitle: Text(_chats[index].lastMessage),
                  trailing: Text(
                    _chats[index].timestamp,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          identityManager: widget.identityManager,
                          peerId: _chats[index].peerId,
                          peerName: _chats[index].name,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ChatItem {
  final String peerId;
  final String name;
  final String lastMessage;
  final String timestamp;

  ChatItem({
    required this.peerId,
    required this.name,
    required this.lastMessage,
    required this.timestamp,
  });
}

class AddContactDialog extends StatelessWidget {
  const AddContactDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final _controller = TextEditingController();

    return AlertDialog(
      title: const Text('Add Contact'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter peer ID or scan QR code'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'stealthchat://...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // TODO: Add contact
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
    return AlertDialog(
      title: const Text('Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Peer ID:'),
          SelectionArea(
            child: Text(
              identityManager.exportPublicKeyString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Network Settings:'),
          SwitchListTile(
            title: const Text('Act as Relay'),
            subtitle: const Text('Allow others to route through you'),
            value: false,
            onChanged: (value) {},
          ),
          SwitchListTile(
            title: const Text('Onion Routing'),
            subtitle: const Text('Route through 3 hops for anonymity'),
            value: true,
            onChanged: (value) {},
          ),
        ],
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
