import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OffersTrackerWidget extends StatelessWidget {
  final String venueId;
  final bool showPreviewData;

  const OffersTrackerWidget({
    super.key,
    required this.venueId,
    this.showPreviewData = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF363740),
        borderRadius: BorderRadius.circular(31.0),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Offers Tracker',
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 22),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('offers')
                .where('venueId', isEqualTo: venueId)
                .snapshots(),
            builder: (context, offersSnapshot) {
              if (offersSnapshot.hasError) {
                return _buildMetricRow(
                  'Active Offers',
                  '0',
                  const Color(0xFFC5C352),
                  'Total Value',
                  '\$0.00',
                  const Color(0xFFF87C58),
                );
              }

              final offers = offersSnapshot.data?.docs ?? [];
              final activeOffersCount = offers.length;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('offer_redemptions')
                    .where('venueId', isEqualTo: venueId)
                    .snapshots(),
                builder: (context, redemptionsSnapshot) {
                  if (redemptionsSnapshot.hasError) {
                    return _buildMetricRow(
                      'Active Offers',
                      activeOffersCount.toString(),
                      const Color(0xFFC5C352),
                      'Total Value',
                      '\$0.00',
                      const Color(0xFFF87C58),
                    );
                  }

                  final redemptions = redemptionsSnapshot.data?.docs ?? [];
                  final totalValue = redemptions.fold<double>(
                    0,
                    (sum, doc) {
                      try {
                        final originalPrice = doc.get('originalPrice');
                        return sum + (originalPrice is num ? originalPrice : 0);
                      } catch (e) {
                        return sum;
                      }
                    },
                  );

                  final todayRedemptions = redemptions.where((doc) {
                    try {
                      final redeemedAt = doc.get('redeemedAt');
                      if (redeemedAt == null || !(redeemedAt is Timestamp)) return false;
                      return redeemedAt.toDate().day == DateTime.now().day;
                    } catch (e) {
                      return false;
                    }
                  }).length;

                  final weekRedemptions = redemptions.where((doc) {
                    try {
                      final redeemedAt = doc.get('redeemedAt');
                      if (redeemedAt == null || !(redeemedAt is Timestamp)) return false;
                      return redeemedAt.toDate().isAfter(DateTime.now().subtract(const Duration(days: 7)));
                    } catch (e) {
                      return false;
                    }
                  }).length;

                  return Column(
                    children: [
                      _buildMetricRow(
                        'Active Offers',
                        activeOffersCount.toString(),
                        const Color(0xFFC5C352),
                        'Total Value',
                        '\$${totalValue.toStringAsFixed(2)}',
                        const Color(0xFFF87C58),
                      ),
                      const SizedBox(height: 20),
                      _buildMetricRow(
                        'Redeemed Today',
                        todayRedemptions.toString(),
                        const Color(0xFF6FA6A0),
                        'This Week',
                        weekRedemptions.toString(),
                        const Color(0xFFBF9BF2),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String leftLabel, String leftValue, Color leftValueColor, String rightLabel, String rightValue, Color rightValueColor) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                leftLabel,
                style: const TextStyle(
                  fontFamily: 'Roboto Flex',
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              Text(
                leftValue,
                style: TextStyle(
                  fontFamily: 'Roboto Flex',
                  color: leftValueColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rightLabel,
                style: const TextStyle(
                  fontFamily: 'Roboto Flex',
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              Text(
                rightValue,
                style: TextStyle(
                  fontFamily: 'Roboto Flex',
                  color: rightValueColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 