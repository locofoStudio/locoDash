import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_scan_result_bottom_sheet.dart';
import 'web_qr_scanner_view.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class QrCodeScannerWidget extends StatefulWidget {
  final String venueId;
  final Function(bool success, String message)? onScanComplete;

  const QrCodeScannerWidget({
    super.key,
    required this.venueId,
    this.onScanComplete,
  });

  @override
  State<QrCodeScannerWidget> createState() => _QrCodeScannerWidgetState();
}

class _QrCodeScannerWidgetState extends State<QrCodeScannerWidget> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;
  String? _lastScannedCode;

  Future<void> _processQRCode(String? code) async {
    if (code == null || _isProcessing || code == _lastScannedCode) return;

    setState(() {
      _isProcessing = true;
      _lastScannedCode = code;
    });

    try {
      // Parse QR code data
      final qrData = json.decode(code);
      
      // Validate QR code data
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
      final timestamp = DateTime.fromMillisecondsSinceEpoch(qrData['timestamp']);
      final now = DateTime.now();
      if (now.difference(timestamp).inMinutes > 2) {
        throw Exception('QR code has expired');
      }

      // Get user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(qrData['userId'])
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Get venue data
      final venueDoc = await FirebaseFirestore.instance
          .collection('venues')
          .doc(qrData['venueId'])
          .get();

      if (!venueDoc.exists) {
        throw Exception('Venue not found');
      }

      final venueData = venueDoc.data() as Map<String, dynamic>;

      // Get user's progress for this venue
      final progressDoc = await FirebaseFirestore.instance
          .collection('userVenueProgress')
          .doc('${qrData['userId']}_${qrData['venueId']}')
          .get();

      final progressData = progressDoc.exists 
          ? progressDoc.data() as Map<String, dynamic>
          : {
              'totalPoints': 0,
              'totalVisits': 0,
              'lastVisit': null,
              'completedChallenges': [],
              'redeemedRewards': [],
            };

      if (mounted) {
        // Show bottom sheet with user data
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => UserScanResultBottomSheet(
            userData: userData,
            venueData: venueData,
            progressData: progressData,
            qrData: qrData,
          ),
        );
        widget.onScanComplete?.call(true, 'Successfully processed QR code');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        widget.onScanComplete?.call(false, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Container(
        height: 450,
        decoration: BoxDecoration(
          color: const Color(0xFF242529),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 64,
              color: Color(0xFFC5C352),
            ),
            const SizedBox(height: 16),
            const Text(
              'QR Code Scanner',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => Center(
                          child: WebQrScannerView(
                            onScan: (code) {
                              Navigator.of(context).pop();
                              _processQRCode(code);
                            },
                          ),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC5C352),
                foregroundColor: const Color(0xFF363740),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(_isProcessing ? 'Processing...' : 'Start Scanner'),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF242529),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: const Color(0xFFC5C352),
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 300,
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  onPressed: () async {
                    await controller?.toggleFlash();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                  onPressed: () async {
                    await controller?.flipCamera();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      _processQRCode(scanData.code);
    });
  }
} 