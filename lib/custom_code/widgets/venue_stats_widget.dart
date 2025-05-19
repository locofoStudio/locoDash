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

class VenueStatsWidget extends StatefulWidget {
  const VenueStatsWidget({
    super.key,
    required this.venueId,
    this.width,
    this.height,
    this.backgroundColor = const Color(0xFF363740),
    this.textColor = const Color(0xFFFCFDFF),
    this.statsColor = const Color(0xFFC5C352),
    this.showPreviewData = false,
  });

  final String venueId;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final Color textColor;
  final Color statsColor;
  final bool showPreviewData;

  @override
  _VenueStatsWidgetState createState() => _VenueStatsWidgetState();
}

class _VenueStatsWidgetState extends State<VenueStatsWidget> {
  Map<String, dynamic> _metricsData = {
    'totalSessions': 0,
    'totalCoins': 0,
    'avgHighScore': 0,
    'uniquePlayers': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatsData();
  }

  @override
  void didUpdateWidget(VenueStatsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload metrics if venueId changes
    if (oldWidget.venueId != widget.venueId) {
      _loadStatsData();
    }
  }

  Future<void> _loadStatsData() async {
    if (widget.showPreviewData) {
      setState(() {
        _metricsData = {
          'totalSessions': 171,
          'totalCoins': 3576,
          'avgHighScore': 443,
          'uniquePlayers': 18,
        };
        _isLoading = false;
      });
      return;
    }

    if (widget.venueId.isEmpty) {
      setState(() {
        _metricsData = {
          'totalSessions': 0,
          'totalCoins': 0,
          'avgHighScore': 0,
          'uniquePlayers': 0,
        };
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Fetching venue stats for: [33m${widget.venueId}[0m');

      // Query userVenueProgress for this venue
      final userVenueProgressQuery = await FirebaseFirestore.instance
          .collection('userVenueProgress')
          .where('venueId', isEqualTo: widget.venueId)
          .get();

      print('Found [36m${userVenueProgressQuery.docs.length}[0m userVenueProgress entries');

      int totalSessions = 0;
      int totalCoins = 0;
      int totalHighScore = 0;
      int highScoreCount = 0;
      Set<String> uniqueUserIds = {};

      for (var doc in userVenueProgressQuery.docs) {
        final data = doc.data();
        final userId = doc.id;
        uniqueUserIds.add(userId);

        // Sum sessions from sessions field
        totalSessions += data['sessions'] as int? ?? 0;

        // Get coins from both coin and coins fields
        int coins = 0;
        if (data['coins'] != null && data['coins'] is int) {
          coins += data['coins'] as int;
        }
        if (data['coin'] != null && data['coin'] is int) {
          coins += data['coin'] as int;
        }
        totalCoins += coins;

        // Track high scores
        final highScore = data['highScore'] as int? ?? 0;
        if (highScore > 0) {
          totalHighScore += highScore;
          highScoreCount++;
        }
      }

      final avgHighScore =
          highScoreCount > 0 ? (totalHighScore / highScoreCount).round() : 0;

      if (mounted) {
        setState(() {
          _metricsData = {
            'totalSessions': totalSessions,
            'totalCoins': totalCoins,
            'avgHighScore': avgHighScore,
            'uniquePlayers': uniqueUserIds.length,
          };
          _isLoading = false;
        });
      }

      print(
          'VenueStats for ${widget.venueId}: Sessions=$totalSessions, Coins=$totalCoins, AvgScore=$avgHighScore, Players=${uniqueUserIds.length}');
    } catch (e) {
      print('Error getting venue stats: $e');
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
                'Venue Stats',
                style: TextStyle(
                  fontFamily: 'Roboto Flex',
                  color: widget.textColor,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Stats content
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  _buildStatRow('Total Sessions', _metricsData['totalSessions'].toString()),
                  SizedBox(height: 12),
                  _buildStatRow('Total Coins', _metricsData['totalCoins'].toString()),
                  SizedBox(height: 12),
                  _buildStatRow('Avg. High Score', _metricsData['avgHighScore'].toString()),
                  SizedBox(height: 12),
                  _buildStatRow('Unique Players', _metricsData['uniquePlayers'].toString()),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    // Determine font size based on screen width
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);
    final valueFontSize = isLargeScreen ? 24.0 : 24.0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor,
            fontSize: 16.0,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.statsColor,
            fontSize: valueFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 