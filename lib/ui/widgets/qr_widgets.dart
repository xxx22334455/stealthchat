import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/identity_manager.dart';
import '../theme/telegram_theme.dart';

/// Shows user's QR code for easy contact sharing
class MyQrCodeDialog extends StatelessWidget {
  final IdentityManager identityManager;
  
  const MyQrCodeDialog({super.key, required this.identityManager});

  @override
  Widget build(BuildContext context) {
    final qrData = identityManager.exportPublicKeyString();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.qr_code, color: TelegramColors.lightPrimary),
          const SizedBox(width: 8),
          const Text('Your QR Code'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TelegramColors.lightPrimary),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 180.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Share this QR code with contacts',
            textAlign: TextAlign.center,
            style: TextStyle(color: TelegramColors.lightTextSecondary),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TelegramColors.lightPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectionArea(
              child: Text(
                qrData,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white : null,
                ),
                textAlign: TextAlign.center,
              ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.qr_code_scanner, color: TelegramColors.lightPrimary),
          const SizedBox(width: 8),
          const Text('Scan QR Code'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: TelegramColors.lightPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              size: 60,
              color: TelegramColors.lightPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Point camera at contact\'s QR code',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Camera integration coming soon',
            style: TextStyle(
              fontSize: 12,
              color: TelegramColors.lightTextSecondary,
            ),
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
          child: const Text('Scan'),
        ),
      ],
    );
  }
}
