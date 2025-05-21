import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class QrCodeGeneratorWidget extends StatelessWidget {
  final String venueId;

  const QrCodeGeneratorWidget({
    Key? key,
    required this.venueId,
  }) : super(key: key);

  String _generateQrData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to generate QR code');
    }

    final qrData = {
      'userId': user.uid,
      'venueId': venueId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'action': 'loyalty_redeem',
    };

    return json.encode(qrData);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF363740),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Scan to Redeem',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto Flex',
            ),
          ),
          const SizedBox(height: 24),
          QrImageView(
            data: _generateQrData(),
            version: QrVersions.auto,
            size: 200.0,
            backgroundColor: Colors.white,
            errorStateBuilder: (context, error) => Center(
              child: Text(
                'Error generating QR code: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Show this QR code to redeem your loyalty points',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontFamily: 'Roboto Flex',
            ),
          ),
        ],
      ),
    );
  }
} 