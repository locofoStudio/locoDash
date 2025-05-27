import 'package:flutter/material.dart';

class OffersCard extends StatelessWidget {
  final String offerName;
  final String offerDescription;
  final String coinValue;
  final String? imageUrl;
  final VoidCallback? onEdit;

  const OffersCard({
    Key? key,
    required this.offerName,
    required this.offerDescription,
    required this.coinValue,
    this.imageUrl,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final width = isMobile ? 360.0 : 488.0;

    return Container(
      width: width,
      height: 108,
      decoration: BoxDecoration(
        color: const Color(0xFF363740),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFF525E5D),
        ),
      ),
      child: Row(
        children: [
          // Image container
          Container(
            width: 84,
            height: 84,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDCDCDC),
              borderRadius: BorderRadius.circular(9),
            ),
            child: imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Info section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offerName,
                    style: const TextStyle(
                      color: Color(0xFFDCDCDC),
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    offerDescription,
                    style: const TextStyle(
                      color: Color(0xFFDCDCDC),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Coins section
              Row(
                children: [
                  const Text(
                    'Coins:',
                    style: TextStyle(
                      color: Color(0xFFDCDCDC),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    coinValue,
                    style: const TextStyle(
                      color: Color(0xFFE86526),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Edit button
          Container(
            width: 70,
            height: 42,
            margin: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF363740),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFDCDCDC),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.yellow.withOpacity(0.7),
                  offset: const Offset(0, 0),
                  blurRadius: 0,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 