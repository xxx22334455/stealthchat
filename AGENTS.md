# AGENTS.md - StealthChat Development Guide

## Project Overview
Децентрализованный защищённый мессенджер с анти-DPI обфускацией. Весь трафик маскируется под HTTPS/WSS на порту 443.

## Critical Requirements
- **NO UDP** - only TCP port 443
- **TLS 1.3** with browser-like fingerprint (use system TLS stack, no custom Client Hello)
- **All messages padded** to 512-byte blocks before encryption
- **Dummy traffic** every 10-30 seconds when idle
- **E2E encryption** with Double Ratchet (libsodium via FFI)
- **No plaintext in handshakes** - all peer info inside encrypted tunnel

## Tech Stack
- **Framework**: Flutter + Dart
- **Crypto**: libsodium (FFI) - Ed25519, X25519, ChaCha20-Poly1305
- **Network**: `web_socket_channel` with platform TLS
- **Storage**: `sqflite_sqlcipher` (encrypted SQLite)
- **Platforms**: Android, Linux, Windows

## Core Components
```
lib/
  core/
    identity_manager.dart    # Ed25519 keys, local auth
    crypto_session.dart       # Double Ratchet
    peer_discovery.dart       # Gossip protocol inside WSS
    relay_pool.dart           # WSS connection pool
    message_router.dart       # Serialization, padding, onion
    traffic_obfuscator.dart   # Dummy traffic generator
  network/
    wss_client.dart           # WebSocket client with TLS
    wss_server.dart           # WebSocket server (relay)
  ui/
    # Flutter screens
```

## Development Commands
```bash
# Setup
flutter pub get

# Run platform
flutter run -d chrome        # Development
flutter run -d android       # Android
flutter run -d linux         # Linux

# Testing
flutter test
flutter test --plain-name "test name"  # Single test

# Code quality
dart analyze
flutter pub run dart_code_metrics:metrics analyze lib

# Build
flutter build apk --release
flutter build linux --release
flutter build windows --release
```

## Key Constraints
1. **TLS fingerprint**: Use `web_socket_channel` with default platform TLS - DO NOT modify cipher suites or extensions
2. **Message format**: `[1 byte type][encrypted data]` padded to 512 bytes
   - 0x01 = real data
   - 0x02 = dummy
   - 0x03 = gossip
3. **Peer discovery**: NO DHT/UDP - all routing info via WSS gossip protocol
4. **Onion routing**: 3-hop chains, layered encryption
5. **Offline buffer**: Last relay stores messages 24h for offline recipients

## Testing Anti-DPI
```bash
# Capture traffic
tcpdump -i any -w capture.pcap port 443

# Analyze with Wireshark/tshark
tshark -r capture.pcap -Y "tcp.port == 443" -T fields -e frame.len

# Check JA3 fingerprint
ja3_client.py < captured_tls.pcap
```

## Seed Nodes
Initial peer list in `lib/config/seed_nodes.dart` - hardcoded or from config file.

## Security Checklist
- [ ] All messages padded before encryption
- [ ] TLS uses system stack (no custom hello)
- [ ] Dummy traffic when idle
- [ ] No peer info in TLS handshake
- [ ] Self-signed cert validation (public key pinning)
- [ ] Double Ratchet correctly implemented
- [ ] No plaintext in WebSocket frames

## Architecture Notes
- Every node can be relay (opt-in)
- Persistent WSS connections (looks like webmail)
- No central server - gossip for discovery
- Files stored only on endpoints (chunked transfer)

## File Organization
```
lib/
  core/           # Business logic, crypto
  network/        # WSS client/server, protocols
  storage/        # Encrypted SQLite
  ui/             # Flutter screens
  config/         # Seed nodes, constants
test/
  unit/           # Crypto, padding tests
  integration/    # WSS, relay tests
  anti_dpi/       # Traffic pattern tests
```

## Important
- **DO NOT** use UDP or custom ports
- **DO NOT** modify TLS handshake
- **DO NOT** send unpadded messages
- **DO** test with DPI simulation (Snort/Suricata rules)
