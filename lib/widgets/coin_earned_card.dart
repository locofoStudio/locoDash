import 'package:flutter/material.dart';
import 'dashboard_card_container.dart';
import 'users_card.dart' show Metric;

class CoinEarnedCard extends StatelessWidget {
  const CoinEarnedCard({super.key, required this.venueId});

  final String venueId;

  @override
  Widget build(BuildContext context) {
    return DashboardCardContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 33, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Coin earned',
              style: TextStyle(
                fontFamily: 'Roboto Flex',
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Metric(label: 'Month', value: '568', valueColor: Color(0xFFC5C352)),
                const SizedBox(width: 40),
                Metric(label: 'Week', value: '100', valueColor: Color(0xFFBF9BF2)),
                const SizedBox(width: 40),
                Metric(label: 'Today', value: '008', valueColor: Color(0xFF6FA6A0)),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 