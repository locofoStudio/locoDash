import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class UserScanResultBottomSheet extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> venueData;
  final Map<String, dynamic> progressData;
  final Map<String, String> qrData;
  final String currentVenueId;
  final VoidCallback? onQrFooterTap;
  final bool scannerOpen;

  const UserScanResultBottomSheet({
    super.key,
    required this.userData,
    required this.venueData,
    required this.progressData,
    required this.qrData,
    required this.currentVenueId,
    this.onQrFooterTap,
    this.scannerOpen = false,
  });

  @override
  State<UserScanResultBottomSheet> createState() => _UserScanResultBottomSheetState();
}

class _UserScanResultBottomSheetState extends State<UserScanResultBottomSheet> {
  bool _isLoading = false;
  String? _error;

  // State for Reward Coins flow
  bool _showRewardCalculator = false;
  double _inputPrice = 0.0;
  int? _calculatedCoins;
  bool _rewardSuccess = false;
  String? _rewardError;
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.qrData['venueId'] != widget.currentVenueId) {
      setState(() {
        _error = 'Wrong venue. This QR code is for a different venue.';
      });
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  int calculateBaseCoins(double priceHkd) {
    if (priceHkd <= 0) return 0;
    return (priceHkd * 0.8).ceil();
  }

  Future<void> _unlockGame() async {
    if (widget.qrData['venueId'] != widget.currentVenueId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot unlock game for a different venue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Starting game unlock process...');
      print('QR data: ${widget.qrData}');
      
      final firestore = FirebaseFirestore.instance;
      
      final docId = '${widget.qrData['userId']}-${widget.qrData['venueId']}';
      print('Looking up document with ID: $docId');
      
      final docRef = firestore.collection('userVenueProgress').doc(docId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        print('No matching document found');
        setState(() {
          _error = 'User progress not found';
          _isLoading = false;
        });
        return;
      }
      
      await docRef.update({
        'hasPlayed': false
      });
      
      print('Document updated successfully');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game unlocked successfully!'))
      );
      
      Navigator.pop(context);
    } catch (e) {
      print('Error unlocking game: $e');
      setState(() {
        _error = 'Error unlocking game: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _rewardCoinsToUser() async {
    setState(() {
      _isLoading = true;
      _rewardError = null;
    });
    try {
      final firestore = FirebaseFirestore.instance;
      final docId = '${widget.qrData['userId']}-${widget.qrData['venueId']}';
      final docRef = firestore.collection('userVenueProgress').doc(docId);
      final doc = await docRef.get();
      if (!doc.exists) throw Exception('User progress not found');
      final currentCoins = (doc.data()?['coin'] ?? 0) as int;
      final newCoins = currentCoins + (_calculatedCoins ?? 0);
      await docRef.update({'coin': newCoins});
      setState(() {
        _rewardSuccess = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _rewardError = 'Error rewarding coins: $e';
        _isLoading = false;
      });
    }
  }

  void _showRewardCoinsCalculator() {
    setState(() {
      _showRewardCalculator = true;
      _rewardSuccess = false;
      _rewardError = null;
      _inputPrice = 0.0;
      _calculatedCoins = null;
      _priceController.text = '';
    });
  }

  Widget _buildRewardCoinsCalculator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Purchase price', style: TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 12),
        TextField(
          controller: _priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 24),
          decoration: InputDecoration(
            prefixText: 'HK	',
            prefixStyle: const TextStyle(color: Colors.white, fontSize: 20),
            filled: true,
            fillColor: const Color(0xFF363740),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: 'Enter amount',
            hintStyle: const TextStyle(color: Colors.white38),
          ),
          onChanged: (val) {
            setState(() {
              _inputPrice = double.tryParse(val) ?? 0.0;
              _calculatedCoins = null;
            });
          },
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: _inputPrice > 0
              ? () {
                  setState(() {
                    _calculatedCoins = calculateBaseCoins(_inputPrice);
                  });
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC5C352),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            minimumSize: const Size(0, 40),
          ),
          child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        if (_calculatedCoins != null) ...[
          const SizedBox(height: 18),
          Text('Coin equivalent:', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text('$_calculatedCoins', style: const TextStyle(color: Color(0xFFC5C352), fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _isLoading ? null : _rewardCoinsToUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC5C352),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(0, 40),
            ),
            child: _isLoading
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.black)))
                : const Text('Send Coins', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        if (_rewardError != null) ...[
          const SizedBox(height: 12),
          Text(_rewardError!, style: const TextStyle(color: Colors.redAccent)),
        ],
        if (_rewardSuccess) ...[
          const SizedBox(height: 18),
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 8),
          const Text('Coins rewarded!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showRewardCalculator = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC5C352),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Done'),
          ),
        ],
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            setState(() {
              _showRewardCalculator = false;
            });
          },
          child: const Text('Back', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWrongVenue = widget.qrData['venueId'] != widget.currentVenueId;
    final photoUrl = widget.userData['photoUrl']?.toString() ?? '';
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 420,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          decoration: BoxDecoration(
            color: const Color(0xFF40414A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFC5C352), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Close button
              Positioned(
                top: 0,
                right: 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: const Icon(Icons.close, color: Colors.white, size: 32),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  // Profile picture
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFDCDCDC),
                      ),
                      child: (photoUrl.isNotEmpty)
                          ? ClipOval(
                              child: Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                width: 96,
                                height: 96,
                              ),
                            )
                          : const Icon(Icons.person, size: 56, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_showRewardCalculator)
                    _buildRewardCoinsCalculator()
                  else if (isWrongVenue)
                    Text(
                      'Wrong venue',
                      style: TextStyle(
                        color: Colors.red[400],
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto Flex',
                      ),
                    )
                  else ...[
                    Text(
                      widget.userData['displayName'] ?? 'User Name',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto Flex',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.userData['email'] ?? 'Email@email.com',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontFamily: 'Roboto Flex',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'coins: ${widget.progressData['coin'] ?? 'XXX'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Roboto Flex',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sessions: ${widget.progressData['sessions'] ?? 'XXX'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Roboto Flex',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white70),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text(
                        'View more',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Roboto Flex',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action buttons
                    SizedBox(
                      width: 220,
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: _isLoading ? null : _unlockGame,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC5C352),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                              minimumSize: const Size(0, 40),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                    ),
                                  )
                                : const Text(
                                    'Unlock Game',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Roboto Flex',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white70),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 40),
                            ),
                            child: const Text(
                              'Confirm Reward',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Roboto Flex',
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton(
                            onPressed: () {
                              _showRewardCoinsCalculator();
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white70),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 40),
                            ),
                            child: const Text(
                              'Reward Coins',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Roboto Flex',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CloseIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Draw X shape
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Add a simple QR code icon widget
class QrCodeIcon extends StatelessWidget {
  const QrCodeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _QrCodePainter(),
      size: const Size(40, 40),
    );
  }
}

class _QrCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF162537)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    // Draw white border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ),
      borderPaint,
    );
    // Draw QR code squares (simplified)
    final squarePaint = Paint()..color = Colors.white;
    double s = size.width / 8;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if ((i == 0 || i == 2) && (j == 0 || j == 2)) {
          canvas.drawRect(Rect.fromLTWH(i * s, j * s, s, s), squarePaint);
        }
      }
    }
    // Center dot
    canvas.drawRect(Rect.fromLTWH(3.5 * s, 3.5 * s, s, s), squarePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 