// lib/custom_code/widgets/top_reward_widget.dart
// This widget displays the venue's top reward (offer with most redeems) and related metrics.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TopRewardWidget extends StatefulWidget {
  const TopRewardWidget({
    super.key,
    required this.venueId,
    this.coinValue = 0.08,
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
  StreamSubscription? _subscription;
  _TopRewardData? _topRewardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _subscribeToTopReward();
  }

  @override
  void didUpdateWidget(covariant TopRewardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.venueId != widget.venueId) {
      _subscribeToTopReward();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribeToTopReward() {
    _subscription?.cancel();
    setState(() => _isLoading = true);

    if (widget.venueId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    // Combined stream of users and offers
    final usersStream = FirebaseFirestore.instance
        .collection('userVenueProgress')
        .where('venueId', isEqualTo: widget.venueId)
        .snapshots();

    _subscription = usersStream.listen((usersSnapshot) async {
      final offerStats = <String, ({int count, double price})>{};

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        if (userData['offers'] is List) {
          final userOffers = userData['offers'] as List;
          for (var offerData in userOffers) {
            if (offerData is Map<String, dynamic>) {
              final name = offerData['name'] as String?;
              final price = (offerData['price'] as num?)?.toDouble() ?? 0.0;
              if (name != null) {
                final current = offerStats[name] ?? (count: 0, price: price);
                offerStats[name] = (count: current.count + 1, price: current.price);
              }
            }
          }
        }
      }

      if (offerStats.isEmpty) {
        if (mounted) {
          setState(() {
            _topRewardData = null;
            _isLoading = false;
          });
        }
        return;
      }

      final topOfferEntry = offerStats.entries.reduce((a, b) => a.value.count > b.value.count ? a : b);
      
      if (mounted) {
        setState(() {
          _topRewardData = _TopRewardData(
            offerName: topOfferEntry.key,
            redeemedCount: topOfferEntry.value.count,
            offerPrice: topOfferEntry.value.price,
          );
          _isLoading = false;
        });
      }
    }, onError: (e) {
      debugPrint('Error fetching top reward: $e');
      if (mounted) setState(() => _isLoading = false);
    });
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
      child: Builder(
        builder: (context) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = _topRewardData;
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