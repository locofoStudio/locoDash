import 'package:flutter/material.dart';

class UsersCard extends StatelessWidget {
  const UsersCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF363740),
        borderRadius: BorderRadius.circular(31),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 33, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Users',
              style: TextStyle(
                fontFamily: 'Roboto Flex',
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Metric(label: 'Monthly Users', value: '568', valueColor: Color(0xFFC5C352)),
                    SizedBox(height: 11),
                    Metric(label: 'Week', value: '154', valueColor: Color(0xFFBF9BF2)),
                  ],
                ),
                const SizedBox(width: 40),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Metric(label: 'Live', value: '008', valueColor: Color(0xFF6FA6A0)),
                    SizedBox(height: 11),
                    Metric(label: 'Total', value: '008', valueColor: Color(0xFFF87C58)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const Metric({super.key, required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 89,
          height: 16,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto Flex',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        SizedBox(
          width: 41,
          height: 28,
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: valueColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
} 