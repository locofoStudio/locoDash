import 'package:flutter/material.dart';

class DashboardCardContainer extends StatelessWidget {
  final Widget child;
  const DashboardCardContainer({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 33, vertical: 33),
      decoration: BoxDecoration(
        color: const Color(0xFF363740),
        borderRadius: BorderRadius.circular(31),
      ),
      child: child,
    );
  }
} 