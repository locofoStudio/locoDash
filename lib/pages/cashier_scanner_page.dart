import 'package:flutter/material.dart';
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

class CashierScannerPage extends StatefulWidget {
  const CashierScannerPage({super.key});

  @override
  State<CashierScannerPage> createState() => _CashierScannerPageState();
}

class _CashierScannerPageState extends State<CashierScannerPage> {
  final AuthService _authService = AuthService();
  String? _selectedVenueId;
  List<String> _venueIds = [];
  bool _loadingVenues = true;
  CashierUser? _scannedUser;
  double _purchaseAmount = 0.0;
  int _calculatedCoins = 0;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _cameFromDashboard = false; // Track if user came from dashboard
  bool _cashierOnly = false; // Track if user is cashier-only (no dashboard access)

  @override
  void initState() {
    super.initState();
    // Delay to get context arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVenuesWithArguments();
    });
  }
  
  void _loadVenuesWithArguments() {
    // Check if venue ID was passed from dashboard or login
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final passedVenueId = args?['venueId'] as String?;
    final cameFromDashboard = args?['cameFromDashboard'] as bool? ?? false;
    final cashierOnly = args?['cashierOnly'] as bool? ?? false;
    
    if (passedVenueId != null) {
      // Use the venue ID passed from dashboard or login
      setState(() {
        _selectedVenueId = passedVenueId;
        _venueIds = [passedVenueId];
        _loadingVenues = false;
        _cameFromDashboard = cameFromDashboard;
        _cashierOnly = cashierOnly;
      });
    } else {
      // Fall back to loading venues normally (came from login without restrictions)
      setState(() {
        _cameFromDashboard = false;
        _cashierOnly = false;
      });
      _loadVenues();
    }
  }

  Future<void> _loadVenues() async {
    setState(() {
      _loadingVenues = true;
    });

    try {
      // Get the current user's venues from venueOwners collection
      final venues = await _authService.getUserVenues();
      
      if (venues.isEmpty) {
        throw Exception('No venues available for this account');
      }

      setState(() {
        _venueIds = venues;
        _loadingVenues = false;
        
        // Select first venue if none selected
        if (_selectedVenueId == null || _selectedVenueId!.isEmpty || !venues.contains(_selectedVenueId)) {
          _selectedVenueId = venues.first;
        }
      });
      
      print('Cashier venues loaded. Current selected venue: $_selectedVenueId');
      print('Available venues: $_venueIds');
      
    } catch (e) {
      print('Error loading venues: $e');
      setState(() {
        _loadingVenues = false;
        _errorMessage = 'Failed to load venues: $e';
      });
      // Sign out on critical error
      await _authService.signOut();
    }
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
        await _onQRScanned(result);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start scanner: $e';
      });
    }
  }

  Future<void> _onQRScanned(String qrCode) async {
    if (_selectedVenueId == null) {
      setState(() {
        _errorMessage = 'Please select a venue first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      print('=== CASHIER QR SCAN ===');
      print('QR Code: $qrCode');
      print('Selected Venue: $_selectedVenueId');

      // Extract userId from QR code (format: userId-venueId or just userId)
      String userId;
      final parts = qrCode.split('-');
      if (parts.length >= 2) {
        userId = parts[0];
        // Verify the venue matches (optional validation)
        final qrVenueId = parts[1];
        print('QR VenueId: "$qrVenueId", Selected VenueId: "$_selectedVenueId"');
      } else {
        userId = qrCode; // Assume entire QR code is userId
      }

      print('UserId: "$userId"');

      // Get user data using selected venue
      final user = await _getUserData(userId, _selectedVenueId!);
      setState(() {
        _scannedUser = user;
        _purchaseAmount = 0.0;
        _calculatedCoins = 0;
      });
    } catch (e) {
      print('❌ Error processing QR: $e');
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<CashierUser> _getUserData(String userId, String venueId) async {
    print('=== CASHIER FIREBASE LOOKUP ===');
    final docId = '$userId-$venueId';
    print('Looking up docId: "$docId"');

    // Get user progress data
    final progressDoc = await FirebaseFirestore.instance
        .collection('userVenueProgress')
        .doc(docId)
        .get();

    if (!progressDoc.exists) {
      throw Exception('User not found');
    }

    final progressData = progressDoc.data()!;

    // Try to get additional user data from users collection
    Map<String, dynamic>? userData;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        userData = userDoc.data();
      }
    } catch (e) {
      print('Could not fetch user data: $e');
    }

    return CashierUser(
      userId: userId,
      venueId: venueId,
      displayName: userData?['displayName'] ?? progressData['displayName'] ?? 'Customer',
      photoUrl: userData?['photoUrl'] ?? progressData['photoUrl'],
      currentCoins: (progressData['coin'] ?? 0) as int,
      hasPlayed: progressData['hasPlayed'] ?? false,
    );
  }

  void _onAmountChanged(String value) {
    final amount = double.tryParse(value) ?? 0.0;
    setState(() {
      _purchaseAmount = amount;
      _calculatedCoins = _calculateCoins(amount);
    });
  }

  int _calculateCoins(double amount) {
    // Coin calculation: 1 coin per $1 spent (rounded down for partial dollars)
    // You can customize this logic based on venue requirements
    if (amount < 0.5) return 0; // Minimum purchase for coins
    return amount.floor(); // 1 coin per full dollar
  }

  Future<void> _awardCoins() async {
    if (_scannedUser == null || _calculatedCoins <= 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final docId = '${_scannedUser!.userId}-${_scannedUser!.venueId}';
      
      print('=== AWARDING COINS ===');
      print('DocId: $docId');
      print('Coins to award: $_calculatedCoins');
      print('Purchase amount: \$${_purchaseAmount.toStringAsFixed(2)}');
      
      // Update user's coins following the correct field structure
      // Based on memory: 'coin' is total, 'coinsFromVenue' is venue-distributed coins
      await FirebaseFirestore.instance
          .collection('userVenueProgress')
          .doc(docId)
          .update({
        'coin': FieldValue.increment(_calculatedCoins), // Total coins
        'coinsFromVenue': FieldValue.increment(_calculatedCoins), // Coins from venue
        'hasPlayed': false, // Reset hasPlayed when coins are awarded
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastPurchaseAmount': _purchaseAmount, // Track last purchase for reference
        'lastCoinsAwarded': _calculatedCoins, // Track last coins awarded
      });

      print('✅ Coins awarded successfully');

      setState(() {
        _successMessage = 'Successfully awarded $_calculatedCoins coins to ${_scannedUser!.displayName}!\nPurchase: \$${_purchaseAmount.toStringAsFixed(2)}';
        _scannedUser = null;
        _purchaseAmount = 0.0;
        _calculatedCoins = 0;
      });
    } catch (e) {
      print('❌ Error awarding coins: $e');
      setState(() {
        _errorMessage = 'Failed to award coins: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingVenues) {
      return const Scaffold(
        backgroundColor: Color(0xFF1F2029),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1F2029),
      appBar: AppBar(
        backgroundColor: const Color(0xFF242529),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Go back based on user's access level and origin
            if (_cameFromDashboard && !_cashierOnly) {
              // Dashboard user can return to dashboard
              Navigator.of(context).pushReplacementNamed('/dashboard');
            } else {
              // Cashier-only user or any user not from dashboard goes to login
              Navigator.of(context).pushReplacementNamed('/');
            }
          },
        ),
        title: const Text(
          'Cashier Scanner',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Roboto Flex',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Venue Selection
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF363740),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: _venueIds.isEmpty
                  ? const Text(
                      'No venues available',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Roboto Flex',
                      ),
                    )
                  : DropdownButton<String>(
                      value: _selectedVenueId ?? _venueIds.first,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      iconSize: 24,
                      elevation: 16,
                      dropdownColor: const Color(0xFF1F2029),
                      underline: Container(height: 0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Roboto Flex',
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedVenueId = newValue;
                            // Clear any scanned user when venue changes
                            _scannedUser = null;
                            _purchaseAmount = 0.0;
                            _calculatedCoins = 0;
                            _errorMessage = null;
                            _successMessage = null;
                          });
                        }
                      },
                      items: _venueIds.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value.substring(0, 1).toUpperCase() + value.substring(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Roboto Flex',
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            
            const SizedBox(height: 24),
            // Scan Button
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFE86526),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _startScan,
                  borderRadius: BorderRadius.circular(16),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 48,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'TAP TO SCAN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto Flex',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontFamily: 'Roboto Flex',
                  ),
                ),
              ),

            // Success Message
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  _successMessage!,
                  style: const TextStyle(
                    color: Colors.green,
                    fontFamily: 'Roboto Flex',
                  ),
                ),
              ),

            // User Info and Purchase Form
            if (_scannedUser != null) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF363740),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer: ${_scannedUser!.displayName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto Flex',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current Coins: ${_scannedUser!.currentCoins}',
                      style: const TextStyle(
                        color: Color(0xFFDCDCDC),
                        fontSize: 14,
                        fontFamily: 'Roboto Flex',
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Purchase Amount Input
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Purchase Amount (\$)',
                        labelStyle: TextStyle(color: Color(0xFFDCDCDC)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF525E5C)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE86526)),
                        ),
                        filled: true,
                        fillColor: Color(0xFF1F2029),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      onChanged: _onAmountChanged,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Calculated Coins
                    Text(
                      'Coins to Award: $_calculatedCoins',
                      style: const TextStyle(
                        color: Color(0xFFE86526),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto Flex',
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Award Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _calculatedCoins > 0 && !_isLoading ? _awardCoins : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE86526),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Award Coins',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto Flex',
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
