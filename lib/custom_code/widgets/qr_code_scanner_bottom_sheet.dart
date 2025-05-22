import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'web_qr_scanner_view.dart';
import 'user_scan_result_bottom_sheet.dart';

class QrCodeScannerBottomSheet extends StatefulWidget {
  const QrCodeScannerBottomSheet({Key? key}) : super(key: key);

  @override
  State<QrCodeScannerBottomSheet> createState() => _QrCodeScannerBottomSheetState();
}

class _QrCodeScannerBottomSheetState extends State<QrCodeScannerBottomSheet> {
  bool _isLoading = false;
  String? _error;

  Future<void> _processQRCode(String code) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Parse QR code: userId_venueId
      final parts = code.split('_');
      if (parts.length != 2) {
        throw Exception('Invalid QR code format');
      }
      final userId = parts[0];
      final venueId = parts[1];

      // Fetch user
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!userDoc.exists) throw Exception('User not found');
      final userData = userDoc.data()!;

      // Fetch venue
      final venueDoc = await FirebaseFirestore.instance.collection('venues').doc(venueId).get();
      if (!venueDoc.exists) throw Exception('Venue not found');
      final venueData = venueDoc.data()!;

      // Fetch progress
      final progressQuery = await FirebaseFirestore.instance
          .collection('userVenueProgress')
          .where('userId', isEqualTo: userId)
          .where('venueId', isEqualTo: venueId)
          .get();
      if (progressQuery.docs.isEmpty) throw Exception('No progress data found');
      final progressData = progressQuery.docs.first.data();

      if (mounted) {
        Navigator.pop(context); // Close scanner
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => UserScanResultBottomSheet(
            userData: userData,
            venueData: venueData,
            progressData: progressData,
            qrData: {'userId': userId, 'venueId': venueId},
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 641,
        height: 472,
        decoration: BoxDecoration(
          color: const Color(0xFF363740),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFC5C352), width: 1),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
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
                  const SizedBox(height: 8),
                  const Text(
                    'Scan the QR code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto Flex',
                    ),
                  ),
                  const SizedBox(height: 29),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_isLoading)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  else
                    Expanded(
                      child: Center(
                        child: WebQrScannerView(onScan: _processQRCode),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 