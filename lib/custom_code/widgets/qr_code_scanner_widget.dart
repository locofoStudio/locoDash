import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QrCodeScannerWidget extends StatefulWidget {
  final String venueId;
  final Function(bool success, String message) onScanComplete;

  const QrCodeScannerWidget({
    Key? key,
    required this.venueId,
    required this.onScanComplete,
  }) : super(key: key);

  @override
  State<QrCodeScannerWidget> createState() => _QrCodeScannerWidgetState();
}

class _QrCodeScannerWidgetState extends State<QrCodeScannerWidget> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF242529),
      appBar: AppBar(
        backgroundColor: const Color(0xFF242529),
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Roboto Flex',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: const Color(0xFFC5C352),
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: _isProcessing
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5C352)),
                    )
                  : const Text(
                      'Position QR code within frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Roboto Flex',
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (_isProcessing) return;
      _isProcessing = true;
      
      try {
        if (scanData.code == null) {
          throw Exception('No QR code data found');
        }

        // Parse QR code data
        final qrData = json.decode(scanData.code!);
        
        // Validate required fields
        if (!qrData.containsKey('userId') ||
            !qrData.containsKey('venueId') ||
            !qrData.containsKey('timestamp') ||
            !qrData.containsKey('action')) {
          throw Exception('Invalid QR code format');
        }

        // Validate venue ID
        if (qrData['venueId'] != widget.venueId) {
          throw Exception('QR code is for a different venue');
        }

        // Validate timestamp (within last 2 minutes)
        final timestamp = qrData['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - timestamp > 120000) { // 2 minutes in milliseconds
          throw Exception('QR code has expired');
        }

        // Look up user in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('userVenueProgress')
            .doc(qrData['userId'])
            .get();

        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        // Process the action
        switch (qrData['action']) {
          case 'loyalty_redeem':
            await _processLoyaltyRedeem(userDoc);
            break;
          default:
            throw Exception('Unknown action type');
        }

        // Success
        widget.onScanComplete(true, 'Successfully processed QR code');
        Navigator.pop(context);
      } catch (e) {
        widget.onScanComplete(false, e.toString());
        Navigator.pop(context);
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<void> _processLoyaltyRedeem(DocumentSnapshot userDoc) async {
    final userData = userDoc.data() as Map<String, dynamic>;
    final coins = userData['coins'] as int? ?? 0;
    
    if (coins <= 0) {
      throw Exception('User has no coins to redeem');
    }

    // Update user's coins
    await userDoc.reference.update({
      'coins': 0,
      'redeemed': FieldValue.increment(coins),
      'last_redeemed': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
} 