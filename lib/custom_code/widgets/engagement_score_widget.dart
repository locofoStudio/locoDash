// Automatic FlutterFlow imports
// Imports other custom widgets
// Imports custom actions
// Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Imports other custom widgets
import 'package:cloud_firestore/cloud_firestore.dart';

class EngagementScoreWidget extends StatefulWidget {
  const EngagementScoreWidget({
    super.key,
    required this.venueId,
    this.width,
    this.height,
    this.backgroundColor = const Color(0xFF363740),
    this.textColor = const Color(0xFFFCFDFF),
    this.excellentColor = const Color(0xFF4CAF50),
    this.goodColor = const Color(0xFFC5C352),
    this.averageColor = const Color(0xFFFF9800),
    this.poorColor = const Color(0xFFF24738),
    this.showPreviewData = false,
  });

  final String venueId;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final Color textColor;
  final Color excellentColor;
  final Color goodColor;
  final Color averageColor;
  final Color poorColor;
  final bool showPreviewData;

  @override
  _EngagementScoreWidgetState createState() => _EngagementScoreWidgetState();
}

class _EngagementScoreWidgetState extends State<EngagementScoreWidget> {
  Map<String, dynamic> _engagementData = {
    'overallScore': 0.0,
    'qualityDistribution': {
      'excellent': 0,
      'good': 0,
      'average': 0,
      'poor': 0,
    },
    'avgDuration': 0.0,
    'conversionRate': 0.0,
    'totalSessions': 0,
  };
  bool _isLoading = true;
  bool _showInfo = false;

  @override
  void initState() {
    super.initState();
    _loadEngagementData();
  }

