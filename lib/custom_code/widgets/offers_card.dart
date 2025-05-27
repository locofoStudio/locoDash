import 'package:flutter/material.dart';

class OffersCard extends StatelessWidget {
  final String offerName;
  final String offerDescription;
  final String coinValue;
  final String? imageUrl;
  final VoidCallback? onEdit;

  const OffersCard({
    super.key,
    required this.offerName,
    required this.offerDescription,
    required this.coinValue,
    this.imageUrl,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final width = isMobile ? 360.0 : 488.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF363740),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFF525E5D),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
          const SizedBox(width: 6),
          // Info section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Column(
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
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        offerDescription,
                        style: const TextStyle(
                          color: Color(0xFFDCDCDC),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Coins section
                  Row(
                    children: [
                      const Text(
                        'Coins:',
                        style: TextStyle(
                          color: Color(0xFFDCDCDC),
                          fontSize: 14,
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
            ),
          ),
          // Edit button
          Container(
            width: 50,
            height: 42,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF363740),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFDCDCDC),
                width: 1,
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
                  fontSize: 12,
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