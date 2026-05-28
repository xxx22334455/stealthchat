# Testing Anti-DPI Features

## Traffic Capture

```bash
# Capture all traffic on port 443
tcpdump -i any -w capture.pcap port 443

# Filter only StealthChat traffic (if you know the IPs)
tcpdump -i any -w capture.pcap 'port 443 and host <relay-ip>'
```

## Analysis

### Check packet sizes
```bash
# All packets should be multiples of 512 bytes (after TLS overhead)
tshark -r capture.pcap -Y "tcp.port == 443" -T fields -e frame.len
```

### Verify TLS fingerprint
```bash
# Use JA3 fingerprinting
python3 ja3_client.py < captured_tls.pcap

# Expected: Browser-like JA3 hash (Chrome/Firefox)
# Should NOT be unique to StealthChat
```

### Check for UDP traffic
```bash
# Should return nothing - no UDP allowed
tshark -r capture.pcap -Y "udp"
```

### Verify no plaintext in WebSocket frames
```bash
# All WebSocket frames should be binary and encrypted
tshark -r capture.pcap -Y "websocket" -T fields -e websocket.opcode
```

## DPI Simulation

### Snort rules for Telegram/P2P detection
```bash
# Test against common DPI rules
snort -r capture.pcap -c /etc/snort/rules/telegram.rules

# Should produce NO alerts
```

### Suricata rules
```bash
suricata -r capture.pcap -l /tmp/suricata/

# Check alerts/eve.json for any P2P/Telegram signatures
cat /tmp/suricata/eve.json | jq '.alert'
```

## Expected Results

1. **All traffic on TCP 443** - No UDP, no other ports
2. **TLS 1.3 with browser-like JA3** - Matches Chrome/Firefox fingerprint
3. **Packet sizes vary** - Due to padding, no fixed pattern
4. **No plaintext patterns** - All WebSocket frames are encrypted binary
5. **Dummy traffic present** - Regular packets even during idle periods
6. **No DPI alerts** - Snort/Suricata don't detect P2P/Telegram signatures

## Automated Testing

Run the test suite:
```bash
flutter test test/anti_dpi/
```

## Manual Verification

1. Start StealthChat
2. Capture traffic with tcpdump
3. Analyze with Wireshark/tshark
4. Verify no UDP, all TLS 1.3
5. Check JA3 fingerprint matches browser
6. Run through Snort/Suricata rules

## Known Issues

- Initial TLS handshake may be detectable (mitigated by using system TLS)
- Traffic volume patterns may be detectable (mitigated by dummy traffic)
- Timing analysis may reveal patterns (partially mitigated by random intervals)
