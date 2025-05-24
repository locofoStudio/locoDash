import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fl_chart/fl_chart.dart'; // Uncomment if using charts
// import your AppCard, AppText, AppColors here

class LoyaltyStatsWidget extends StatelessWidget {
  final String venueId;
  const LoyaltyStatsWidget({Key? key, required this.venueId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopPlayersCard(venueId: venueId),
        const SizedBox(height: 20),
        _EngagementHeatmapCard(venueId: venueId),
        const SizedBox(height: 20),
        _RewardTrendsCard(venueId: venueId),
      ],
    );
  }
}

// 1. Top Players Leaderboard
class TopPlayersCard extends StatelessWidget {
  final String venueId;
  const TopPlayersCard({Key? key, required this.venueId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF363A40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(32.0, 32.0, 32.0, 32.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('userVenueProgress')
              .where('venueId', isEqualTo: venueId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Text('No players found', style: TextStyle(color: Colors.white70));
            }
            // Aggregate highScore per user
            final Map<String, Map<String, dynamic>> userStats = {};
            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final userId = data['userId'] ?? doc.id;
              // Ensure userStats[userId] is initialized
              Map<String, dynamic> user = userStats[userId] ?? {
                'highScore': 0,
                'name': data['displayName'] ?? 'User',
                'photoUrl': data['photoUrl'] ?? '',
              };
              int highScore = 0;
              if (data['highScore'] != null) highScore = int.tryParse(data['highScore'].toString()) ?? 0;
              if (highScore > (user['highScore'] as int)) {
                user['highScore'] = highScore;
              }
              userStats[userId] = user;
            }
            // Sort by highScore
            final topUsers = userStats.entries.toList()
              ..sort((a, b) => (b.value['highScore'] as int).compareTo(a.value['highScore'] as int));
            final podium = topUsers.take(3).toList();
            // Podium colors and sizes
            final List<Color> podiumColors = [
              const Color(0xFFC5C352), // 1st - gold
              const Color(0xFFBF9BF2), // 2nd - purple
              const Color(0xFF6FA6A0), // 3rd - teal
            ];
            final List<double> avatarSizes = [72, 56, 40];
            final List<double> cardHeights = [240, 180, 160];
            final List<double> cardWidths = [140, 120, 120];
            // Center 1st, left 2nd, right 3rd
            Widget buildPodiumUser(int place, Map<String, dynamic> user, Color color, double avatarSize, double cardHeight, double cardWidth) {
              return Container(
                width: cardWidth,
                height: cardHeight,
                margin: EdgeInsets.only(
                  top: place == 0 ? 0 : (place == 1 ? 40 : 40),
                  left: place == 1 ? 0 : 8,
                  right: place == 2 ? 0 : 8,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: avatarSize / 2,
                      backgroundColor: Colors.white,
                      backgroundImage: ((user?['photoUrl'] ?? '') as String).isNotEmpty ? NetworkImage(user?['photoUrl'] ?? '') : null,
                      child: ((user?['photoUrl'] ?? '') as String).isEmpty
                          ? Icon(Icons.person, color: color.withOpacity(0.5), size: avatarSize / 2)
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (user?['name'] ?? 'User') as String,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      (user['highScore'] ?? 0).toString(),
                      style: const TextStyle(
                        color: Color(0xFFE76527),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (place + 1).toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Top Players', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (podium.length > 1)
                      buildPodiumUser(1, podium.length > 1 ? podium[1].value : {}, podiumColors[1], avatarSizes[1], cardHeights[1], cardWidths[1]),
                    if (podium.isNotEmpty)
                      buildPodiumUser(0, podium[0].value, podiumColors[0], avatarSizes[0], cardHeights[0], cardWidths[0]),
                    if (podium.length > 2)
                      buildPodiumUser(2, podium.length > 2 ? podium[2].value : {}, podiumColors[2], avatarSizes[2], cardHeights[2], cardWidths[2]),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// 2. Engagement Heatmap
class _EngagementHeatmapCard extends StatelessWidget {
  final String venueId;
  const _EngagementHeatmapCard({required this.venueId});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      color: const Color(0xFF363A40),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(32.0, 32.0, 32.0, 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Engagement Heatmap', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: 180,
              color: const Color(0xFF23262B),
              child: const Center(child: Text('Heatmap goes here', style: TextStyle(color: Colors.white54))),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. Reward Redemption Trends
class _RewardTrendsCard extends StatelessWidget {
  final String venueId;
  const _RewardTrendsCard({required this.venueId});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      color: const Color(0xFF363A40),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(32.0, 32.0, 32.0, 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reward Redemption Trends', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: 180,
              color: const Color(0xFF23262B),
              child: const Center(child: Text('Bar chart goes here', style: TextStyle(color: Colors.white54))),
            ),
          ],
        ),
      ),
    );
  }
} 