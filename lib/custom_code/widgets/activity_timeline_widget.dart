import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityTimelineWidget extends StatefulWidget {
  final String venueId;
  final bool showPreviewData;
  final Color backgroundColor;
  final Color textColor;
  final Color primaryColor;

  const ActivityTimelineWidget({
    super.key,
    required this.venueId,
    this.showPreviewData = false,
    this.backgroundColor = const Color(0xFF242529),
    this.textColor = Colors.white,
    this.primaryColor = const Color(0xFFE91E63), // Pink/magenta color
  });

  @override
  _ActivityTimelineWidgetState createState() => _ActivityTimelineWidgetState();
}

class _ActivityTimelineWidgetState extends State<ActivityTimelineWidget> {
  Map<String, int> _hourlyActivity = {};
  List<String> _timeSlots = [];
  bool _isLoading = true;
  bool _showInfo = false;
  int _maxActivity = 0;
  int _selectedDayIndex = 0; // 0=Sunday, 1=Monday, etc.
  List<String> _dayLabels = ['Su', 'M', 'Tu', 'W', 'Th', 'F', 'Sa'];
  Map<int, Map<String, int>> _dailyActivity = {}; // Store activity for each day

  @override
  void initState() {
    super.initState();
    _initializeTimeSlots();
    _loadActivityData();
  }

