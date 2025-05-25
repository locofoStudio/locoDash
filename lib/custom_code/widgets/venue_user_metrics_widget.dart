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

class VenueUserMetricsWidget extends StatefulWidget {
  const VenueUserMetricsWidget({
    super.key,
    required this.venueId,
    this.width,
    this.height,
    this.backgroundColor = const Color(0xFF363740),
    this.textColor = const Color(0xFFFCFDFF),
    this.monthlyColor = const Color(0xFFC5C352),
    this.weeklyColor = const Color(0xFFBF9BF2),
    this.dailyColor = const Color(0xFF6FA6A0),
    this.totalColor = const Color(0xFFF24738),
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
  final Color totalColor;
  final bool showPreviewData;

  @override
  _VenueUserMetricsWidgetState createState() => _VenueUserMetricsWidgetState();
}

class _VenueUserMetricsWidgetState extends State<VenueUserMetricsWidget> {
  Map<String, int> _userMetrics = {
    'monthly': 0,
    'weekly': 0,
    'daily': 0,
    'total': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserMetrics();
  }

  @override
  void didUpdateWidget(VenueUserMetricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload metrics if venueId changes
    if (oldWidget.venueId != widget.venueId) {
      _loadUserMetrics();
    }
  }

  Future<void> _loadUserMetrics() async {
    if (widget.showPreviewData) {
      setState(() {
        _userMetrics = {
          'monthly': 568,
          'weekly': 154,
          'daily': 8,
          'total': 1024,
        };
        _isLoading = false;
      });
      return;
    }

    if (widget.venueId.isEmpty) {
      setState(() {
        _userMetrics = {
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
      print('Loading user metrics for venue: ${widget.venueId}');
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = now.subtract(const Duration(days: 7));
      final startOfMonth = now.subtract(const Duration(days: 30));

      // Query userVenueProgress for this venue
      final userVenueProgressQuery = await FirebaseFirestore.instance
          .collection('userVenueProgress')
          .where('venueId', isEqualTo: widget.venueId)
          .get();

      print('Found ${userVenueProgressQuery.docs.length} userVenueProgress documents');

      Set<String> monthlyUsers = {};
      Set<String> weeklyUsers = {};
      Set<String> dailyUsers = {};
      Set<String> totalUsers = {};

      for (var doc in userVenueProgressQuery.docs) {
        final data = doc.data();
        final userId = doc.id;
        final createdTime = (data['createdTime'] as Timestamp?)?.toDate();
        if (createdTime == null) continue;
        totalUsers.add(userId);
        if (createdTime.isAfter(startOfMonth)) {
          monthlyUsers.add(userId);
        }
        if (createdTime.isAfter(startOfWeek)) {
          weeklyUsers.add(userId);
        }
        if (createdTime.isAfter(startOfDay)) {
          dailyUsers.add(userId);
        }
      }

      if (mounted) {
        setState(() {
          _userMetrics = {
            'monthly': monthlyUsers.length,
            'weekly': weeklyUsers.length,
            'daily': dailyUsers.length,
            'total': totalUsers.length,
          };
          _isLoading = false;
        });
      }

      print(
          'Updated user metrics (userVenueProgress) - Monthly: ${monthlyUsers.length}, Weekly: ${weeklyUsers.length}, Daily: ${dailyUsers.length}, Total: ${totalUsers.length}');
    } catch (e) {
      print('Error loading user metrics: $e');
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
      constraints: const BoxConstraints(
        minWidth: 300, // Minimum width
      ),
      margin: EdgeInsets.zero, // Remove margin as padding is now handled by the parent
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
                'Users',
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
                        'Monthly Users',
                        _isLoading ? '000' : _userMetrics['monthly'].toString().padLeft(3, '0'),
                        widget.monthlyColor,
                      ),
                      
                      // Weekly section
                      _buildMetricSection(
                        'Week',
                        _isLoading ? '000' : _userMetrics['weekly'].toString().padLeft(3, '0'),
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
                      // Today section (was Live)
                      _buildMetricSection(
                        'Today',
                        _isLoading ? '000' : _userMetrics['daily'].toString().padLeft(3, '0'),
                        widget.dailyColor,
                      ),
                      
                      // Total section
                      _buildMetricSection(
                        'Total',
                        _isLoading ? '000' : _userMetrics['total'].toString().padLeft(3, '0'),
                        widget.totalColor,
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

    // Determine font size based on screen width
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);
    final valueFontSize = isLargeScreen ? 36.0 : 48.0;

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