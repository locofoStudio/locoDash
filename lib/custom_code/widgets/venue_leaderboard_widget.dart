// Automatic FlutterFlow imports
// Imports other custom widgets
// Imports custom actions
// Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Imports other custom widgets
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VenueLeaderboardWidget extends StatefulWidget {
  const VenueLeaderboardWidget({
    super.key,
    required this.venueId,
    this.width = 368.0,
    this.height = 600.0,
    this.backgroundColor = const Color(0xFF363740),
    this.textColor = const Color(0xFFFCFDFF),
    this.showPreviewData = false,
  });

  final String venueId;
  final double width;
  final double height;
  final Color backgroundColor;
  final Color textColor;
  final bool showPreviewData;

  @override
  _VenueLeaderboardWidgetState createState() => _VenueLeaderboardWidgetState();
}

class _VenueLeaderboardWidgetState extends State<VenueLeaderboardWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.height,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(31.0),
        boxShadow: [
          BoxShadow(
            offset: const Offset(-4, 5),
            color: Colors.black.withOpacity(0.25),
            spreadRadius: 0,
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getVenueLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No users found for leaderboard',
                style: TextStyle(color: widget.textColor),
              ),
            );
          }

          final leaderboardData = snapshot.data!;
          return _buildLeaderboard(leaderboardData);
        },
      ),
    );
  }

  Widget _buildLeaderboard(List<Map<String, dynamic>> users) {
    // Extract top 3 users for podium display
    final podiumUsers = users.length > 3 ? users.sublist(0, 3) : users;
    // Get remaining users for list view
    final listUsers = users.length > 3 ? users.sublist(3) : [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 20),
      child: Column(
        children: [
          // Podium section
          Builder(
            builder: (context) {
              final width = MediaQuery.of(context).size.width;
              final isMobile = width < 600;
              
              if (isMobile) {
                // Mobile view: Use card layout for all users
                return Column(
                  children: users.asMap().entries.map((entry) {
                    final index = entry.key;
                    final user = entry.value;
                    return _buildUserRankCard(user, index + 1);
                  }).toList(),
                );
              }

              // Desktop view: Use podium layout for top 3
              return _buildPodium(podiumUsers);
            },
          ),
          const SizedBox(height: 16),
          // Remaining users list (only for desktop)
          Builder(
            builder: (context) {
              final width = MediaQuery.of(context).size.width;
              final isMobile = width < 600;
              
              if (!isMobile) {
                return Column(
                  children: listUsers.asMap().entries.map((entry) {
                    final index = entry.key + 4; // Start from position 4
                    final user = entry.value;
                    return _buildUserRankCard(user, index);
                  }).toList(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> topUsers) {
    // Arrange users in podium order: 2nd place, 1st place, 3rd place
    final podiumArrangement = <int, Map<String, dynamic>>{};
    
    // Fill with available users (might be less than 3)
    for (int i = 0; i < topUsers.length; i++) {
      // Positions: 0 = 1st, 1 = 2nd, 2 = 3rd
      podiumArrangement[i] = topUsers[i];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place (left)
          if (podiumArrangement.containsKey(1))
            _buildPodiumPosition(
              podiumArrangement[1]!,
              2,
              120,
              const Color(0xFF6FA6A0),
            ),
          const SizedBox(width: 12),
          
          // 1st place (center, taller)
          if (podiumArrangement.containsKey(0))
            _buildPodiumPosition(
              podiumArrangement[0]!,
              1,
              150, 
              const Color(0xFFFFFFFF),
            ),
          const SizedBox(width: 12),
          
          // 3rd place (right)
          if (podiumArrangement.containsKey(2))
            _buildPodiumPosition(
              podiumArrangement[2]!,
              3,
              100,
              const Color(0xFFFFFFFF),
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumPosition(Map<String, dynamic> user, int position, double height, Color circleColor) {
    return Container(
      width: 120,
      height: height + 80, // Add space for text below
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            offset: const Offset(-4, 5),
            color: Colors.black.withOpacity(0.25),
            spreadRadius: 0,
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Profile image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: user['photo_url'] != null
                  ? CachedNetworkImage(
                      imageUrl: user['photo_url'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) {
                        print('Debug - Error loading image for user ${user['display_name']}: $error');
                        return Icon(Icons.person, color: widget.textColor, size: 40);
                      },
                    )
                  : Icon(Icons.person, color: widget.textColor, size: 40),
            ),
          ),
          const SizedBox(height: 12),
          // Name
          Text(
            user['display_name'] != null ? (user['display_name'] as String).split(' ').first : 'name',
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: widget.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          // High Score value
          Text(
            user['high_score']?.toString() ?? '0',
            style: const TextStyle(
              fontFamily: 'Roboto Flex',
              color: Color(0xFFFF8B64),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRankCard(Map<String, dynamic> user, int position) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 4, right: 4),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(31),
        boxShadow: [
          BoxShadow(
            offset: const Offset(-4, 5),
            color: Colors.black.withOpacity(0.25),
            spreadRadius: 0,
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Position number
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: Text(
              position.toString(),
              style: TextStyle(
                color: widget.textColor,
                fontFamily: 'Roboto Flex',
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // User details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Profile Image
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: user['photo_url'] != null
                              ? CachedNetworkImage(
                                  imageUrl: user['photo_url'],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.person, color: widget.textColor),
                                )
                              : Icon(Icons.person, color: widget.textColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name and Email
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['display_name'] ?? 'Unknown',
                              style: TextStyle(
                                color: widget.textColor,
                                fontFamily: 'Roboto Flex',
                                fontSize: 16.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              user['email'] ?? '',
                              style: TextStyle(
                                color: widget.textColor.withOpacity(0.7),
                                fontFamily: 'Roboto Flex',
                                fontSize: 12.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat('Visits', user['sessions'] ?? 0, const Color(0xFF6FA6A0)),
                      _buildStat('Coins', user['coins'] ?? 0, const Color(0xFFFF8B64)),
                      _buildStat('High Score', user['high_score'] ?? 0, const Color(0xFFC5C352)),
                      _buildStat('Redeemed', user['redeemed'] ?? 0, const Color(0xFFFF6464)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: widget.textColor,
            fontFamily: 'Roboto Flex',
            fontSize: 12.0,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2B2B),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value.toString().padLeft(3, '0'),
            style: TextStyle(
              color: valueColor,
              fontFamily: 'Roboto Flex',
              fontSize: 12.0,
            ),
          ),
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _getVenueLeaderboard() async {
    try {
      print('Fetching leaderboard for venue: [33m${widget.venueId}[0m');

      // Query userVenueProgress for this venue
      final usersQuery = await FirebaseFirestore.instance
          .collection('userVenueProgress')
          .where('venueId', isEqualTo: widget.venueId)
          .get();

      print('Found [36m${usersQuery.docs.length}[0m userVenueProgress entries for venue ${widget.venueId}');

      // Aggregate by userId and only include users with a non-empty email
      Map<String, Map<String, dynamic>> userStats = {};
      for (var doc in usersQuery.docs) {
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
            'redeemed': 0,
            'createdTime': data['createdTime'],
          };
          print('Debug - User data from Firestore for ${userStats[userId]!['display_name']}:');
          print('  photo_url: ${userStats[userId]!['photo_url']}');
          print('  Raw data photo_url: ${data['photo_url']}');
          print('  Raw data photoUrl: ${data['photoUrl']}');
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
        if (data['highScore'] != null && data['highScore'] is int) {
          highScore = data['highScore'] as int;
        } else if (data['high_score'] != null && data['high_score'] is int) highScore = data['high_score'] as int;
        if (highScore > (userStats[userId]!['high_score'] as int)) {
          userStats[userId]!['high_score'] = highScore;
        }
        // Sum redeemed
        userStats[userId]!['redeemed'] = (userStats[userId]!['redeemed'] as int) + (data['redeemed'] is int ? data['redeemed'] as int : (data['redeemed'] is num ? (data['redeemed'] as num).toInt() : 0));
      }

      // Convert to list
      List<Map<String, dynamic>> leaderboardUsers = userStats.values.toList();
      // Sort by high_score in descending order
      leaderboardUsers.sort((a, b) => (b['high_score'] as int).compareTo(a['high_score'] as int));
      return leaderboardUsers;
    } catch (e) {
      print('Error getting venue leaderboard: $e');
      return [];
    }
  }
} 