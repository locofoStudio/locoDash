// lib/custom_code/widgets/top_reward_widget.dart
// This widget displays the venue's top reward (offer with most redeems) and related metrics.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TopRewardWidget extends StatefulWidget {
  const TopRewardWidget({
    super.key,
    required this.venueId,
    this.coinValue = 0.10,
    this.backgroundColor = const Color(0xFF363740),
    this.textColor = Colors.white,
    this.rewardColor = const Color(0xFFC5C352),
    this.ordersColor = const Color(0xFFBF9BF2),
    this.spendColor = const Color(0xFFF87C58),
  });

  final String venueId;
  final double coinValue;
  final Color backgroundColor;
  final Color textColor;
  final Color rewardColor;
  final Color ordersColor;
  final Color spendColor;

  @override
  State<TopRewardWidget> createState() => _TopRewardWidgetState();
}

class _TopRewardWidgetState extends State<TopRewardWidget> {
  late Future<_TopRewardData?> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = _fetchTopReward();
  }

  @override
  void didUpdateWidget(covariant TopRewardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.venueId != widget.venueId) {
      _futureData = _fetchTopReward();
    }
  }

  Future<_TopRewardData?> _fetchTopReward() async {
    if (widget.venueId.isEmpty) return null;

    try {
      final offersQuery = await FirebaseFirestore.instance
          .collection('offers')
          .where('venueId', isEqualTo: widget.venueId)
          .get();

      _TopRewardData? topReward;

      for (var doc in offersQuery.docs) {
        final data = doc.data();
        final List redeemedUsers = data['redeemedUsers'] is List
            ? data['redeemedUsers'] as List
            : [];
        final int redeemedCount = redeemedUsers.length;
        final String offerName = data['OfferName']?.toString() ?? 'Unknown';
        final double price = (data['OfferPrice'] is num)
            ? (data['OfferPrice'] as num).toDouble()
            : 0.0;

        if (topReward == null || redeemedCount > topReward.redeemedCount) {
          topReward = _TopRewardData(
            offerName: offerName,
            redeemedCount: redeemedCount,
            offerPrice: price,
          );
        }
      }

      return topReward;
    } catch (e) {
      debugPrint('Error fetching top reward: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(31.0),
      ),
      padding: const EdgeInsets.all(32),
      child: FutureBuilder<_TopRewardData?>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null) {
            return Text(
              'No rewards data',
              style: TextStyle(color: widget.textColor),
            );
          }

          final double totalSpend =
              data.redeemedCount * data.offerPrice * widget.coinValue;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top rewards',
                style: TextStyle(
                  fontFamily: 'Roboto Flex',
                  color: widget.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reward',
                          style: TextStyle(
                            fontFamily: 'Roboto Flex',
                            color: widget.textColor,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          data.offerName,
                          style: TextStyle(
                            fontFamily: 'Roboto Flex',
                            color: widget.rewardColor,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildMetricRow(
                label1: 'Total orders / month',
                value1: data.redeemedCount.toString(),
                color1: widget.ordersColor,
                label2: 'Total Spend',
                value2: '\$${totalSpend.toStringAsFixed(0)}',
                color2: widget.spendColor,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricRow({
    required String label1,
    required String value1,
    required Color color1,
    required String label2,
    required String value2,
    required Color color2,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label1,
                style: TextStyle(
                  fontFamily: 'Roboto Flex',
                  color: widget.textColor,
                  fontSize: 14,
                ),
              ),
              Text(
                value1,
                style: TextStyle(
                  fontFamily: 'Roboto Flex',
                  color: color1,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label2,
                style: TextStyle(
                  fontFamily: 'Roboto Flex',
                  color: widget.textColor,
                  fontSize: 14,
                ),
              ),
              Text(
                value2,
                style: TextStyle(
                  fontFamily: 'Roboto Flex',
                  color: color2,
                  fontSize: 24,
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

class _TopRewardData {
  _TopRewardData({
    required this.offerName,
    required this.redeemedCount,
    required this.offerPrice,
  });

  final String offerName;
  final int redeemedCount;
  final double offerPrice;
} 