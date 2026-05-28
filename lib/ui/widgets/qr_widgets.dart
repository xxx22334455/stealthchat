import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/identity_manager.dart';

/// Shows user's QR code for easy contact sharing
class MyQrCodeDialog extends StatelessWidget {
  final IdentityManager identityManager;
  
  const MyQrCodeDialog({super.key, required this.identityManager});

  @override
  Widget build(BuildContext context) {
    final qrData = identityManager.exportPublicKeyString();
    
    return AlertDialog(
      title: const Text('Your QR Code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 200.0,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text('Scan to share your contact', textAlign: TextAlign.center),
          const SizedBox(height: 8),
          SelectionArea(
            child: Text(
              qrData,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
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
    );
  }
}

/// Scans QR code to add contact
class QrScannerDialog extends StatelessWidget {
  const QrScannerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scan QR Code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_scanner, size: 100),
          const SizedBox(height: 16),
          const Text('Point camera at QR code'),
          const SizedBox(height: 16),
          const Text('(Camera integration pending)', style: TextStyle(fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // TODO: Start camera
            Navigator.pop(context);
          },
          child: const Text('Scan'),
        ),
      ],
    );
  }
}
