import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_qr_scanner_view.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'user_scan_result_bottom_sheet.dart';

class QrCodeScannerBottomSheetFlow extends StatefulWidget {
  final String venueId;
  const QrCodeScannerBottomSheetFlow({Key? key, required this.venueId}) : super(key: key);

  @override
  State<QrCodeScannerBottomSheetFlow> createState() => _QrCodeScannerBottomSheetFlowState();
}

class _QrCodeScannerBottomSheetFlowState extends State<QrCodeScannerBottomSheetFlow> {
  bool _scanned = false;
  bool _isProcessing = false;
  String? _error;
  Map<String, dynamic> _progressData = <String, dynamic>{};
  Map<String, dynamic>? _venueData;
  Map<String, dynamic>? _qrData;

  void _onScan(String code) async {
    if (_isProcessing) return;
    setState(() { _isProcessing = true; _error = null; });
    try {
      final qrData = json.decode(code);
      if (!qrData.containsKey('userId') || !qrData.containsKey('venueId') || !qrData.containsKey('timestamp') || !qrData.containsKey('action')) {
        throw Exception('Invalid QR code format');
      }
      if (qrData['venueId'] != widget.venueId) {
        throw Exception('QR code is for a different venue');
      }
      final timestamp = DateTime.fromMillisecondsSinceEpoch(qrData['timestamp']);
      final now = DateTime.now();
      if (now.difference(timestamp).inMinutes > 2) {
        throw Exception('QR code has expired');
      }
      final docId = '${qrData['userId']}-${qrData['venueId']}';
      print('Looking for userVenueProgress doc: "$docId"');
      final allDocs = await FirebaseFirestore.instance.collection('userVenueProgress').get();
      for (var doc in allDocs.docs) {
        print('Firestore doc ID: "${doc.id}"');
      }
      final progressDoc = await FirebaseFirestore.instance.collection('userVenueProgress').doc(docId).get();
      if (!progressDoc.exists) throw Exception('User progress not found');
      final rawProgressData = progressDoc.data();
      final Map<String, dynamic> progressData = rawProgressData != null ? Map<String, dynamic>.from(rawProgressData as Map<dynamic, dynamic>) : <String, dynamic>{};
      // Defensive: ensure coin and sessions are int
      int coins = 0;
      int sessions = 0;
      if (progressData.containsKey('coin')) {
        final c = progressData['coin'];
        if (c is int) coins = c;
        else if (c is String) coins = int.tryParse(c) ?? 0;
      }
      if (progressData.containsKey('sessions')) {
        final s = progressData['sessions'];
        if (s is int) sessions = s;
        else if (s is String) sessions = int.tryParse(s) ?? 0;
      }
      progressData['coin'] = coins;
      progressData['sessions'] = sessions;
      // Venue data (optional, for future use)
      final venueDoc = await FirebaseFirestore.instance.collection('venues').doc(qrData['venueId']).get();
      final Map<String, dynamic> venueData = venueDoc.exists && venueDoc.data() != null
        ? Map<String, dynamic>.from(venueDoc.data() as Map<dynamic, dynamic>)
        : <String, dynamic>{};
      setState(() {
        _scanned = true;
        _progressData = progressData;
        _venueData = venueData;
        _qrData = qrData;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 472,
          maxWidth: 641,
          minWidth: 320,
        ),
        child: Container(
          width: 641,
          height: 472,
          decoration: BoxDecoration(
            color: const Color(0xFF363740),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFC5C352), width: 1),
          ),
          child: Stack(
            children: [
              if (!_scanned) ...[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Scan the QR code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto Flex',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF242529),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: kIsWeb
                          ? WebQrScannerView(onScan: _onScan)
                          : SizedBox(
                              width: 350,
                              height: 350,
                              child: _MobileQrScanner(onScan: _onScan),
                            ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    if (_isProcessing) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5C352))),
                    ],
                  ],
                ),
              ] else ...[
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 472, maxHeight: 641),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF363740),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFC5C352), width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 59,
                          backgroundColor: Colors.white24,
                          backgroundImage: (_progressData['photoUrl'] != null && _progressData['photoUrl'] != '')
                            ? NetworkImage(_progressData['photoUrl'])
                            : null,
                          child: (_progressData['photoUrl'] == null || _progressData['photoUrl'] == '')
                              ? const Icon(Icons.person, size: 48, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 29),
                        Text(
                          (_progressData['displayName'] != null && _progressData['displayName'] != '')
                            ? _progressData['displayName']
                            : 'User Name',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto Flex',
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          (_progressData['email'] != null && _progressData['email'] != '')
                            ? _progressData['email']
                            : 'Email',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Roboto Flex',
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Points: ${_progressData['coin']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Roboto Flex',
                          ),
                        ),
                        Text(
                          'Visits: ${_progressData['sessions']}',
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
                              child: const Text('Reward Points'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileQrScanner extends StatefulWidget {
  final void Function(String code) onScan;
  const _MobileQrScanner({required this.onScan});
  @override
  State<_MobileQrScanner> createState() => _MobileQrScannerState();
}

class _MobileQrScannerState extends State<_MobileQrScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _scanned = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    controller!.scannedDataStream.listen((scanData) {
      if (!_scanned) {
        _scanned = true;
        widget.onScan(scanData.code ?? '');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: const Color(0xFFC5C352),
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: 300,
      ),
    );
  }
} 