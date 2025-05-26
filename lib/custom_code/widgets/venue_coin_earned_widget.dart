import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/responsive_helper.dart';

class VenueCoinEarnedWidget extends StatefulWidget {
  const VenueCoinEarnedWidget({
    super.key,
    required this.venueId,
    this.width,
    this.height,
    this.backgroundColor = const Color(0xFF363740),
    this.textColor = const Color(0xFFFCFDFF),
    this.monthlyColor = const Color(0xFFC5C352),
    this.weeklyColor = const Color(0xFFBF9BF2),
    this.dailyColor = const Color(0xFF6FA6A0),
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
  final bool showPreviewData;

  @override
  _VenueCoinEarnedWidgetState createState() => _VenueCoinEarnedWidgetState();
}

class _VenueCoinEarnedWidgetState extends State<VenueCoinEarnedWidget> {
  Map<String, dynamic> _metricsData = {
    'monthly': 0,
    'weekly': 0,
    'daily': 0,
    'total': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetricsData();
  }

  @override
  void didUpdateWidget(VenueCoinEarnedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
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
          'total': 0,
        };
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = now.subtract(const Duration(days: 7));
      final startOfMonth = now.subtract(const Duration(days: 30));

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
        if (data['venueId'] != widget.venueId) continue;
        final createdTime = (data['createdTime'] as Timestamp?)?.toDate();
        if (createdTime == null) continue;
        int coins = 0;
        if (data['coins'] != null && data['coins'] is int) {
          coins += data['coins'] as int;
        }
        if (data['coin'] != null && data['coin'] is int) {
          coins += data['coin'] as int;
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

      if (mounted) {
        setState(() {
          _metricsData = {
            'monthly': monthlyCoins,
            'weekly': weeklyCoins,
            'daily': dailyCoins,
            'total': totalCoins,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _metricsData = {
            'monthly': 0,
            'weekly': 0,
            'daily': 0,
            'total': 0,
          };
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minWidth: 300),
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(31.0),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(32.0, 32.0, 32.0, 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
              child: Text(
                'Coin earned',
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
                      _buildMetricSection(
                        'Monthly Coins',
                        _isLoading ? '000' : _metricsData['monthly'].toString().padLeft(3, '0'),
                        widget.monthlyColor,
                      ),
                      _buildMetricSection(
                        'Week',
                        _isLoading ? '000' : _metricsData['weekly'].toString().padLeft(3, '0'),
                        widget.weeklyColor,
                      ),
                    ],
                  ),
                ),
                // Right column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetricSection(
                        'Today',
                        _isLoading ? '000' : _metricsData['daily'].toString().padLeft(3, '0'),
                        widget.dailyColor,
                      ),
                      _buildMetricSection(
                        'Total',
                        _isLoading ? '000' : _metricsData['total'].toString().padLeft(3, '0'),
                        const Color(0xFFF24738),
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
      return const Padding(
        padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final valueFontSize = isLargeScreen 
        ? (isTablet ? 20.0 : 36.0) 
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