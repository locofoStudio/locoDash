import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InsightsDashboardWidget extends StatefulWidget {
  final String venueId;
  final bool showPreviewData;
  final Color backgroundColor;
  final Color textColor;
  final Color successColor;

  const InsightsDashboardWidget({
    super.key,
    required this.venueId,
    this.showPreviewData = false,
    this.backgroundColor = const Color(0xFF242529),
    this.textColor = Colors.white,
    this.successColor = const Color(0xFF4CAF50),
  });

  @override
  _InsightsDashboardWidgetState createState() => _InsightsDashboardWidgetState();
}

class _InsightsDashboardWidgetState extends State<InsightsDashboardWidget> {
  Map<String, dynamic> _insights = {};
  bool _isLoading = true;
  bool _showInfo = false;
  String _dateRange = '';

  @override
  void initState() {
    super.initState();
    _loadInsightsData();
  }

  @override
  void didUpdateWidget(InsightsDashboardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.venueId != widget.venueId) {
      _loadInsightsData();
    }
  }

  Future<void> _loadInsightsData() async {
    if (widget.showPreviewData) {
      setState(() {
        _insights = {
          'visits': {'value': '142', 'growth': true},
          'interactions': {'value': '387', 'growth': true},
          'newUsers': {'value': '23', 'growth': false},
          'offersRedeemed': {'value': '15', 'growth': true},
        };
        _dateRange = 'This week';
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
      print('🔍 Loading weekly insights for venue: ${widget.venueId}');

      final now = DateTime.now();
      final thisWeekStart = now.subtract(Duration(days: now.weekday % 7)); // Start of this week (Sunday)
      final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
      final lastWeekEnd = thisWeekStart.subtract(const Duration(days: 1));

      print('📅 This week: ${thisWeekStart.toIso8601String()} to ${now.toIso8601String()}');
      print('📅 Last week: ${lastWeekStart.toIso8601String()} to ${lastWeekEnd.toIso8601String()}');

      // Get all venue data
      final allVenueQuery = await FirebaseFirestore.instance
          .collection('userVenueProgress')
          .where('venueId', isEqualTo: widget.venueId)
          .get();

      // Get offers data
      final offersQuery = await FirebaseFirestore.instance
          .collection('offers')
          .where('venueId', isEqualTo: widget.venueId)
          .get();

      print('📊 Found ${allVenueQuery.docs.length} user progress documents');
      print('🎁 Found ${offersQuery.docs.length} offers');

      // Calculate weekly metrics
      int thisWeekVisits = 0;
      int thisWeekInteractions = 0;
      int thisWeekNewUsers = 0;
      int thisWeekOffersRedeemed = 0;
      int lastWeekVisits = 0;
      int lastWeekInteractions = 0;
      int lastWeekNewUsers = 0;
      int lastWeekOffersRedeemed = 0;

      // Track unique visitors this week
      Set<String> thisWeekVisitors = {};
      Set<String> lastWeekVisitors = {};

      for (var doc in allVenueQuery.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        
        print('👤 Processing user: $userId');
        
        // Get user creation time for new users metric
        DateTime? createdTime;
        if (data['createdTime'] != null) {
          createdTime = (data['createdTime'] as Timestamp).toDate();
        }
        
        // Check if user was created this week or last week
        if (createdTime != null) {
          if (createdTime.isAfter(thisWeekStart)) {
            thisWeekNewUsers++;
            print('👶 New user this week: $userId');
          } else if (createdTime.isAfter(lastWeekStart) && createdTime.isBefore(thisWeekStart)) {
            lastWeekNewUsers++;
            print('👶 New user last week: $userId');
          }
        }
        
        // Process session events for visits and interactions
        if (data['sessionMap'] != null) {
          final sessionMap = data['sessionMap'] as Map<String, dynamic>;
          
          for (var sessionKey in sessionMap.keys) {
            final sessionData = sessionMap[sessionKey];
            
            if (sessionData is Map<String, dynamic>) {
              // Check session timing for visits
              DateTime? sessionTime;
              if (sessionData['startTime'] != null) {
                try {
                  sessionTime = DateTime.parse(sessionData['startTime'] as String);
                } catch (e) {
                  // Try lastVisited as fallback
                  if (data['lastVisited'] != null) {
                    sessionTime = (data['lastVisited'] as Timestamp).toDate();
                  }
                }
              }
              
              if (sessionTime != null) {
                if (sessionTime.isAfter(thisWeekStart)) {
                  thisWeekVisitors.add(userId ?? 'unknown');
                  print('🏠 Visit this week: $userId at ${sessionTime.toIso8601String()}');
                } else if (sessionTime.isAfter(lastWeekStart) && sessionTime.isBefore(thisWeekStart)) {
                  lastWeekVisitors.add(userId ?? 'unknown');
                  print('🏠 Visit last week: $userId at ${sessionTime.toIso8601String()}');
                }
              }
              
              // Process events for interactions
              if (sessionData['events'] != null) {
                final events = sessionData['events'] as List<dynamic>;
                
                for (var event in events) {
                  if (event is Map<String, dynamic> && event['timestamp'] != null) {
                    try {
                      final eventTime = DateTime.parse(event['timestamp'] as String);
                      
                      if (eventTime.isAfter(thisWeekStart)) {
                        thisWeekInteractions++;
                        print('🖱️ Interaction this week: ${event['type']}');
                      } else if (eventTime.isAfter(lastWeekStart) && eventTime.isBefore(thisWeekStart)) {
                        lastWeekInteractions++;
                        print('🖱️ Interaction last week: ${event['type']}');
                      }
                    } catch (e) {
                      print('❌ Invalid event timestamp: ${event['timestamp']}');
                    }
                  }
                }
              }
            }
          }
        }
      }

      // Count unique visits
      thisWeekVisits = thisWeekVisitors.length;
      lastWeekVisits = lastWeekVisitors.length;

      // Process offers for redemption data
      for (var offerDoc in offersQuery.docs) {
        final offerData = offerDoc.data();
        
        if (offerData['redemptions'] != null) {
          final redemptions = offerData['redemptions'] as List<dynamic>;
          
          for (var redemption in redemptions) {
            if (redemption is Map<String, dynamic> && redemption['redeemedAt'] != null) {
              try {
                final redemptionTime = (redemption['redeemedAt'] as Timestamp).toDate();
                
                if (redemptionTime.isAfter(thisWeekStart)) {
                  thisWeekOffersRedeemed++;
                  print('🎁 Offer redeemed this week');
                } else if (redemptionTime.isAfter(lastWeekStart) && redemptionTime.isBefore(thisWeekStart)) {
                  lastWeekOffersRedeemed++;
                  print('🎁 Offer redeemed last week');
                }
              } catch (e) {
                print('❌ Invalid redemption timestamp');
              }
            }
          }
        }
      }

      // Calculate growth indicators (green arrows for up, red for down)
      bool visitsGrowth = thisWeekVisits >= lastWeekVisits;
      bool interactionsGrowth = thisWeekInteractions >= lastWeekInteractions;
      bool newUsersGrowth = thisWeekNewUsers >= lastWeekNewUsers;
      bool offersGrowth = thisWeekOffersRedeemed >= lastWeekOffersRedeemed;

      print('📈 Weekly Insights Summary:');
      print('👥 Visits: This week=$thisWeekVisits, Last week=$lastWeekVisits, Growth=$visitsGrowth');
      print('🖱️ Interactions: This week=$thisWeekInteractions, Last week=$lastWeekInteractions, Growth=$interactionsGrowth');
      print('👶 New Users: This week=$thisWeekNewUsers, Last week=$lastWeekNewUsers, Growth=$newUsersGrowth');
      print('🎁 Offers Redeemed: This week=$thisWeekOffersRedeemed, Last week=$lastWeekOffersRedeemed, Growth=$offersGrowth');

      if (mounted) {
        setState(() {
          _insights = {
            'visits': {
              'value': _formatNumber(thisWeekVisits),
              'growth': visitsGrowth,
            },
            'interactions': {
              'value': _formatNumber(thisWeekInteractions),
              'growth': interactionsGrowth,
            },
            'newUsers': {
              'value': _formatNumber(thisWeekNewUsers),
              'growth': newUsersGrowth,
            },
            'offersRedeemed': {
              'value': _formatNumber(thisWeekOffersRedeemed),
              'growth': offersGrowth,
            },
          };
          _dateRange = 'This week';
          _isLoading = false;
        });
      }

      print('✅ Weekly insights loaded successfully!');
    } catch (e) {
      print('Error loading insights: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
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
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Insights',
              style: TextStyle(
                fontFamily: 'Roboto Flex',
                color: widget.textColor,
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _dateRange,
              style: TextStyle(
                fontFamily: 'Roboto Flex',
                color: widget.textColor.withOpacity(0.6),
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),

        // Metrics
        if (_isLoading)
          Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(widget.successColor),
            ),
          )
        else
          Column(
            children: [
              _buildMetricRow(
                'Visits',
                _insights['visits']?['value'] ?? '0',
                _insights['visits']?['growth'] ?? false,
              ),
              const SizedBox(height: 24),
              _buildMetricRow(
                'Interactions',
                _insights['interactions']?['value'] ?? '0',
                _insights['interactions']?['growth'] ?? false,
              ),
              const SizedBox(height: 24),
              _buildMetricRow(
                'New users',
                _insights['newUsers']?['value'] ?? '0',
                _insights['newUsers']?['growth'] ?? false,
              ),
              const SizedBox(height: 24),
              _buildMetricRow(
                'Offers redeemed',
                _insights['offersRedeemed']?['value'] ?? '0',
                _insights['offersRedeemed']?['growth'] ?? false,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMetricRow(String title, String value, bool hasGrowth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor,
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Roboto Flex',
                color: widget.textColor,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              hasGrowth ? Icons.trending_up : Icons.trending_down,
              color: hasGrowth ? const Color(0xFF4CAF50) : const Color(0xFFE57373), // Green for up, red for down
              size: 20,
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
          'Insights Dashboard',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor,
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Track key weekly performance metrics for your venue compared to the previous week.',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor.withOpacity(0.8),
            fontSize: 14.0,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Metrics include:\n• Visits: Unique users who used the app\n• Interactions: Total clicks and events\n• New users: First-time app users\n• Offers redeemed: Successful offer redemptions',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor.withOpacity(0.6),
            fontSize: 12.0,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Green arrows indicate growth from last week, red arrows indicate decline.',
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