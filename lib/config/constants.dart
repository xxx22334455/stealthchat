/// Message types for WSS protocol
class MessageType {
  static const int realData = 0x01;
  static const int dummy = 0x02;
  static const int gossip = 0x03;
  static const int handshake = 0x04;
  static const int fileChunk = 0x05;
  static const int onion = 0x06;
}

/// Fixed block size for padding
const int BLOCK_SIZE = 512;

/// Maximum message size before chunking
const int MAX_MESSAGE_SIZE = 65536;

/// Offline message buffer duration (24 hours)
const int OFFLINE_BUFFER_DURATION = 24 * 60 * 60;

/// Dummy traffic interval range (seconds)
const int MIN_DUMMY_INTERVAL = 10;
const int MAX_DUMMY_INTERVAL = 30;

/// Onion chain length
const int ONION_CHAIN_LENGTH = 3;

/// WSS port
const int WSS_PORT = 443;
