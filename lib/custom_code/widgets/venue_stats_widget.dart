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
  Map<String, int> _metricsData = {
    'totalSessions': 0,
    'totalCoins': 0,
    'avgHighScore': 0,
    'uniquePlayers': 0,
    'numOffers': 0,
    'itemsRedeemed': 0,
  };
  bool _isLoading = true;
  bool _showInfo = false;

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
          'numOffers': 3,
          'itemsRedeemed': 12,
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
          'numOffers': 0,
          'itemsRedeemed': 0,
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
      int itemsRedeemed = 0;

      for (var doc in userVenueProgressQuery.docs) {
        final data = doc.data();
        print('Processing document: ${doc.id}');
        print('Document data: $data');
        
        // Get userId directly from document data
        final userId = data['userId'] as String?;
        if (userId == null) {
          print('No userId found in document ${doc.id}');
          continue;
        }
        
        uniqueUserIds.add(userId);

        // Sum sessions from sessions field - check multiple possible field names
        int sessions = 0;
        if (data['sessions'] != null) {
          sessions = data['sessions'] as int? ?? 0;
        } else if (data['sessionCount'] != null) {
          sessions = data['sessionCount'] as int? ?? 0;
        }
        totalSessions += sessions;
        print('User $userId: sessions=$sessions');

        // Get coins from multiple possible fields
        int coins = 0;
        if (data['coins'] != null && data['coins'] is int) {
          coins += data['coins'] as int;
        }
        if (data['coin'] != null && data['coin'] is int) {
          coins += data['coin'] as int;
        }
        if (data['coinsFromGame'] != null && data['coinsFromGame'] is int) {
          coins += data['coinsFromGame'] as int;
        }
        if (data['coinsFromVenue'] != null && data['coinsFromVenue'] is int) {
          coins += data['coinsFromVenue'] as int;
        }
        totalCoins += coins;
        print('User $userId: coins=$coins');

        // Track high scores
        final highScore = data['highScore'] as int? ?? 0;
        if (highScore > 0) {
          totalHighScore += highScore;
          highScoreCount++;
        }
        print('User $userId: highScore=$highScore');
      }

      final avgHighScore =
          highScoreCount > 0 ? (totalHighScore / highScoreCount).round() : 0;

      // Query offers collection for this venue
      int numOffers = 0;
      itemsRedeemed = 0; // reset, will be calculated from offers
      try {
        final offersQuery = await FirebaseFirestore.instance
            .collection('offers')
            .where('venueId', isEqualTo: widget.venueId)
            .get();
        numOffers = offersQuery.docs.length;

        // Sum the number of redeemed users across all offers.
        for (var doc in offersQuery.docs) {
          final data = doc.data();
          if (data['redeemedUsers'] is List) {
            itemsRedeemed += (data['redeemedUsers'] as List).length;
          }
        }
      } catch (e) {
        print('Error fetching offers: $e');
      }

      if (mounted) {
        setState(() {
          _metricsData = {
            'totalSessions': totalSessions,
            'totalCoins': totalCoins,
            'avgHighScore': avgHighScore,
            'uniquePlayers': uniqueUserIds.length,
            'numOffers': numOffers,
            'itemsRedeemed': itemsRedeemed,
          };
          _isLoading = false;
        });
      }

      print(
          'VenueStats for ${widget.venueId}: Sessions=$totalSessions, Coins=$totalCoins, AvgScore=$avgHighScore, Players=${uniqueUserIds.length}, Offers=$numOffers, Redeemed=$itemsRedeemed');
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
          const Center(child: CircularProgressIndicator())
        else
          Column(
            children: [
              _buildStatRow('Total Sessions', _metricsData['totalSessions'].toString()),
              const SizedBox(height: 12),
              _buildStatRow('Total Coins', _metricsData['totalCoins'].toString()),
              const SizedBox(height: 12),
              _buildStatRow('Avg. High Score', _metricsData['avgHighScore'].toString()),
              const SizedBox(height: 12),
              _buildStatRow('Unique Players', _metricsData['uniquePlayers'].toString()),
              const SizedBox(height: 12),
              _buildStatRow('Number of Offers', _metricsData['numOffers'].toString()),
              const SizedBox(height: 12),
              _buildStatRow('Items Redeemed', _metricsData['itemsRedeemed'].toString()),
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
          'Venue Statistics',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Comprehensive overview of your venue\'s performance metrics:',
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor.withOpacity(0.9),
            fontSize: 14.0,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoItem('Total Sessions', 'Cumulative user sessions at your venue'),
        _buildInfoItem('Total Coins', 'All coins earned by users from your venue'),
        _buildInfoItem('Avg. High Score', 'Average of all user high scores'),
        _buildInfoItem('Unique Players', 'Number of distinct users who visited'),
        _buildInfoItem('Number of Offers', 'Active offers available at your venue'),
        _buildInfoItem('Items Redeemed', 'Total offer redemptions by users'),
        const SizedBox(height: 12),
        Text(
          'These metrics provide insight into user engagement, loyalty program effectiveness, and overall venue performance.',
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

  Widget _buildStatRow(String label, String value) {
    // Determine font size based on screen width
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final valueFontSize = isLargeScreen 
        ? 18.0 
        : 18.0;
    
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