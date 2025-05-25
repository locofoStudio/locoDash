import 'package:flutter/material.dart';

class QRScannerWidget extends StatelessWidget {
  final Function(String) onQRCodeDetected;
  const QRScannerWidget({super.key, required this.onQRCodeDetected});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Please use the Scan QR button to open the scanner.'),
    );
  }
} 