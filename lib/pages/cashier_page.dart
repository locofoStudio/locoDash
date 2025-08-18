import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../custom_code/widgets/full_screen_scanner_overlay.dart';

// Simple user model for cashier interface
class CashierUser {
  final String userId;
  final String venueId;
  final String displayName;
  final String? photoUrl;
  final int currentCoins;
  final bool hasPlayed;

  CashierUser({
    required this.userId,
    required this.venueId,
    required this.displayName,
    this.photoUrl,
    required this.currentCoins,
    required this.hasPlayed,
  });
}

class CashierPage extends StatefulWidget {
  final String venueId;
  
  const CashierPage({super.key, required this.venueId});

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final AuthService _authService = AuthService();
  CashierUser? _scannedUser;
  bool _isLoading = false;
  String? _error;
  String _status = 'Ready to scan';
  double _purchaseAmount = 0.0;
  int _calculatedCoins = 0;
  bool _showCoinInput = false;
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2029),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              
              if (_scannedUser == null) ...[
                _buildScanSection(),
              ] else ...[
                _buildUserSection(),
              ],
              
              if (_error != null) ...[
                const SizedBox(height: 20),
                _buildErrorSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              IconButton(
                onPressed: () async {
                  await _authService.signOut();
                },
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              // Venue info
              Text(
                widget.venueId.toUpperCase(),
                style: GoogleFonts.robotoFlex(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Icon(
            Icons.qr_code_scanner,
            size: 48,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(height: 16),
          Text(
            'CASHIER SCANNER',
            style: GoogleFonts.robotoFlex(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Loco Loyalty System',
            style: GoogleFonts.robotoFlex(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanSection() {
    return Column(
      children: [
        // Large scan button
        GestureDetector(
          onTap: _isLoading ? null : _startScan,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _isLoading 
                    ? [Colors.grey.shade400, Colors.grey.shade600]
                    : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading) ...[
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SCANNING...',
                    style: GoogleFonts.robotoFlex(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.qr_code_scanner,
                    size: 64,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'TAP TO SCAN',
                    style: GoogleFonts.robotoFlex(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customer QR Code',
                    style: GoogleFonts.robotoFlex(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          _status,
          style: GoogleFonts.robotoFlex(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Point camera at customer QR code',
          style: GoogleFonts.robotoFlex(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.5),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUserSection() {
    return Column(
      children: [
        // User info card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF363740),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // User avatar and name
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF6366F1),
                    backgroundImage: _scannedUser!.photoUrl != null 
                        ? NetworkImage(_scannedUser!.photoUrl!) 
                        : null,
                    child: _scannedUser!.photoUrl == null 
                        ? Text(
                            _scannedUser!.displayName.isNotEmpty 
                                ? _scannedUser!.displayName[0].toUpperCase()
                                : 'U',
                            style: GoogleFonts.robotoFlex(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _scannedUser!.displayName.isNotEmpty 
                              ? _scannedUser!.displayName 
                              : 'Customer',
                          style: GoogleFonts.robotoFlex(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_scannedUser!.currentCoins} coins',
                          style: GoogleFonts.robotoFlex(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Purchase amount input
              TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Purchase Amount (HKD)',
                  labelStyle: GoogleFonts.robotoFlex(
                    color: Colors.white.withOpacity(0.7),
                  ),
                  prefixText: '\$',
                  prefixStyle: GoogleFonts.robotoFlex(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF6366F1),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                ),
                style: GoogleFonts.robotoFlex(
                  color: Colors.white,
                  fontSize: 16,
                ),
                keyboardType: TextInputType.number,
                onChanged: _onAmountChanged,
              ),
              
              if (_calculatedCoins > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Coins to award:',
                        style: GoogleFonts.robotoFlex(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        '$_calculatedCoins coins',
                        style: GoogleFonts.robotoFlex(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Send coins button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _awardCoins,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Send Coins',
                            style: GoogleFonts.robotoFlex(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              // Reset button
              TextButton(
                onPressed: _resetScanner,
                child: Text(
                  'Scan Another Customer',
                  style: GoogleFonts.robotoFlex(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.robotoFlex(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startScan() async {
    try {
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => const FullScreenScannerOverlay(),
          fullscreenDialog: true,
        ),
      );

      if (result != null && result.isNotEmpty) {
        _handleQRScan(result);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to start scanner: $e';
        _status = 'Scan failed - Try again';
      });
    }
  }

  void _handleQRScan(String qrCode) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _status = 'Processing QR code...';
    });

    try {
      print('=== CASHIER QR SCAN ===');
      print('QR Code: $qrCode');
      print('Selected Venue: ${widget.venueId}');

      // Parse QR code (format: userId-venueId)
      final parts = qrCode.split('-');
      if (parts.length != 2) {
        throw Exception('Invalid QR code format');
      }

      final userId = parts[0];
      final scannedVenueId = parts[1];

      // Validate venue matches
      if (scannedVenueId != widget.venueId) {
        throw Exception('QR code is for ${scannedVenueId.toUpperCase()}, but you selected ${widget.venueId.toUpperCase()}');
      }

      // Get user data
      final user = await _getUserData(userId, scannedVenueId);
      
      setState(() {
        _scannedUser = user;
        _status = 'User found - Ready to award coins';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _status = 'Scan failed - Try again';
        _isLoading = false;
      });
    }
  }

  Future<CashierUser> _getUserData(String userId, String venueId) async {
    print('=== CASHIER FIREBASE LOOKUP ===');
    final docId = '$userId-$venueId';
    print('Looking up docId: "$docId"');
    print('UserId: "$userId"');
    print('VenueId: "$venueId"');

    try {
      // Get user progress document
      final progressDoc = await FirebaseFirestore.instance
          .collection('userVenueProgress')
          .doc(docId)
          .get();

      if (!progressDoc.exists) {
        throw Exception('User not found in venue system');
      }

      final progressData = progressDoc.data()!;
      
      // Get additional user info from users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      Map<String, dynamic> userData = {};
      if (userDoc.exists) {
        userData = userDoc.data()!;
      }

      print('✅ User found: ${userData['displayName'] ?? progressData['displayName'] ?? 'Unknown'}');
      print('💰 Current coins: ${progressData['coin'] ?? 0}');

      return CashierUser(
        userId: userId,
        venueId: venueId,
        displayName: userData['displayName'] ?? progressData['displayName'] ?? 'Customer',
        photoUrl: userData['photoUrl'] ?? progressData['photoUrl'],
        currentCoins: (progressData['coin'] ?? 0) as int,
        hasPlayed: progressData['hasPlayed'] ?? false,
      );
    } catch (e) {
      print('❌ Error getting user: $e');
      rethrow;
    }
  }

  void _onAmountChanged(String value) {
    final amount = double.tryParse(value) ?? 0.0;
    setState(() {
      _purchaseAmount = amount;
      _calculatedCoins = _calculateCoins(amount);
    });
  }

  int _calculateCoins(double priceHkd) {
    if (priceHkd <= 0) return 0;
    return (priceHkd * 0.8).ceil(); // 80% conversion rate
  }

  Future<void> _awardCoins() async {
    if (_scannedUser == null || _calculatedCoins <= 0) return;

    setState(() {
      _isLoading = true;
      _status = 'Awarding coins...';
    });

    try {
      print('=== AWARDING COINS ===');
      print('User: ${_scannedUser!.userId}');
      print('Venue: ${_scannedUser!.venueId}');
      print('Coins to award: $_calculatedCoins');

      final docId = '${_scannedUser!.userId}-${_scannedUser!.venueId}';
      final docRef = FirebaseFirestore.instance
          .collection('userVenueProgress')
          .doc(docId);
      
      final doc = await docRef.get();
      if (!doc.exists) {
        throw Exception('User progress not found');
      }

      final currentData = doc.data()!;
      final currentCoins = (currentData['coin'] ?? 0) as int;
      final currentCoinsFromVenue = (currentData['coinsFromVenue'] ?? 0) as int;
      
      final newCoins = currentCoins + _calculatedCoins;
      final newCoinsFromVenue = currentCoinsFromVenue + _calculatedCoins;

      // Update coins and set hasPlayed to false so user can play game
      await docRef.update({
        'coin': newCoins,
        'coinsFromVenue': newCoinsFromVenue,
        'hasPlayed': false, // Allow user to play the game
        'lastCoinUpdate': FieldValue.serverTimestamp(),
      });

      print('✅ Coins awarded successfully!');
      print('💰 New total: $newCoins coins');
      print('🎮 hasPlayed set to false - user can play game');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ $_calculatedCoins coins awarded to ${_scannedUser!.displayName}',
            style: GoogleFonts.robotoFlex(),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Reset after success
      _resetScanner();
    } catch (e) {
      setState(() {
        _error = 'Failed to award coins: $e';
        _status = 'Award failed - Try again';
        _isLoading = false;
      });
    }
  }

  void _resetScanner() {
    setState(() {
      _scannedUser = null;
      _error = null;
      _status = 'Ready to scan';
      _purchaseAmount = 0.0;
      _calculatedCoins = 0;
      _isLoading = false;
    });
    _amountController.clear();
  }
}

// Simple UserModel class for the cashier interface
class UserModel {
  final String userId;
  final String venueId;
  final String displayName;
  final String? photoUrl;
  final int currentCoins;
  final int coinsFromVenue;
  final bool hasPlayed;

  UserModel({
    required this.userId,
    required this.venueId,
    required this.displayName,
    this.photoUrl,
    required this.currentCoins,
    required this.coinsFromVenue,
    required this.hasPlayed,
  });
}
