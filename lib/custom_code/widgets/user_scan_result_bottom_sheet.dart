import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserScanResultBottomSheet extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> venueData;
  final Map<String, dynamic> progressData;
  final Map<String, String> qrData;
  final String currentVenueId;

  const UserScanResultBottomSheet({
    Key? key,
    required this.userData,
    required this.venueData,
    required this.progressData,
    required this.qrData,
    required this.currentVenueId,
  }) : super(key: key);

  @override
  State<UserScanResultBottomSheet> createState() => _UserScanResultBottomSheetState();
}

class _UserScanResultBottomSheetState extends State<UserScanResultBottomSheet> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.qrData['venueId'] != widget.currentVenueId) {
      setState(() {
        _error = 'Wrong venue. This QR code is for a different venue.';
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 641,
      height: 472,
      decoration: BoxDecoration(
        color: const Color(0xFF363740),
        border: Border.all(color: const Color(0xFFC5C352), width: 1),
      ),
      child: Stack(
        children: [
          // Close button
          Positioned(
            top: 33,
            right: 33,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 33,
                height: 18.5,
                child: CustomPaint(
                  painter: CloseIconPainter(),
                ),
              ),
            ),
          ),
          
          // Main content
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.qrData['venueId'] != widget.currentVenueId)
                  Expanded(
                    child: Center(
                      child: Text(
                        'Wrong venue',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 24,
                          fontFamily: 'Roboto Flex',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side - User info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User photo
                              Container(
                                width: 118,
                                height: 118,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFDCDCDC),
                                ),
                                child: widget.userData['photoUrl'] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(59),
                                        child: Image.network(
                                          widget.userData['photoUrl'],
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(Icons.person, size: 59, color: Colors.white),
                              ),
                              const SizedBox(height: 29),
                              // User info
                              Text(
                                widget.userData['displayName'] ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontFamily: 'Roboto Flex',
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                widget.userData['email'] ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontFamily: 'Roboto Flex',
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Coins: ${widget.progressData['coin'] ?? 0}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontFamily: 'Roboto Flex',
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Sessions: ${widget.progressData['sessions'] ?? 0}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontFamily: 'Roboto Flex',
                                ),
                              ),
                              const SizedBox(height: 14),
                              // View more button
                              Container(
                                height: 23,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Text(
                                    'View more',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontFamily: 'Roboto Flex',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Right side - Action buttons
                        Column(
                          children: [
                            // Unlock Game button
                            GestureDetector(
                              onTap: _isLoading ? null : _unlockGame,
                              child: Container(
                                height: 23,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Center(
                                        child: Text(
                                          'Unlock Game',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontFamily: 'Roboto Flex',
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Reward Coins button
                            Container(
                              height: 23,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text(
                                  'Reward Coins',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontFamily: 'Roboto Flex',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Confirm Reward button
                            Container(
                              height: 23,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text(
                                  'Confirm Reward',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontFamily: 'Roboto Flex',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
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