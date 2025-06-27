// Automatic FlutterFlow imports
// Imports other custom widgets
// Imports custom actions
// Imports custom functions
import 'dart:async';
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
    'monthlyAnonymous': 0,
    'weeklyAnonymous': 0,
    'dailyAnonymous': 0,
    'totalAnonymous': 0,
  };
  bool _isLoading = true;
  bool _showInfo = false;
  StreamSubscription<QuerySnapshot>? _userMetricsSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToUserMetrics();
  }

  @override
  void didUpdateWidget(VenueUserMetricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.venueId != widget.venueId) {
      _subscribeToUserMetrics();
    }
  }

  @override
  void dispose() {
    _userMetricsSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToUserMetrics() {
    _userMetricsSubscription?.cancel();

    if (widget.venueId.isEmpty) {
      setState(() {
        _userMetrics = {
          'monthly': 0,
          'weekly': 0,
          'daily': 0,
          'total': 0,
          'monthlyAnonymous': 0,
          'weeklyAnonymous': 0,
          'dailyAnonymous': 0,
          'totalAnonymous': 0,
        };
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final query = FirebaseFirestore.instance
        .collection('userVenueProgress')
        .where('venueId', isEqualTo: widget.venueId);

    _userMetricsSubscription = query.snapshots().listen((snapshot) {
      print('Received update from userVenueProgress stream');
      _processUserMetrics(snapshot);
    }, onError: (error) {
      print('Error listening to user metrics: $error');
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _processUserMetrics(QuerySnapshot snapshot) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = now.subtract(const Duration(days: 7));
    final startOfMonth = now.subtract(const Duration(days: 30));

    Set<String> monthlyUsers = {};
    Set<String> weeklyUsers = {};
    Set<String> dailyUsers = {};
    Set<String> totalUsers = {};
    Set<String> monthlyAnonymous = {};
    Set<String> weeklyAnonymous = {};
    Set<String> dailyAnonymous = {};
    Set<String> totalAnonymous = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final userId = data['userId'] as String?;
      if (userId == null) continue;

      totalUsers.add(userId);

      final displayName = data['displayName'] as String?;
      final isAnonymous = displayName == 'Guest';
      if (isAnonymous) {
        totalAnonymous.add(userId);
      }

      DateTime? timeToUse;
      if (data['sessionLastUpdated'] != null) {
        if (data['sessionLastUpdated'] is Timestamp) {
          timeToUse = (data['sessionLastUpdated'] as Timestamp).toDate();
        } else if (data['sessionLastUpdated'] is String) {
          try {
            timeToUse = DateTime.parse(data['sessionLastUpdated'] as String);
          } catch (e) {
            // Fallback will be used
          }
        }
      }
      if (timeToUse == null && data['createdTime'] is Timestamp) {
        timeToUse = (data['createdTime'] as Timestamp).toDate();
      }

      if (timeToUse != null) {
        if (timeToUse.isAfter(startOfMonth)) {
          monthlyUsers.add(userId);
          if (isAnonymous) monthlyAnonymous.add(userId);
        }
        if (timeToUse.isAfter(startOfWeek)) {
          weeklyUsers.add(userId);
          if (isAnonymous) weeklyAnonymous.add(userId);
        }
        if (timeToUse.isAfter(startOfDay)) {
          dailyUsers.add(userId);
          if (isAnonymous) dailyAnonymous.add(userId);
        }
      }
    }

    if (mounted) {
      setState(() {
        _userMetrics = {
          'monthly': monthlyUsers.length,
          'weekly': weeklyUsers.length,
          'daily': dailyUsers.length,
          'total': totalUsers.length,
          'monthlyAnonymous': monthlyAnonymous.length,
          'weeklyAnonymous': weeklyAnonymous.length,
          'dailyAnonymous': dailyAnonymous.length,
          'totalAnonymous': totalAnonymous.length,
        };
        _isLoading = false;
      });
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
            // Left column - Regular Users
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registered Users',
                    style: TextStyle(
                      fontFamily: 'Roboto Flex',
                      color: widget.textColor.withOpacity(0.8),
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Monthly section
                  _buildMetricSection(
                    'Monthly',
                    _isLoading ? '000' : (_userMetrics['monthly']! - _userMetrics['monthlyAnonymous']!).toString().padLeft(3, '0'),
                    widget.monthlyColor,
                  ),
                  
                  // Weekly section
                  _buildMetricSection(
                    'Week',
                    _isLoading ? '000' : (_userMetrics['weekly']! - _userMetrics['weeklyAnonymous']!).toString().padLeft(3, '0'),
                    widget.weeklyColor,
                  ),
                  
                  // Today section
                  _buildMetricSection(
                    'Today',
                    _isLoading ? '000' : (_userMetrics['daily']! - _userMetrics['dailyAnonymous']!).toString().padLeft(3, '0'),
                    widget.dailyColor,
                  ),
                  
                  // Total section
                  _buildMetricSection(
                    'Total',
                    _isLoading ? '000' : (_userMetrics['total']! - _userMetrics['totalAnonymous']!).toString().padLeft(3, '0'),
                    widget.totalColor,
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 24),
            
            // Right column - Anonymous Users
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anonymous Users',
                    style: TextStyle(
                      fontFamily: 'Roboto Flex',
                      color: widget.textColor.withOpacity(0.8),
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Monthly Anonymous section
                  _buildMetricSection(
                    'Monthly',
                    _isLoading ? '000' : _userMetrics['monthlyAnonymous'].toString().padLeft(3, '0'),
                    widget.monthlyColor.withOpacity(0.7),
                  ),
                  
                  // Weekly Anonymous section
                  _buildMetricSection(
                    'Week',
                    _isLoading ? '000' : _userMetrics['weeklyAnonymous'].toString().padLeft(3, '0'),
                    widget.weeklyColor.withOpacity(0.7),
                  ),
                  
                  // Today Anonymous section
                  _buildMetricSection(
                    'Today',
                    _isLoading ? '000' : _userMetrics['dailyAnonymous'].toString().padLeft(3, '0'),
                    widget.dailyColor.withOpacity(0.7),
                  ),
                  
                  // Total Anonymous section
                  _buildMetricSection(
                    'Total',
                    _isLoading ? '000' : _userMetrics['totalAnonymous'].toString().padLeft(3, '0'),
                    widget.totalColor.withOpacity(0.7),
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
          'User Metrics',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'This widget tracks unique users who have visited your venue:',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor.withOpacity(0.9),
            fontSize: 14.0,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoItem('Monthly Users', 'Unique visitors in the last 30 days'),
        _buildInfoItem('Week', 'Unique visitors in the last 7 days'),
        _buildInfoItem('Today', 'Unique visitors today'),
        _buildInfoItem('Total', 'All-time unique visitors'),
        const SizedBox(height: 12),
        Text(
          'Users are counted when they first interact with your venue page. Each user is only counted once per time period.',
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