  @override
  void didUpdateWidget(EngagementScoreWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.venueId != widget.venueId) {
      _loadEngagementData();
    }
  }

  Future<void> _loadEngagementData() async {
    if (widget.venueId.isEmpty) {
      setState(() {
        _engagementData = {
          'overallScore': 0.0,
          'qualityDistribution': {
            'excellent': 0,
            'good': 0,
            'average': 0,
            'poor': 0,
          },
          'avgDuration': 0.0,
          'conversionRate': 0.0,
          'totalSessions': 0,
        };
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('EngagementScoreWidget: Loading engagement data for venue: ${widget.venueId}');
      
      // Query userVenueProgress for this venue
      final userVenueProgressQuery = await FirebaseFirestore.instance
          .collection('userVenueProgress')
          .where('venueId', isEqualTo: widget.venueId)
          .get();

      List<double> sessionScores = [];
      List<double> durations = [];
      int totalSessions = 0;
      int conversions = 0;
      
      Map<String, int> qualityDistribution = {
        'excellent': 0,
        'good': 0,
        'average': 0,
        'poor': 0,
      };

      for (var doc in userVenueProgressQuery.docs) {
        final data = doc.data();
        final sessionMap = data['sessionMap'] as Map<String, dynamic>?;
        
        if (sessionMap != null) {
          // Process each session in the sessionMap
          for (var sessionEntry in sessionMap.entries) {
            final sessionData = sessionEntry.value as Map<String, dynamic>?;
            if (sessionData == null) continue;

            totalSessions++;
            
            // Calculate session score based on duration, interactions, and value events
            final duration = (sessionData['duration'] as int? ?? 0) / 1000.0; // Convert to seconds
            final totalEvents = sessionData['totalEvents'] as int? ?? 0;
            final valueEvents = sessionData['valueEvents'] as int? ?? 0;
            
            durations.add(duration);
            
            // Check for conversions (value events)
            if (valueEvents > 0) {
              conversions++;
            }
            
            // Calculate engagement score (0-100)
            double score = _calculateSessionScore(duration, totalEvents, valueEvents);
            sessionScores.add(score);
            
            // Categorize session quality
            if (score >= 80) {
              qualityDistribution['excellent'] = qualityDistribution['excellent']! + 1;
            } else if (score >= 60) {
              qualityDistribution['good'] = qualityDistribution['good']! + 1;
            } else if (score >= 40) {
              qualityDistribution['average'] = qualityDistribution['average']! + 1;
            } else {
              qualityDistribution['poor'] = qualityDistribution['poor']! + 1;
            }
          }
        }
      }

      // Calculate averages
      double overallScore = sessionScores.isNotEmpty 
          ? sessionScores.reduce((a, b) => a + b) / sessionScores.length 
          : 0.0;
      
      double avgDuration = durations.isNotEmpty 
          ? durations.reduce((a, b) => a + b) / durations.length 
          : 0.0;
      
      double conversionRate = totalSessions > 0 
          ? (conversions / totalSessions) * 100 
          : 0.0;

      if (mounted) {
        setState(() {
          _engagementData = {
            'overallScore': overallScore,
            'qualityDistribution': qualityDistribution,
            'avgDuration': avgDuration,
            'conversionRate': conversionRate,
            'totalSessions': totalSessions,
          };
          _isLoading = false;
        });
      }

      print('EngagementScoreWidget: Updated engagement data - Score: ${overallScore.toStringAsFixed(1)}, Sessions: $totalSessions, Conversions: $conversions');
    } catch (e) {
      print('EngagementScoreWidget: Error loading engagement data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  double _calculateSessionScore(double duration, int totalEvents, int valueEvents) {
    // Weighted scoring algorithm
    double durationScore = 0.0;
    double interactionScore = 0.0;
    double valueScore = 0.0;
    
    // Duration scoring (0-30 points) - optimal around 2-5 minutes
    if (duration >= 120 && duration <= 300) { // 2-5 minutes
      durationScore = 30.0;
    } else if (duration >= 60) { // 1+ minutes
      durationScore = 20.0;
    } else if (duration >= 30) { // 30+ seconds
      durationScore = 10.0;
    }
    
    // Interaction scoring (0-40 points) - more interactions = higher engagement
    if (totalEvents >= 20) {
      interactionScore = 40.0;
    } else if (totalEvents >= 10) {
      interactionScore = 30.0;
    } else if (totalEvents >= 5) {
      interactionScore = 20.0;
    } else if (totalEvents >= 2) {
      interactionScore = 10.0;
    }
    
    // Value event scoring (0-30 points) - conversions are most valuable
    if (valueEvents >= 3) {
      valueScore = 30.0;
    } else if (valueEvents >= 2) {
      valueScore = 25.0;
    } else if (valueEvents >= 1) {
      valueScore = 20.0;
    }
    
    return durationScore + interactionScore + valueScore;
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return widget.excellentColor;
    if (score >= 60) return widget.goodColor;
    if (score >= 40) return widget.averageColor;
    return widget.poorColor;
  }

  String _getScoreLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Average';
    return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minWidth: 300,
      ),
      margin: EdgeInsets.zero,
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
    final overallScore = _engagementData['overallScore'] as double;
    final scoreColor = _getScoreColor(overallScore);
    final scoreLabel = _getScoreLabel(overallScore);
    final qualityDistribution = _engagementData['qualityDistribution'] as Map<String, int>;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
          child: Text(
            'Engagement Score',
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: widget.textColor,
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          // Overall score
          Center(
            child: Column(
              children: [
                Text(
                  overallScore.toStringAsFixed(1),
                  style: TextStyle(
                    fontFamily: 'Roboto Flex',
                    color: scoreColor,
                    fontSize: 36.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  scoreLabel,
                  style: TextStyle(
                    fontFamily: 'Roboto Flex',
                    color: scoreColor,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Quality distribution
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQualityItem('Excellent', qualityDistribution['excellent']!, widget.excellentColor),
              _buildQualityItem('Good', qualityDistribution['good']!, widget.goodColor),
              _buildQualityItem('Average', qualityDistribution['average']!, widget.averageColor),
              _buildQualityItem('Poor', qualityDistribution['poor']!, widget.poorColor),
            ],
          ),

          const SizedBox(height: 20),

          // Key metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricSection(
                  'Avg Duration',
                  '${((_engagementData['avgDuration'] as double) / 60).toStringAsFixed(1)}m',
                  widget.textColor.withOpacity(0.8),
                ),
              ),
              Expanded(
                child: _buildMetricSection(
                  'Conversion Rate',
                  '${(_engagementData['conversionRate'] as double).toStringAsFixed(1)}%',
                  widget.textColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInfoView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Engagement Quality Score',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'This widget calculates user engagement quality using a weighted algorithm:',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor.withOpacity(0.9),
            fontSize: 14.0,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoItem('Duration Score (30%)', 'Time spent on page (optimal: 2-5 minutes)'),
        _buildInfoItem('Interaction Score (40%)', 'Button clicks and feature usage'),
        _buildInfoItem('Value Score (30%)', 'Conversions like earning/spending coins'),
        const SizedBox(height: 12),
        Text(
          'Score ranges:',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor,
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _buildScoreRange('Excellent', '80-100', widget.excellentColor),
        _buildScoreRange('Good', '60-79', widget.goodColor),
        _buildScoreRange('Average', '40-59', widget.averageColor),
        _buildScoreRange('Poor', '0-39', widget.poorColor),
        const SizedBox(height: 12),
        Text(
          'Higher scores indicate more engaged users who are likely to return and convert. Use this metric to optimize your venue experience.',
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

  Widget _buildScoreRange(String label, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label ($range)',
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: widget.textColor.withOpacity(0.8),
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: color,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor.withOpacity(0.7),
            fontSize: 12.0,
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
              fontSize: 12.0,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: valueColor,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 