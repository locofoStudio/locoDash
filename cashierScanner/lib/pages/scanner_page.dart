import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/scan_button.dart';
import '../widgets/user_info_card.dart';
import '../widgets/coin_input_widget.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  UserModel? _scannedUser;
  bool _isLoading = false;
  String? _error;
  String _status = 'Ready to scan';
  double _purchaseAmount = 0.0;
  int _calculatedCoins = 0;
  bool _showCoinInput = false;
  String _selectedVenueId = 'fineprint'; // Default venue

  // Available venues - you can expand this list
  final List<Map<String, String>> _venues = [
    {'id': 'fineprint', 'name': 'Fineprint'},
    {'id': 'venue2', 'name': 'Venue 2'},
    {'id': 'venue3', 'name': 'Venue 3'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2029), // Same as dashboard
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
              
              if (_error != null) _buildErrorSection(),
              
              const SizedBox(height: 20),
              _buildStatusSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            'CASHIER SCANNER',
            style: GoogleFonts.robotoFlex(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Loco Loyalty System',
            style: GoogleFonts.robotoFlex(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),
          
          // Venue Selection Dropdown
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedVenueId,
                dropdownColor: const Color(0xFF6366F1),
                style: GoogleFonts.robotoFlex(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white.withOpacity(0.8),
                ),
                items: _venues.map((venue) {
                  return DropdownMenuItem<String>(
                    value: venue['id'],
                    child: Text(
                      venue['name']!,
                      style: GoogleFonts.robotoFlex(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedVenueId = newValue;
                      // Reset scan state when venue changes
                      _scannedUser = null;
                      _showCoinInput = false;
                      _error = null;
                      _status = 'Ready to scan';
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanSection() {
    return Column(
      children: [
        ScanButton(
          onScan: _handleQRScan,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 20),
        Text(
          'Point camera at customer QR code',
          style: GoogleFonts.robotoFlex(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUserSection() {
    return Column(
      children: [
        UserInfoCard(user: _scannedUser!),
        const SizedBox(height: 20),
        
        if (!_showCoinInput) ...[
          // Show coin input button
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showCoinInput = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                '💰 AWARD COINS',
                style: GoogleFonts.robotoFlex(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ] else ...[
          // Show coin input widget
          CoinInputWidget(
            onAmountChanged: (amount) {
              setState(() {
                _purchaseAmount = amount;
                _calculatedCoins = FirebaseService.calculateCoins(amount);
              });
            },
            calculatedCoins: _calculatedCoins,
            onAwardCoins: _awardCoins,
            isLoading: _isLoading,
          ),
        ],
        
        const SizedBox(height: 20),
        
        // Back to scan button
        TextButton(
          onPressed: _resetScanner,
          child: Text(
            '← Back to Scan',
            style: GoogleFonts.robotoFlex(
              fontSize: 16,
              color: const Color(0xFF6366F1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorSection() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.robotoFlex(
                fontSize: 14,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _scannedUser != null ? Colors.green : Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _status,
            style: GoogleFonts.robotoFlex(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleQRScan(String qrCode) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _status = 'Processing QR code...';
    });

    try {
      print('=== CASHIER QR SCAN ===');
      print('QR Code: $qrCode');
      print('Selected Venue: $_selectedVenueId');

      // Parse QR code
      final scanResult = ScanResult.fromQRCode(qrCode);
      
      // Validate venue matches selected venue
      if (scanResult.venueId != _selectedVenueId) {
        final selectedVenueName = _venues.firstWhere(
          (v) => v['id'] == _selectedVenueId,
          orElse: () => {'name': 'Unknown'},
        )['name'];
        
        throw Exception('QR code is for a different venue. Please scan a QR code from $selectedVenueName.');
      }
      
      // Get user data
      final user = await FirebaseService.getUserFromScan(scanResult);
      
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

  Future<void> _awardCoins() async {
    if (_scannedUser == null || _calculatedCoins <= 0) return;

    setState(() {
      _isLoading = true;
      _status = 'Awarding coins...';
    });

    try {
      await FirebaseService.awardCoins(
        userId: _scannedUser!.userId,
        venueId: _selectedVenueId, // Use selected venue ID
        coinsToAward: _calculatedCoins,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${_calculatedCoins} coins awarded to ${_scannedUser!.displayName}',
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
        _status = 'Award failed';
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
      _showCoinInput = false;
      _isLoading = false;
    });
  }
}
