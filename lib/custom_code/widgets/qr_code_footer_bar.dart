import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';

class QrCodeFooterBar extends StatelessWidget {
  final String userId;
  final String venueId;
  final String action;
  final Color backgroundColor;
  final Color accentColor;
  final Color iconColor;
  final Color textColor;
  final VoidCallback? onQrTap;

  const QrCodeFooterBar({
    Key? key,
    required this.userId,
    required this.venueId,
    this.action = 'loyalty_redeem',
    this.backgroundColor = const Color(0xFF242529),
    this.accentColor = const Color(0xFFC5C352),
    this.iconColor = const Color(0xFF363740),
    this.textColor = Colors.black,
    this.onQrTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 89,
      color: backgroundColor,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Footer bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 53,
              color: accentColor,
            ),
          ),
          // Notch container
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: onQrTap,
              child: Container(
                width: 63,
                height: 88,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(9),
                    topRight: Radius.circular(9),
                  ),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.qr_code,
                      size: 30,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 