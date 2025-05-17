// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

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

      // Query venueProgress directly for this venue
      final venueProgressQuery = await FirebaseFirestore.instance
          .collectionGroup('venueProgress')
          .where('venueId', isEqualTo: widget.venueId)
          .get();

      print('Found ${venueProgressQuery.docs.length} venue progress entries');

      // Create a map to store aggregated user data
      Map<String, Map<String, dynamic>> userStats = {};

      // First, get all unique user IDs and check their verification status
      Map<String, bool> verifiedUsers = {};
      for (var doc in venueProgressQuery.docs) {
        final userId = doc.reference.parent.parent!.id;
        if (!verifiedUsers.containsKey(userId)) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            verifiedUsers[userId] = (userData != null &&
                userData['email'] != null &&
                (userData['email'] as String).isNotEmpty);
          } else {
            verifiedUsers[userId] = false;
          }
        }
      }

      print('Found ${verifiedUsers.entries.where((e) => e.value).length} verified users');

      // Process all venue progress entries for verified users only
      for (var doc in venueProgressQuery.docs) {
        final data = doc.data();
        final userId = doc.reference.parent.parent!.id;

        // Skip if user is not verified
        if (!verifiedUsers.containsKey(userId) || !verifiedUsers[userId]!) continue;

        // Initialize user stats if not exists
        if (!userStats.containsKey(userId)) {
          userStats[userId] = {
            'sessions': 0,
            'coins': 0,
            'high_score': 0,
            'created_time': null,
          };
        }

        // Update stats
        final sessions = data['sessions'] as int? ?? 0;
        final coins = data['coin'] as int? ?? 0;

        if (sessions > 0) {
          userStats[userId]!['sessions'] =
              (userStats[userId]!['sessions'] as int) + sessions;
        }

        if (coins > 0) {
          userStats[userId]!['coins'] =
              (userStats[userId]!['coins'] as int) + coins;
        }

        // Track high scores
        final highScore = data['highScore'] as int? ?? 0;
        if (highScore > (userStats[userId]!['high_score'] as int)) {
          userStats[userId]!['high_score'] = highScore;
        }

        // Track earliest created_time
        final createdTime = data['created_time'] as Timestamp?;
        if (createdTime != null) {
          final existingTime = userStats[userId]!['created_time'] as Timestamp?;
          if (existingTime == null || createdTime.compareTo(existingTime) < 0) {
            userStats[userId]!['created_time'] = createdTime;
          }
        }
      }

      // Fetch user details for verified users
      List<Map<String, dynamic>> clients = [];
      for (var userId in userStats.keys) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            clients.add({
              'display_name': userData['display_name'] ??
                  userData['displayName'] ??
                  'Unknown',
              'email': userData['email'] ?? '',
              'photo_url': userData['photo_url'] ?? userData['photoUrl'],
              'sessions': userStats[userId]!['sessions'],
              'coins': userStats[userId]!['coins'],
              'high_score': userStats[userId]!['high_score'],
              'created_time': userStats[userId]!['created_time'],
            });
          }
        }
      }

      // Sort clients by sessions in descending order
      clients.sort(
          (a, b) => (b['sessions'] as int).compareTo(a['sessions'] as int));

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