  @override
  void didUpdateWidget(ActivityTimelineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.venueId != widget.venueId) {
      _loadActivityData();
    }
  }

  void _initializeTimeSlots() {
    _timeSlots = [
      '12a', '3a', '6a', '9a', '12p', '3p', '6p', '9p'
    ];
    
    // Initialize with zero activity
    for (String slot in _timeSlots) {
      _hourlyActivity[slot] = 0;
    }
  }

  Future<void> _loadActivityData() async {
    if (widget.showPreviewData) {
      setState(() {
        _hourlyActivity = {
          '12a': 85,
          '3a': 45,
          '6a': 25,
          '9a': 35,
          '12p': 55,
          '3p': 75,
          '6p': 95,
          '9p': 100,
        };
        _maxActivity = 100;
        _isLoading = false;
      });
      return;
    }

    if (widget.venueId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🕐 Loading activity timeline for venue: ${widget.venueId}');

      // Get all userVenueProgress documents for this venue
      final venueProgressQuery = await FirebaseFirestore.instance
          .collection('userVenueProgress')
          .where('venueId', isEqualTo: widget.venueId)
          .get();

      print('📊 Found ${venueProgressQuery.docs.length} documents for activity analysis');

      // Initialize daily activity storage (0=Sunday, 1=Monday, etc.)
      Map<int, Map<int, int>> dailyHourlyCount = {};
      for (int day = 0; day < 7; day++) {
        dailyHourlyCount[day] = {};
        for (int hour = 0; hour < 24; hour++) {
          dailyHourlyCount[day]![hour] = 0;
        }
      }
      
      int totalEvents = 0;

      // Process each document's sessionMap data
      for (var doc in venueProgressQuery.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        
        print('📱 Processing user: $userId');
        
        // Check sessionMap for session events with timestamps
        if (data['sessionMap'] != null) {
          final sessionMap = data['sessionMap'] as Map<String, dynamic>;
          
          print('🗂️ Found ${sessionMap.length} sessions for user $userId');
          
          for (var sessionKey in sessionMap.keys) {
            final sessionData = sessionMap[sessionKey];
            
            if (sessionData is Map<String, dynamic>) {
              // Check for events array in session
              if (sessionData['events'] != null) {
                final events = sessionData['events'] as List<dynamic>;
                print('⚡ Processing ${events.length} events in session $sessionKey');
                
                for (var event in events) {
                  if (event is Map<String, dynamic> && event['timestamp'] != null) {
                                          try {
                        final timestampStr = event['timestamp'] as String;
                        final timestamp = DateTime.parse(timestampStr);
                        final hour = timestamp.hour;
                        final dayOfWeek = timestamp.weekday % 7; // Convert to 0=Sunday format
                        
                        dailyHourlyCount[dayOfWeek]![hour] = (dailyHourlyCount[dayOfWeek]![hour] ?? 0) + 1;
                        totalEvents++;
                        
                        print('🕐 Event at hour $hour on day $dayOfWeek: ${event['type']} (${timestampStr})');
                      } catch (e) {
                        print('❌ Invalid timestamp: ${event['timestamp']} - $e');
                      }
                  }
                }
              }
              
              // Also check for session start/end times
              if (sessionData['startTime'] != null) {
                try {
                  final startTime = DateTime.parse(sessionData['startTime'] as String);
                  final hour = startTime.hour;
                  final dayOfWeek = startTime.weekday % 7; // Convert to 0=Sunday format
                  dailyHourlyCount[dayOfWeek]![hour] = (dailyHourlyCount[dayOfWeek]![hour] ?? 0) + 1;
                  totalEvents++;
                  print('🎯 Session start at hour $hour on day $dayOfWeek');
                } catch (e) {
                  print('❌ Invalid session startTime: ${sessionData['startTime']}');
                }
              }
              
              if (sessionData['endTime'] != null) {
                try {
                  final endTime = DateTime.parse(sessionData['endTime'] as String);
                  final hour = endTime.hour;
                  final dayOfWeek = endTime.weekday % 7; // Convert to 0=Sunday format
                  dailyHourlyCount[dayOfWeek]![hour] = (dailyHourlyCount[dayOfWeek]![hour] ?? 0) + 1;
                  totalEvents++;
                  print('🏁 Session end at hour $hour on day $dayOfWeek');
                } catch (e) {
                  print('❌ Invalid session endTime: ${sessionData['endTime']}');
                }
              }
            }
          }
        }
        
        // Also check for any direct timestamp fields
        if (data['lastVisited'] != null) {
          try {
            final lastVisited = (data['lastVisited'] as Timestamp).toDate();
            final hour = lastVisited.hour;
            final dayOfWeek = lastVisited.weekday % 7; // Convert to 0=Sunday format
            dailyHourlyCount[dayOfWeek]![hour] = (dailyHourlyCount[dayOfWeek]![hour] ?? 0) + 1;
            totalEvents++;
            print('👤 Last visit at hour $hour on day $dayOfWeek');
          } catch (e) {
            print('❌ Invalid lastVisited timestamp');
          }
        }
      }

      print('📈 Total events processed: $totalEvents');
      print('📊 Daily breakdown: $dailyHourlyCount');

      // Store all daily activity data
      Map<int, Map<String, int>> processedDailyActivity = {};
      
      // Map hours to time slots
      Map<String, List<int>> slotHours = {
        '12a': [0, 1, 2],      // 12am-3am
        '3a': [3, 4, 5],       // 3am-6am
        '6a': [6, 7, 8],       // 6am-9am
        '9a': [9, 10, 11],     // 9am-12pm
        '12p': [12, 13, 14],   // 12pm-3pm
        '3p': [15, 16, 17],    // 3pm-6pm
        '6p': [18, 19, 20],    // 6pm-9pm
        '9p': [21, 22, 23],    // 9pm-12am
      };

      // Process each day's data
      for (int day = 0; day < 7; day++) {
        Map<String, int> daySlotActivity = {};
        for (String slot in _timeSlots) {
          int slotTotal = 0;
          for (int hour in slotHours[slot] ?? []) {
            slotTotal += dailyHourlyCount[day]![hour] ?? 0;
          }
          daySlotActivity[slot] = slotTotal;
          print('🕐 Day $day, Time slot $slot: $slotTotal events');
        }
        processedDailyActivity[day] = daySlotActivity;
      }

      // Get current day's activity and max
      Map<String, int> currentDayActivity = processedDailyActivity[_selectedDayIndex] ?? {};
      int maxActivity = 0;
      for (int value in currentDayActivity.values) {
        if (value > maxActivity) {
          maxActivity = value;
        }
      }

      if (mounted) {
        setState(() {
          _dailyActivity = processedDailyActivity;
          _hourlyActivity = currentDayActivity;
          _maxActivity = maxActivity > 0 ? maxActivity : 1; // Avoid division by zero
          _isLoading = false;
        });
      }

      print('✅ Activity timeline loaded successfully!');
      print('📊 Current day activity: $currentDayActivity');
      print('🎯 Max activity: $maxActivity');
    } catch (e) {
      print('❌ Error loading activity timeline: $e');
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
      constraints: const BoxConstraints(minWidth: 300),
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(31.0),
        // Add a subtle border to ensure the container is visible
        border: Border.all(
          color: widget.textColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(32.0, 32.0, 32.0, 32.0),
            child: _showInfo ? _buildInfoView() : _buildDataView(),
          ),
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
            'Most active times',
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: widget.textColor,
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Day selector
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 32.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              return _buildDayButton(_dayLabels[index], index == _selectedDayIndex, index);
            }),
          ),
        ),

        // Bar chart
        SizedBox(
          height: 140,
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
                  ),
                )
              : _buildBarChart(),
        ),
      ],
    );
  }

  Widget _buildDayButton(String day, bool isSelected, int dayIndex) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDayIndex = dayIndex;
          // Update hourly activity for the selected day
          _hourlyActivity = _dailyActivity[dayIndex] ?? {};
          // Recalculate max activity for the selected day
          _maxActivity = 0;
          for (int value in _hourlyActivity.values) {
            if (value > _maxActivity) {
              _maxActivity = value;
            }
          }
          if (_maxActivity == 0) _maxActivity = 1; // Avoid division by zero
        });
        print('🗓️ Selected day: $day (index: $dayIndex)');
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected 
              ? widget.textColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.textColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: widget.textColor.withOpacity(isSelected ? 1.0 : 0.6),
              fontSize: 14.0,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _timeSlots.map((timeSlot) {
        final activity = _hourlyActivity[timeSlot] ?? 0;
        final heightRatio = _maxActivity > 0 ? (activity / _maxActivity) : 0.0;
        final barHeight = (heightRatio * 100).clamp(8.0, 100.0); // Reduced max height to prevent overflow
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Bar
            Container(
              width: 24,
              height: barHeight,
              decoration: BoxDecoration(
                color: widget.primaryColor,
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    widget.primaryColor,
                    widget.primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8), // Reduced spacing
            // Time label
            Text(
              timeSlot,
              style: TextStyle(
                fontFamily: 'Roboto Flex',
                color: widget.textColor.withOpacity(0.6),
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildInfoView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Timeline',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor,
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'This widget shows user activity patterns throughout the day, grouped into 3-hour time slots.',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor.withOpacity(0.8),
            fontSize: 14.0,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Data is analyzed from session events and activity logs to identify peak usage times for your venue.',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor.withOpacity(0.6),
            fontSize: 12.0,
            height: 1.4,
          ),
        ),
      ],
    );
  }
} 