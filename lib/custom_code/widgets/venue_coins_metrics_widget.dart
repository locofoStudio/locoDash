// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/responsive_helper.dart';

class VenueCoinsMetricsWidget extends StatefulWidget {
  const VenueCoinsMetricsWidget({
    super.key,
    required this.venueId,
    this.width,
    this.height,
    this.backgroundColor = const Color(0xFF363740),
    this.textColor = const Color(0xFFFCFDFF),
    this.monthlyColor = const Color(0xFFC5C352),
    this.weeklyColor = const Color(0xFFBF9BF2),
    this.dailyColor = const Color(0xFF6FA6A0),
    this.totalSpendColor = const Color(0xFFFF8B64),
    this.totalCoinsColor = const Color(0xFFF24738),
    this.coinValue = 0.10,
    this.showPreviewData = false,
  });

  final String venueId;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final Color textColor;
  final Color monthlyColor;
  final Color weeklyColor;
  final Color dailyColor;
  final Color totalSpendColor;
  final Color totalCoinsColor;
  final double coinValue;
  final bool showPreviewData;

  @override
  _VenueCoinsMetricsWidgetState createState() =>
      _VenueCoinsMetricsWidgetState();
}

class _VenueCoinsMetricsWidgetState extends State<VenueCoinsMetricsWidget> {
  Map<String, dynamic> _metricsData = {
    'monthly': 0,
    'weekly': 0,
    'daily': 0,
    'totalSpent': 0.0,
    'totalCoins': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetricsData();
  }

  @override
  void didUpdateWidget(VenueCoinsMetricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload metrics if venueId changes
    if (oldWidget.venueId != widget.venueId) {
      _loadMetricsData();
    }
  }

  Future<void> _loadMetricsData() async {
    if (widget.showPreviewData) {
      setState(() {
        _metricsData = {
          'monthly': 568,
          'weekly': 154,
          'daily': 32,
          'totalSpent': 500.0,
          'totalCoins': 5000,
        };
        _isLoading = false;
      });
      return;
    }

    if (widget.venueId.isEmpty) {
      setState(() {
        _metricsData = {
          'monthly': 0,
          'weekly': 0,
          'daily': 0,
          'totalSpent': 0.0,
          'totalCoins': 0,
        };
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading metrics data for venue: ${widget.venueId}');
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Query venueProgress directly for this venue
      print('Querying venueProgress collection for venueId: ${widget.venueId}');
      final venueProgressQuery = await FirebaseFirestore.instance
          .collectionGroup('venueProgress')
          .where('venueId', isEqualTo: widget.venueId)
          .get();

      print('Found ${venueProgressQuery.docs.length} documents with venueId: ${widget.venueId}');

      int dailyCoins = 0;
      int weeklyCoins = 0;
      int monthlyCoins = 0;
      int totalCoins = 0;

      // First, get all unique user IDs and check their verification status
      Map<String, bool> verifiedUsers = {};

      // First pass: Get all verified users
      for (var doc in venueProgressQuery.docs) {
        final userId = doc.reference.parent.parent!.id;
        if (!verifiedUsers.containsKey(userId)) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            verifiedUsers[userId] = (userData != null &&
                userData['email'] != null &&
                (userData['email'] as String).isNotEmpty);
          } else {
            verifiedUsers[userId] = false;
          }
        }
      }

      print('Found ${verifiedUsers.entries.where((e) => e.value).length} verified users');

      // Second pass: Process coins only for verified users
      for (var doc in venueProgressQuery.docs) {
        final userId = doc.reference.parent.parent!.id;

        // Skip if user is not verified
        if (!verifiedUsers.containsKey(userId) || !verifiedUsers[userId]!) continue;

        final data = doc.data();
        final createdTime = (data['created_time'] as Timestamp?)?.toDate();
        if (createdTime == null) continue;

        // Get coin value only from the coin field in venueProgress
        final coinValue = data['coin'] as int? ?? 0;
        if (coinValue <= 0) continue;

        print('Processing coins: User $userId, VenueId: ${widget.venueId}, Coins: $coinValue, Date: $createdTime');
        
        // Add conditional breakpoint - will break only if coin value is above 100
        assert(coinValue <= 100, 'High coin value detected: $coinValue for user $userId');

        // Add coins to appropriate periods
        if (createdTime.isAfter(startOfDay)) {
          dailyCoins += coinValue;
        }
        if (createdTime.isAfter(startOfWeek)) {
          weeklyCoins += coinValue;
        }
        if (createdTime.isAfter(startOfMonth)) {
          monthlyCoins += coinValue;
        }
        // Add to total coins
        totalCoins += coinValue;
      }

      final totalSpent = totalCoins * widget.coinValue;

      if (mounted) {
        setState(() {
          _metricsData = {
            'monthly': monthlyCoins,
            'weekly': weeklyCoins,
            'daily': dailyCoins,
            'totalSpent': totalSpent,
            'totalCoins': totalCoins,
          };
          _isLoading = false;
        });
      }

      print(
          'Updated coin metrics for ${widget.venueId} - Monthly: $monthlyCoins, Weekly: $weeklyCoins, Daily: $dailyCoins, TotalSpent: $totalSpent');
    } catch (e) {
      print('Error loading metrics data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Full width
      constraints: BoxConstraints(
        minWidth: 300, // Minimum width
      ),
      margin: EdgeInsets.zero, // Remove margin as padding is now handled by the parent
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(31.0),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(32.0, 32.0, 32.0, 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
              child: Text(
                'Coins distributed',
                style: TextStyle(
                  fontFamily: 'Roboto Flex',
                  color: widget.textColor,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Two-column layout for metrics
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Monthly section
                      _buildMetricSection(
                        'Monthly',
                        _metricsData['monthly'].toString(),
                        widget.monthlyColor,
                      ),
                      
                      // Weekly section
                      _buildMetricSection(
                        'Weekly',
                        _metricsData['weekly'].toString(),
                        widget.weeklyColor,
                      ),
                      
                      // Daily section
                      _buildMetricSection(
                        'Daily',
                        _metricsData['daily'].toString(),
                        widget.dailyColor,
                      ),
                    ],
                  ),
                ),
                
                // Right column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Coin value section
                      _buildMetricSection(
                        'Coin value',
                        '\$${widget.coinValue.toStringAsFixed(2)}',
                        Colors.white,
                      ),
                      
                      // Total Coins section
                      _buildMetricSection(
                        'Total Coins',
                        _metricsData['totalCoins'].toString(),
                        widget.totalCoinsColor,
                      ),
                      
                      // Total Spent section
                      _buildMetricSection(
                        'Total Spent',
                        '\$${_metricsData['totalSpent'].toStringAsFixed(0)}',
                        widget.totalSpendColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSection(String label, String value, Color valueColor) {
    if (_isLoading) {
      return Padding(
        padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Determine font size based on screen width
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);
    final valueFontSize = isLargeScreen ? 36.0 : 48.0;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: widget.textColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: valueColor,
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 