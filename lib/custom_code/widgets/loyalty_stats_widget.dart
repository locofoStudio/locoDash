import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fl_chart/fl_chart.dart'; // Uncomment if using charts
// import your AppCard, AppText, AppColors here

class LoyaltyStatsWidget extends StatelessWidget {
  final String venueId;
  const LoyaltyStatsWidget({super.key, required this.venueId});

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
  const TopPlayersCard({super.key, required this.venueId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF363740),
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
              'high_score': 0,
              'display_name': data['displayName'] ?? 'User',
              'photo_url': data['photoUrl'] ?? '',
            };
            int highScore = 0;
            if (data['highScore'] != null) highScore = int.tryParse(data['highScore'].toString()) ?? 0;
            if (highScore > (user['high_score'] as int)) {
              user['high_score'] = highScore;
            }
            userStats[userId] = user;
          }

          // Sort by highScore
          final topUsers = userStats.entries.toList()
            ..sort((a, b) => (b.value['high_score'] as int).compareTo(a.value['high_score'] as int));
          final podium = topUsers.take(3).map((e) => e.value).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top Players',
                style: TextStyle(
                  fontFamily: 'Roboto Flex',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Builder(
                builder: (context) {
                  final width = MediaQuery.of(context).size.width;
                  final isMobile = width < 600;
                  
                  if (isMobile) {
                    // Mobile view: Use card layout
                    return Column(
                      children: podium.asMap().entries.map((entry) {
                        final index = entry.key;
                        final user = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF363740),
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
                                  (index + 1).toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
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
                                                  ? Image.network(
                                                      user['photo_url'],
                                                      fit: BoxFit.cover,
                                                      loadingBuilder: (context, child, loadingProgress) {
                                                        if (loadingProgress == null) return child;
                                                        return const CircularProgressIndicator();
                                                      },
                                                      errorBuilder: (context, error, stackTrace) =>
                                                          const Icon(Icons.person, color: Colors.white, size: 40),
                                                    )
                                                  : const Icon(Icons.person, color: Colors.white, size: 40),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Name
                                          Expanded(
                                            child: Text(
                                              user['display_name'] ?? 'Unknown',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Roboto Flex',
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Stats Row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildStat('High Score', user['high_score'] ?? 0, const Color(0xFFC5C352)),
                                          _buildStat('Visits', user['sessions'] ?? 0, const Color(0xFF6FA6A0)),
                                          _buildStat('Coins', user['coins'] ?? 0, const Color(0xFFFF8B64)),
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
                      }).toList(),
                    );
                  }

                  // Desktop view: Use podium layout
                  final children = <Widget>[
                    if (podium.length > 1)
                      Expanded(child: _buildPodiumPosition(podium[1], 2, 120, const Color(0xFF6FA6A0))),
                    if (podium.length > 1) const SizedBox(width: 12),
                    if (podium.isNotEmpty)
                      Expanded(child: _buildPodiumPosition(podium[0], 1, 150, const Color(0xFFFFFFFF))),
                    if (podium.length > 2) const SizedBox(width: 12),
                    if (podium.length > 2)
                      Expanded(child: _buildPodiumPosition(podium[2], 3, 100, const Color(0xFFFFFFFF))),
                  ];
                  return SizedBox(
                    height: 230,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: children,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPodiumPosition(Map<String, dynamic> user, int position, double height, Color circleColor) {
    return Container(
      width: 120,
      height: height + 80, // Add space for text below
      decoration: BoxDecoration(
        color: const Color(0xFF363740),
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: user['photo_url'] != null
                  ? Image.network(
                      user['photo_url'],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const CircularProgressIndicator();
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, color: Colors.white, size: 40),
                    )
                  : const Icon(Icons.person, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 12),
          // Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              user['display_name'] != null ? (user['display_name'] as String).split(' ').first : 'name',
              style: const TextStyle(
                fontFamily: 'Roboto Flex',
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          // High Score value
          Text(
            user['high_score']?.toString() ?? '0',
            style: const TextStyle(
              fontFamily: 'Roboto Flex',
              color: Color(0xFFFF8B64),
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
          style: const TextStyle(
            color: Colors.white,
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
            const Text(
              'Engagement Heatmap',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
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
            const Text(
              'Reward Redemption Trends',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
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