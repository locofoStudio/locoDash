import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

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
  bool _hasPermission = false;
  bool _isCameraInitialized = false;
  String? _errorMessage;
  Barcode? _lastScannedCode;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
      if (!_hasPermission) {
        _errorMessage = 'Camera permission is required to scan QR codes';
      }
    });
  }

  void _processQRCode(String code) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Pause camera while processing
      await controller?.pauseCamera();

      // Parse QR code data
      final qrData = json.decode(code);
      
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

      // Success: Show bottom sheet with user info
      final userData = userDoc.data() as Map<String, dynamic>;
      if (!mounted) return;

      // Close the scanner bottom sheet
      Navigator.pop(context);

      // Show the user info bottom sheet
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => UserScanResultBottomSheet(userData: userData),
      );
      
      widget.onScanComplete(true, 'Successfully processed QR code');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
        widget.onScanComplete(false, e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
        // Resume camera after error
        await controller?.resumeCamera();
      }
    } finally {
      _isProcessing = false;
    }
  }

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
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF242529),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scan QR Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto Flex',
                  ),
                ),
                Row(
                  children: [
                    if (_isCameraInitialized) ...[
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                        onPressed: () async {
                          await controller?.flipCamera();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.flash_on, color: Colors.white),
                        onPressed: () async {
                          await controller?.toggleFlash();
                        },
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        controller?.dispose();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _hasPermission
                ? Stack(
                    children: [
                      QRView(
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
                      if (_errorMessage != null)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _errorMessage = null;
                                      });
                                      controller?.resumeCamera();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFC5C352),
                                    ),
                                    child: const Text('Try Again'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Camera permission is required',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _checkPermission,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC5C352),
                          ),
                          child: const Text('Grant Permission'),
                        ),
                      ],
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
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
    setState(() {
      _isCameraInitialized = true;
    });
    
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && !_isProcessing && scanData != _lastScannedCode) {
        _lastScannedCode = scanData;
        _processQRCode(scanData.code!);
      }
    });
  }

  Future<void> _processLoyaltyRedeem(DocumentSnapshot userDoc) async {
    final userData = userDoc.data() as Map<String, dynamic>;
    final coins = userData['coin'] as int? ?? 0;
    
    if (coins <= 0) {
      throw Exception('User has no coins to redeem');
    }

    // Update user's coins
    await userDoc.reference.update({
      'coin': 0,
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

class UserScanResultBottomSheet extends StatelessWidget {
  final Map<String, dynamic> userData;
  const UserScanResultBottomSheet({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF363740),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        border: Border.all(color: const Color(0xFFC5C352), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          CircleAvatar(
            radius: 59,
            backgroundColor: Colors.white24,
            backgroundImage: userData['photoUrl'] != null && userData['photoUrl'] != ''
                ? NetworkImage(userData['photoUrl'])
                : null,
            child: userData['photoUrl'] == null || userData['photoUrl'] == ''
                ? const Icon(Icons.person, size: 48, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 29),
          Text(
            userData['displayName'] ?? 'User Name',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto Flex',
            ),
          ),
          const SizedBox(height: 14),
          Text(
            userData['email'] ?? 'Email',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Roboto Flex',
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Coins: ${userData['coin'] ?? 0}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Roboto Flex',
            ),
          ),
          Text(
            'Sessions: ${userData['sessions'] ?? 0}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Roboto Flex',
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: const Text('View more', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 29),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: const Text('Unlock Game'),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: const Text('Confirm Reward'),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: const Text('Reward Coins'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
} 