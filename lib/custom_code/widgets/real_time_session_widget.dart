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

class RealTimeSessionWidget extends StatefulWidget {
  const RealTimeSessionWidget({
    super.key,
    required this.venueId,
    this.width,
    this.height,
    this.backgroundColor = const Color(0xFF363740),
    this.textColor = const Color(0xFFFCFDFF),
    this.activeColor = const Color(0xFF4CAF50),
    this.pausedColor = const Color(0xFFFF9800),
    this.visitorColor = const Color(0xFF6FA6A0),
    this.authenticatedColor = const Color(0xFFC5C352),
    this.showPreviewData = false,
  });

  final String venueId;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final Color textColor;
  final Color activeColor;
  final Color pausedColor;
  final Color visitorColor;
  final Color authenticatedColor;
  final bool showPreviewData;

  @override
  _RealTimeSessionWidgetState createState() => _RealTimeSessionWidgetState();
}

class _RealTimeSessionWidgetState extends State<RealTimeSessionWidget> {
  Map<String, dynamic> _sessionData = {
    'activeSessions': 0,
    'pausedSessions': 0,
    'visitorSessions': 0,
    'authenticatedSessions': 0,
    'avgDuration': '0m',
  };
  bool _isLoading = true;
  bool _showInfo = false;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  @override
  void didUpdateWidget(RealTimeSessionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.venueId != widget.venueId) {
      _loadSessionData();
    }
  }

  Future<void> _loadSessionData() async {
    if (widget.showPreviewData) {
      setState(() {
        _sessionData = {
          'activeSessions': 3,
          'pausedSessions': 1,
          'visitorSessions': 2,
          'authenticatedSessions': 2,
          'avgDuration': '4m',
        };
        _isLoading = false;
      });
      return;
    }

    if (widget.venueId.isEmpty) {
      setState(() {
        _sessionData = {
          'activeSessions': 0,
          'pausedSessions': 0,
          'visitorSessions': 0,
          'authenticatedSessions': 0,
          'avgDuration': '0m',
        };
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('RealTimeSessionWidget: Loading session data for venue: ${widget.venueId}');
      
      // Query userVenueProgress for this venue
      final userVenueProgressQuery = await FirebaseFirestore.instance
          .collection('userVenueProgress')
          .where('venueId', isEqualTo: widget.venueId)
          .get();

      print('RealTimeSessionWidget: Found ${userVenueProgressQuery.docs.length} userVenueProgress documents');

      int activeSessions = 0;
      int visitorSessions = 0;
      int authenticatedSessions = 0;
      List<int> sessionDurations = [];

      final now = DateTime.now();
      final activeThreshold = now.subtract(const Duration(minutes: 3)); // 3 minutes as specified
      
      print('RealTimeSessionWidget: Looking for events after ${activeThreshold.toIso8601String()}');

      for (var doc in userVenueProgressQuery.docs) {
        final data = doc.data();
        print('RealTimeSessionWidget: Processing document ${doc.id}');
        
        // Check for sessionMap field
        final sessionMap = data['sessionMap'] as Map<String, dynamic>?;
        
        if (sessionMap != null) {
          print('RealTimeSessionWidget: Found sessionMap with ${sessionMap.length} sessions');
          
          // Process each session in the sessionMap
          for (var sessionEntry in sessionMap.entries) {
            final sessionId = sessionEntry.key;
            final sessionData = sessionEntry.value as Map<String, dynamic>?;
            if (sessionData == null) continue;

            print('RealTimeSessionWidget: Processing session $sessionId');

            // Get events array from session
            final events = sessionData['events'] as List<dynamic>?;
            if (events == null || events.isEmpty) {
              print('RealTimeSessionWidget: No events found in session $sessionId');
              continue;
            }

            print('RealTimeSessionWidget: Found ${events.length} events in session $sessionId');

            // Check if any event has a timestamp within the last 3 minutes
            bool hasRecentActivity = false;
            List<DateTime> eventTimestamps = [];

            for (var event in events) {
              if (event is Map<String, dynamic>) {
                final timestamp = event['timestamp'];
                DateTime? eventTime;
                
                if (timestamp is Timestamp) {
                  eventTime = timestamp.toDate();
                } else if (timestamp is String) {
                  try {
                    eventTime = DateTime.parse(timestamp);
                  } catch (e) {
                    print('RealTimeSessionWidget: Could not parse timestamp string: $timestamp');
                  }
                } else if (timestamp is int) {
                  // Handle milliseconds timestamp
                  eventTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
                }

                if (eventTime != null) {
                  eventTimestamps.add(eventTime);
                  if (eventTime.isAfter(activeThreshold)) {
                    hasRecentActivity = true;
                    print('RealTimeSessionWidget: Found recent activity at ${eventTime.toIso8601String()}');
                  }
                }
              }
            }

            // If session has recent activity, count it as active
            if (hasRecentActivity) {
              activeSessions++;
              
              // Determine if user is anonymous or authenticated
              // Check multiple possible fields for user type
              final userType = sessionData['userType'] as String?;
              final userId = sessionData['userId'] as String?;
              final isAnonymous = sessionData['isAnonymous'] as bool?;
              
              bool isVisitor = true; // Default to visitor
              
              if (userType == 'authenticated' || userType == 'registered') {
                isVisitor = false;
              } else if (userId != null && userId.isNotEmpty && !userId.startsWith('anonymous')) {
                isVisitor = false;
              } else if (isAnonymous == false) {
                isVisitor = false;
              }
              
              if (isVisitor) {
                visitorSessions++;
                print('RealTimeSessionWidget: Counted as visitor session');
              } else {
                authenticatedSessions++;
                print('RealTimeSessionWidget: Counted as authenticated session');
              }

              // Calculate session duration from first to last timestamp
              if (eventTimestamps.length >= 2) {
                eventTimestamps.sort();
                final firstTimestamp = eventTimestamps.first;
                final lastTimestamp = eventTimestamps.last;
                final durationMs = lastTimestamp.difference(firstTimestamp).inMilliseconds;
                sessionDurations.add((durationMs / 1000).round()); // Convert to seconds
                print('RealTimeSessionWidget: Session duration: ${durationMs / 1000} seconds');
              } else if (eventTimestamps.length == 1) {
                // Single event, assume minimal duration
                sessionDurations.add(30); // 30 seconds default
              }
            }
          }
        } else {
          print('RealTimeSessionWidget: No sessionMap found in document ${doc.id}');
        }
      }

      // Calculate average duration
      String avgDuration = '0m';
      if (sessionDurations.isNotEmpty) {
        final avgSeconds = sessionDurations.reduce((a, b) => a + b) / sessionDurations.length;
        final minutes = (avgSeconds / 60).round();
        if (minutes > 0) {
          avgDuration = '${minutes}m';
        } else {
          avgDuration = '${avgSeconds.round()}s';
        }
      }

      if (mounted) {
        setState(() {
          _sessionData = {
            'activeSessions': activeSessions,
            'pausedSessions': 0, // Not tracking paused sessions in this implementation
            'visitorSessions': visitorSessions,
            'authenticatedSessions': authenticatedSessions,
            'avgDuration': avgDuration,
          };
          _isLoading = false;
        });
      }

      print('RealTimeSessionWidget: Final results - Active: $activeSessions, Visitors: $visitorSessions, Auth: $authenticatedSessions, Avg Duration: $avgDuration');
    } catch (e) {
      print('RealTimeSessionWidget: Error loading session data: $e');
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.activeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Live Sessions',
                style: TextStyle(
                  fontFamily: 'Roboto Flex',
                  color: widget.textColor,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
                    'Active',
                    _isLoading ? '00' : _sessionData['activeSessions'].toString().padLeft(2, '0'),
                    widget.activeColor,
                  ),
                  _buildMetricSection(
                    'Visitors',
                    _isLoading ? '00' : _sessionData['visitorSessions'].toString().padLeft(2, '0'),
                    widget.visitorColor,
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
                    'Registered',
                    _isLoading ? '00' : _sessionData['authenticatedSessions'].toString().padLeft(2, '0'),
                    widget.authenticatedColor,
                  ),
                  // Empty space to maintain layout balance
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),

        // Average duration
        const SizedBox(height: 16),
        _buildMetricSection(
          'Avg Duration',
          _isLoading ? '0m' : _sessionData['avgDuration'],
          widget.textColor.withOpacity(0.8),
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
          'Live Sessions Monitor',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'This widget shows real-time user activity on your venue page:',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor.withOpacity(0.9),
            fontSize: 14.0,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoItem('Active', 'Users currently browsing (last 3 minutes)'),
        _buildInfoItem('Visitors', 'Anonymous users exploring your venue'),
        _buildInfoItem('Registered', 'Signed-in users with accounts'),
        _buildInfoItem('Avg Duration', 'Average time spent per session'),
        const SizedBox(height: 12),
        Text(
          'Data updates automatically from user session tracking. Sessions are considered active if there\'s been activity in the last 3 minutes.',
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

    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);
    final valueFontSize = isLargeScreen ? 18.0 : 18.0;

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