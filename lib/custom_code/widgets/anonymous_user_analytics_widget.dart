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

class AnonymousUserAnalyticsWidget extends StatefulWidget {
  const AnonymousUserAnalyticsWidget({
    super.key,
    required this.venueId,
    this.width,
    this.height,
    this.backgroundColor = const Color(0xFF363740),
    this.textColor = const Color(0xFFFCFDFF),
    this.anonymousColor = const Color(0xFFFF9800),
    this.convertedColor = const Color(0xFF4CAF50),
    this.abandonedColor = const Color(0xFFF44336),
    this.pendingColor = const Color(0xFF2196F3),
    this.showPreviewData = false,
  });

  final String venueId;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final Color textColor;
  final Color anonymousColor;
  final Color convertedColor;
  final Color abandonedColor;
  final Color pendingColor;
  final bool showPreviewData;

  @override
  _AnonymousUserAnalyticsWidgetState createState() => _AnonymousUserAnalyticsWidgetState();
}

class _AnonymousUserAnalyticsWidgetState extends State<AnonymousUserAnalyticsWidget> {
  Map<String, dynamic> _analyticsData = {
    'totalAnonymous': 0,
    'converted': 0,
    'abandoned': 0,
    'pending': 0,
    'conversionRate': 0.0,
    'avgSessionCount': 0.0,
    'totalCoinsEarned': 0,
  };
  bool _isLoading = true;
  bool _showInfo = false;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  @override
  void didUpdateWidget(AnonymousUserAnalyticsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.venueId != widget.venueId) {
      _loadAnalyticsData();
    }
  }

  Future<void> _loadAnalyticsData() async {
    if (widget.showPreviewData) {
      setState(() {
        _analyticsData = {
          'totalAnonymous': 45,
          'converted': 12,
          'abandoned': 8,
          'pending': 25,
          'conversionRate': 26.7,
          'avgSessionCount': 3.2,
          'totalCoinsEarned': 1250,
        };
        _isLoading = false;
      });
      return;
    }

    if (widget.venueId.isEmpty) {
      setState(() {
        _analyticsData = {
          'totalAnonymous': 0,
          'converted': 0,
          'abandoned': 0,
          'pending': 0,
          'conversionRate': 0.0,
          'avgSessionCount': 0.0,
          'totalCoinsEarned': 0,
        };
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading anonymous user analytics for venue: ${widget.venueId}');

      // First, get all userVenueProgress documents for this venue
      final venueProgressQuery = await FirebaseFirestore.instance
          .collection('userVenueProgress')
          .where('venueId', isEqualTo: widget.venueId)
          .get();

      print('Found ${venueProgressQuery.docs.length} userVenueProgress documents for venue ${widget.venueId}');

      int totalAnonymous = 0;
      int converted = 0;
      int abandoned = 0;
      int pending = 0;
      int totalSessions = 0;
      int totalCoinsEarned = 0;
      
      Set<String> venueAnonymousUsers = {};

             // Process venue progress documents and check if they're anonymous
       for (var progressDoc in venueProgressQuery.docs) {
         final progressData = progressDoc.data();
         final userId = progressData['userId'] as String?;
         final userType = progressData['userType'] as String?;
         
         print('Anonymous Analytics - Processing doc: ${progressDoc.id}');
         print('Anonymous Analytics - userId: $userId, userType: $userType');
         
         if (userId == null) {
           print('Anonymous Analytics - No userId found, skipping');
           continue;
         }
         
         // Check if this is an anonymous user (by userType OR displayName)
         final displayName = progressData['displayName'] as String?;
         
         if (userType == 'anonymous' || displayName == 'Guest') {
           print('Anonymous Analytics - Found anonymous user: $userId (userType: $userType, displayName: $displayName)');
           venueAnonymousUsers.add(userId);
           
           // Get user data from users collection for conversion status and metrics
           try {
             final userDoc = await FirebaseFirestore.instance
                 .collection('users')
                 .doc(userId)
                 .get();
                 
             if (userDoc.exists) {
               final userData = userDoc.data() as Map<String, dynamic>;
               
               // Get conversion status from user document
               final conversionStatus = userData['conversionStatus'] as String? ?? 'pending';
               switch (conversionStatus) {
                 case 'converted':
                   converted++;
                   break;
                 case 'abandoned':
                   abandoned++;
                   break;
                 case 'pending':
                 default:
                   pending++;
                   break;
               }
               
               // Get session count from user document
               totalSessions += (userData['sessionCount'] as int? ?? 0);
               
               // Get coins from user document
               totalCoinsEarned += (userData['totalCoinsEarned'] as int? ?? 0);
             } else {
               // User document doesn't exist, default to pending
               pending++;
             }
           } catch (e) {
             print('Error checking user $userId: $e');
             pending++; // Default to pending on error
           }
         }
       }

      totalAnonymous = venueAnonymousUsers.length;
      final conversionRate = totalAnonymous > 0 ? (converted / totalAnonymous) * 100 : 0.0;
      final avgSessionCount = totalAnonymous > 0 ? totalSessions / totalAnonymous : 0.0;

      if (mounted) {
        setState(() {
          _analyticsData = {
            'totalAnonymous': totalAnonymous,
            'converted': converted,
            'abandoned': abandoned,
            'pending': pending,
            'conversionRate': conversionRate,
            'avgSessionCount': avgSessionCount,
            'totalCoinsEarned': totalCoinsEarned,
          };
          _isLoading = false;
        });
      }

      print('Anonymous analytics for ${widget.venueId}: Total=$totalAnonymous, Converted=$converted, Rate=${conversionRate.toStringAsFixed(1)}%');
    } catch (e) {
      print('Error loading anonymous analytics: $e');
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
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
          child: Text(
            'Anonymous Users',
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
        else
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Anonymous',
                      _analyticsData['totalAnonymous'].toString(),
                      widget.anonymousColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Conversion Rate',
                      '${_analyticsData['conversionRate'].toStringAsFixed(1)}%',
                      widget.convertedColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Converted',
                      _analyticsData['converted'].toString(),
                      widget.convertedColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      'Pending',
                      _analyticsData['pending'].toString(),
                      widget.pendingColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      'Abandoned',
                      _analyticsData['abandoned'].toString(),
                      widget.abandonedColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: widget.textColor.withOpacity(0.7),
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: color,
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anonymous User Analytics',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Track anonymous user behavior and conversion patterns at your venue.',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor.withOpacity(0.9),
            fontSize: 14.0,
          ),
        ),
      ],
    );
  }
} 