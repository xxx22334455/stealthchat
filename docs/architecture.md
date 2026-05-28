# StealthChat Architecture

## Overview

StealthChat is a decentralized, anti-DPI messenger that masks all traffic as HTTPS/WSS on port 443.

## Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      StealthChat Node                       │
├─────────────────────────────────────────────────────────────┤
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐ │
│  │   Identity     │  │   Storage      │  │    UI          │ │
│  │   Manager      │  │  (SQLite)      │  │  (Flutter)     │ │
│  └────────────────┘  └────────────────┘  └────────────────┘ │
│          │                  │                  │            │
│          v                  v                  v            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                  App Node                             │  │
│  │  (Coordinates all components)                         │  │
│  └──────────────────────────────────────────────────────┘  │
│          │                  │                  │            │
│          v                  v                  v            │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐ │
│  │   Relay        │  │   Peer         │  │   Message      │ │
│  │   Pool         │  │   Discovery    │  │   Router       │ │
│  │  (WSS conns)   │  │   (Gossip)     │  │  (Encryption)  │ │
│  └────────────────┘  └────────────────┘  └────────────────┘ │
│          │                  │                  │            │
│          └──────────────────┼──────────────────┘            │
│                             v                               │
│                  ┌──────────────────┐                       │
│                  │ Traffic          │                       │
│                  │ Obfuscator       │                       │
│                  │ (Dummy packets)  │                       │
│                  └──────────────────┘                       │
│                             │                               │
│                             v                               │
│                  ┌──────────────────┐                       │
│                  │    WSS Client    │                       │
│                  │  (TLS 1.3 port)  │                       │
│                  │        443       │                       │
│                  └──────────────────┘                       │
└─────────────────────────────────────────────────────────────┘
                            │
                            v
                    ┌───────────────┐
                    │   Internet    │
                    │  (TCP 443)    │
                    └───────────────┘
                            │
                    ┌───────────────┐
                    │ Other Nodes   │
                    │  (Relays)     │
                    └───────────────┘
```

## Data Flow

### Sending a Message

1. **User types message** → ChatScreen
2. **Encrypt with Double Ratchet** → CryptoSession
3. **Pad to 512 bytes** → MessagePadding
4. **Add message type byte** → MessageRouter
5. **Send through relay** → RelayPool → WssClient
6. **TLS 1.3 encryption** → Platform TLS stack
7. **TCP packet on port 443** → Network

### Receiving a Message

1. **TCP packet arrives** → Port 443
2. **TLS 1.3 decryption** → Platform TLS stack
3. **WSS frame received** → WssClient
4. **Route by message type** → App Node
5. **Decrypt with Double Ratchet** → CryptoSession
6. **Remove padding** → MessagePadding
7. **Display to user** → ChatScreen

### Dummy Traffic Generation

1. **Timer fires (10-30s)** → TrafficObfuscator
2. **Generate random bytes** → MessagePadding
3. **Add dummy type byte (0x02)** → TrafficObfuscator
4. **Send through relay** → RelayPool
5. **Looks like real traffic** → DPI cannot distinguish

## Anti-DPI Features

### 1. Transport Layer
- **Only TCP port 443** - No UDP, no other ports
- **TLS 1.3** - Latest protocol with perfect forward secrecy
- **System TLS stack** - Browser-like fingerprint (JA3)
- **No custom Client Hello** - Uses platform defaults

### 2. Message Layer
- **Fixed-size padding** - All messages padded to 512-byte blocks
- **Random padding bytes** - Prevents length analysis
- **Message type byte** - 0x01 (real), 0x02 (dummy), 0x03 (gossip)
- **All encrypted** - No plaintext in WebSocket frames

### 3. Traffic Pattern
- **Dummy packets** - Every 10-30 seconds when idle
- **Random intervals** - Prevents timing analysis
- **Persistent connections** - Looks like webmail
- **No burst patterns** - Constant traffic flow

### 4. Peer Discovery
- **No UDP/DHT** - All discovery via WSS gossip
- **Encrypted gossip** - Peer info inside tunnel
- **Seed nodes** - Initial bootstrap, then self-sustaining
- **Onion routing** - Optional 3-hop chains

## File Structure

```
lib/
├── app_node.dart           # Main coordinator
├── core/
│   ├── identity_manager.dart    # Ed25519/X25519 keys
│   ├── crypto_session.dart      # Double Ratchet
│   ├── message_padding.dart     # 512-byte padding
│   ├── traffic_obfuscator.dart  # Dummy traffic
│   ├── message_router.dart      # Routing + onion
│   ├── relay_pool.dart          # WSS connection pool
│   └── peer_discovery.dart      # Gossip protocol
├── network/
│   ├── wss_client.dart          # WSS client (TLS)
│   └── wss_server.dart          # WSS server (relay)
├── storage/
│   └── encrypted_storage.dart   # SQLite (SQLCipher)
├── ui/
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── chat_list_screen.dart
│   │   └── chat_screen.dart
│   └── widgets/
│       └── qr_widgets.dart
└── config/
    ├── constants.dart           # Protocol constants
    └── seed_nodes.dart          # Initial peers
```

## Security Considerations

### Cryptography
- **Ed25519** - Digital signatures (placeholder: SHA256)
- **X25519** - Key exchange (placeholder: SHA256)
- **ChaCha20-Poly1305** - AEAD encryption (placeholder: XOR)
- **TODO**: Replace placeholders with libsodium FFI

### Key Management
- **Long-term keys** - Stored in encrypted SQLite
- **Session keys** - Double Ratchet with forward secrecy
- **Key exchange** - Via WSS tunnel after connection

### Threat Model
- **DPI** - Cannot distinguish from HTTPS traffic
- **Network observer** - Sees only encrypted TLS packets
- **Relay operator** - Cannot see message content (E2EE)
- **Offline attacker** - Cannot decrypt without keys

## Future Enhancements

1. **libsodium FFI** - Replace crypto placeholders
2. **SQLCipher** - Enable database encryption
3. **Onion routing** - Complete 3-hop implementation
4. **File transfer** - Chunked encrypted uploads
5. **Group chats** - Sender Key algorithm
6. **Notifications** - Platform-specific push
7. **Yggdrasil integration** - Alternative transport
8. **Domain fronting** - CDN-based obfuscation

## Testing

```bash
# Unit tests
flutter test test/unit/

# Anti-DPI tests
flutter test test/anti_dpi/

# Traffic capture
tcpdump -i any -w capture.pcap port 443

# JA3 fingerprint
python3 ja3_client.py < captured_tls.pcap
```
