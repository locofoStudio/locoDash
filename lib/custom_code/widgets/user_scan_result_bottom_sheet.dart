import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserScanResultBottomSheet extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> venueData;
  final Map<String, dynamic> progressData;
  final Map<String, String> qrData;

  const UserScanResultBottomSheet({
    Key? key,
    required this.userData,
    required this.venueData,
    required this.progressData,
    required this.qrData,
  }) : super(key: key);

  @override
  State<UserScanResultBottomSheet> createState() => _UserScanResultBottomSheetState();
}

class _UserScanResultBottomSheetState extends State<UserScanResultBottomSheet> {
  bool _isLoading = false;
  String? _error;

  Future<void> _unlockGame() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Starting game unlock process...');
      print('QR data: ${widget.qrData}');
      
      // Get a reference to the Firestore instance
      final firestore = FirebaseFirestore.instance;
      
      // Try to find the document in the userVenueProgress collection using a query
      print('Querying userVenueProgress collection...');
      final querySnapshot = await firestore
          .collection('userVenueProgress')
          .where('userId', isEqualTo: widget.qrData['userId'])
          .where('venueId', isEqualTo: widget.qrData['venueId'])
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        print('No matching document found');
        setState(() {
          _error = 'User progress not found';
          _isLoading = false;
        });
        return;
      }
      
      final docId = querySnapshot.docs.first.id;
      print('Found document with ID: $docId');
      print('Current data: ${querySnapshot.docs.first.data()}');
      
      // Update the hasPlayed field to false
      await firestore.collection('userVenueProgress').doc(docId).update({
        'hasPlayed': false
      });
      
      print('Document updated successfully');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Game unlocked successfully!'))
      );
      
      // Close the bottom sheet
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
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const Text(
            'User Information',
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
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A33),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Name', widget.userData['name'] ?? 'N/A'),
                const SizedBox(height: 12),
                _buildInfoRow('Email', widget.userData['email'] ?? 'N/A'),
                const SizedBox(height: 12),
                _buildInfoRow('Phone', widget.userData['phone'] ?? 'N/A'),
                const SizedBox(height: 12),
                _buildInfoRow('Venue', widget.venueData['name'] ?? 'N/A'),
                const SizedBox(height: 12),
                _buildInfoRow('Coins', '${widget.progressData['coin'] ?? 0}'),
                const SizedBox(height: 12),
                _buildInfoRow('Sessions', '${widget.progressData['sessions'] ?? 0}'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _unlockGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC5C352),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text('Unlock Game'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontFamily: 'Roboto Flex',
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto Flex',
          ),
        ),
      ],
    );
  }
} 