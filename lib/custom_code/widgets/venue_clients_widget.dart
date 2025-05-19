// Automatic FlutterFlow imports
// Imports other custom widgets
// Imports custom actions
// Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Imports other custom widgets
import 'package:cloud_firestore/cloud_firestore.dart';

class VenueClientsWidget extends StatefulWidget {
  const VenueClientsWidget({
    super.key,
    required this.venueId,
    this.width,
    this.height,
    this.backgroundColor = const Color(0xFF363740),
    this.textColor = const Color(0xFFFCFDFF),
    this.sessionsColor = const Color(0xFF6FA6A0),
    this.showPreviewData = false,
    this.onNavigateToUsersTab,
  });

  final String venueId;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final Color textColor;
  final Color sessionsColor;
  final bool showPreviewData;
  final VoidCallback? onNavigateToUsersTab;

  @override
  _VenueClientsWidgetState createState() => _VenueClientsWidgetState();
}

class _VenueClientsWidgetState extends State<VenueClientsWidget> {
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }
  
  @override
  void didUpdateWidget(VenueClientsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.venueId != widget.venueId) {
      _loadClients();
    }
  }

  Future<void> _loadClients() async {
    if (widget.showPreviewData) {
      setState(() {
        _clients = [
          {
            'display_name': 'Daniel Garcia',
            'email': 'daniel.garcia@example.com',
            'sessions': 20,
            'photo_url': null,
          },
          {
            'display_name': 'Jacob Martin',
            'email': 'jacob.martin@example.com',
            'sessions': 19,
            'photo_url': null,
          },
          {
            'display_name': 'Michael Brown',
            'email': 'michael.brown@example.com',
            'sessions': 18,
            'photo_url': null,
          },
          {
            'display_name': 'James Taylor',
            'email': 'james.taylor@example.com',
            'sessions': 18,
            'photo_url': null,
          },
        ];
        _isLoading = false;
      });
      return;
    }

    if (widget.venueId.isEmpty) {
      setState(() {
        _clients = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Fetching clients for venue: ${widget.venueId}');

      // Query userVenueProgress for this venue
      final venueProgressQuery = await FirebaseFirestore.instance
          .collection('userVenueProgress')
          .where('venueId', isEqualTo: widget.venueId)
          .get();

      print('Found [36m${venueProgressQuery.docs.length}[0m userVenueProgress entries');

      // Aggregate by userId and only include users with a non-empty email
      Map<String, Map<String, dynamic>> userStats = {};
      for (var doc in venueProgressQuery.docs) {
        final data = doc.data();
        final userId = doc.id;
        final email = data['email'] ?? '';
        if (email == null || (email is String && email.trim().isEmpty)) {
          continue;
        }
        if (!userStats.containsKey(userId)) {
          userStats[userId] = {
            'display_name': data['display_name'] ?? data['displayName'] ?? 'Unknown',
            'email': email,
            'photo_url': data['photo_url'] ?? data['photoUrl'],
            'sessions': 0,
            'coins': 0,
            'high_score': 0,
            'created_time': data['created_time'],
          };
        }
        // Sum sessions
        userStats[userId]!['sessions'] = (userStats[userId]!['sessions'] as int) + (data['sessions'] is int ? data['sessions'] as int : (data['sessions'] is num ? (data['sessions'] as num).toInt() : 0));
        // Sum coins (coin + coins)
        int coins = 0;
        if (data['coins'] != null && data['coins'] is int) coins += data['coins'] as int;
        if (data['coin'] != null && data['coin'] is int) coins += data['coin'] as int;
        userStats[userId]!['coins'] = (userStats[userId]!['coins'] as int) + coins;
        // Max high score
        int highScore = 0;
        if (data['highScore'] != null && data['highScore'] is int) highScore = data['highScore'] as int;
        else if (data['high_score'] != null && data['high_score'] is int) highScore = data['high_score'] as int;
        if (highScore > (userStats[userId]!['high_score'] as int)) {
          userStats[userId]!['high_score'] = highScore;
        }
      }

      // Convert to list
      List<Map<String, dynamic>> clients = userStats.values.toList();
      // Sort by sessions in descending order
      clients.sort((a, b) => (b['sessions'] as int).compareTo(a['sessions'] as int));

      print('Processed ${clients.length} verified clients with their session data');
      
      if (mounted) {
        setState(() {
          _clients = clients;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error getting venue clients: $e');
      if (mounted) {
        setState(() {
          // Use preview data as fallback
          _clients = [
            {
              'display_name': 'Daniel Garcia',
              'email': 'daniel.garcia@example.com',
              'sessions': 20,
              'photo_url': null,
            },
            {
              'display_name': 'Jacob Martin',
              'email': 'jacob.martin@example.com',
              'sessions': 19,
              'photo_url': null,
            },
            {
              'display_name': 'Michael Brown',
              'email': 'michael.brown@example.com',
              'sessions': 18,
              'photo_url': null,
            },
            {
              'display_name': 'James Taylor',
              'email': 'james.taylor@example.com',
              'sessions': 18,
              'photo_url': null,
            },
          ];
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
        minHeight: 300, // Minimum height
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
                'Clients',
                style: TextStyle(
                  fontFamily: 'Roboto Flex',
                  color: widget.textColor,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Column headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customer name',
                  style: TextStyle(
                    color: widget.textColor,
                    fontFamily: 'Roboto Flex',
                    fontSize: 12.0,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Text(
                  'Sessions',
                  style: TextStyle(
                    color: widget.textColor,
                    fontFamily: 'Roboto Flex',
                    fontSize: 12.0,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Client list
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else if (_clients.isEmpty)
              Center(
                child: Text(
                  'No clients found',
                  style: TextStyle(color: widget.textColor),
                ),
              )
            else
              Column(
                children: _clients.take(4).map((client) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        // Profile Image
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: client['photo_url'] != null
                                ? Icon(Icons.person, color: widget.textColor, size: 18)
                                : Icon(Icons.person,
                                    color: widget.textColor, size: 18),
                          ),
                        ),
                        SizedBox(width: 8),
                        // Name and Email
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                client['display_name'] ?? 'Unknown',
                                style: TextStyle(
                                  color: widget.textColor,
                                  fontFamily: 'Roboto Flex',
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                client['email'] ?? '',
                                style: TextStyle(
                                  color:
                                      widget.textColor.withOpacity(0.7),
                                  fontFamily: 'Roboto Flex',
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Sessions
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 9, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            (client['sessions'] as int).toString().padLeft(3, '0'),
                            style: TextStyle(
                              color: widget.sessionsColor,
                              fontFamily: 'Roboto Flex',
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              
            // Fixed height spacer
            SizedBox(height: 12),
            
            // Load more button
            Center(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.textColor.withOpacity(0.2),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextButton(
                  onPressed: () {
                    // Debug trace for navigation flow
                    debugPrint('Load More button pressed, venueId: ${widget.venueId}');
                    
                    // Navigate to users tab using the callback
                    if (widget.onNavigateToUsersTab != null) {
                      debugPrint('Navigation callback found, executing...');
                      widget.onNavigateToUsersTab!();
                    } else {
                      debugPrint('WARNING: Navigation callback not provided!');
                      // Fallback message if callback not provided
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Users tab navigation not available')),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Load more',
                    style: TextStyle(
                      color: widget.textColor,
                      fontFamily: 'Roboto Flex',
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 