// Automatic FlutterFlow imports
// Imports other custom widgets
// Imports custom actions
// Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Imports other custom widgets
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _showInfo = false;

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
      print('Loading coin metrics data for venue: ${widget.venueId}');
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = now.subtract(const Duration(days: 7));
      final startOfMonth = now.subtract(const Duration(days: 30));

      // Query userVenueProgress for this venue
      final userVenueProgressQuery = await FirebaseFirestore.instance
          .collection('userVenueProgress')
          .where('venueId', isEqualTo: widget.venueId)
          .get();

      int dailyCoins = 0;
      int weeklyCoins = 0;
      int monthlyCoins = 0;
      int totalCoins = 0;

      for (var doc in userVenueProgressQuery.docs) {
        final data = doc.data();
        // Double-check venueId matches
        if (data['venueId'] != widget.venueId) continue;
        final createdTime = (data['createdTime'] as Timestamp?)?.toDate();
        if (createdTime == null) continue;
        int coins = 0;
        if (data['coinsFromVenue'] is int) {
          coins = data['coinsFromVenue'] as int;
        } else if (data['coinsFromVenue'] is num) {
          coins = (data['coinsFromVenue'] as num).toInt();
        }
        totalCoins += coins;
        if (createdTime.isAfter(startOfMonth)) {
          monthlyCoins += coins;
        }
        if (createdTime.isAfter(startOfWeek)) {
          weeklyCoins += coins;
        }
        if (createdTime.isAfter(startOfDay)) {
          dailyCoins += coins;
        }
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
      print('Updated coin metrics for ${widget.venueId} (userVenueProgress) - Monthly: $monthlyCoins, Weekly: $weeklyCoins, Daily: $dailyCoins, Total Coins: $totalCoins, TotalSpent: $totalSpent');
    } catch (e) {
      print('Error loading metrics data: $e');
      if (mounted) {
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug check to ensure venueId isn't null
    print('VenueCoinsMetricsWidget build called with venueId: "${widget.venueId}"');
    
    return Container(
      width: double.infinity, // Full width
      constraints: const BoxConstraints(
        minWidth: 300, // Minimum width
      ),
      margin: EdgeInsets.zero, // Remove margin as padding is now handled by the parent
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(31.0),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(32.0, 32.0, 32.0, 32.0),
            child: _showInfo ? _buildInfoView() : _buildDataView(),
          ),
          // Info/Close button
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showInfo = !_showInfo;
                });
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.textColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _showInfo ? Icons.close : Icons.info_outline,
                  color: widget.textColor.withOpacity(0.7),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
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
                  
                  // Today section (was Daily)
                  _buildMetricSection(
                    'Today',
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
    );
  }

  Widget _buildInfoView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Coins Distributed',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'This widget tracks loyalty coins distributed to users by your venue:',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor.withOpacity(0.9),
            fontSize: 14.0,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoItem('Monthly/Weekly/Today', 'Coins distributed in each time period'),
        _buildInfoItem('Coin Value', 'Monetary value per coin (\$${widget.coinValue.toStringAsFixed(2)})'),
        _buildInfoItem('Total Coins', 'All-time coins distributed'),
        _buildInfoItem('Total Spent', 'Total monetary value distributed'),
        const SizedBox(height: 12),
        Text(
          'Coins are tracked when users earn them through venue interactions. This helps you understand your loyalty program\'s reach and impact.',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor.withOpacity(0.7),
            fontSize: 12.0,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: widget.textColor.withOpacity(0.7),
              fontSize: 14.0,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontFamily: 'Roboto Flex',
                      color: widget.textColor,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: description,
                    style: TextStyle(
                      fontFamily: 'Roboto Flex',
                      color: widget.textColor.withOpacity(0.8),
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSection(String label, String value, Color valueColor) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Determine font size based on screen width
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final valueFontSize = isLargeScreen 
        ? 18.0 
        : 18.0;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
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