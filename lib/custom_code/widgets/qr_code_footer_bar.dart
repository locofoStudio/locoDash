import 'package:flutter/material.dart';
import 'qr_code_scanner_widget.dart';

class QrCodeFooterBar extends StatelessWidget {
  final String venueId;

  const QrCodeFooterBar({
    Key? key,
    required this.venueId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 66,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Outer transparent container
          Container(
            width: double.infinity,
            height: 66,
            color: Colors.transparent,
          ),
          // Bottom bar (bottom aligned, new color)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: double.infinity,
              height: 45,
              color: const Color(0xFFC5C352), // New color
            ),
          ),
          // QR code notch (bottom center aligned, new color)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () => _launchScanner(context),
                child: Container(
                  width: 75,
                  height: 66,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC5C352), // New color
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(9),
                      topRight: Radius.circular(9),
                    ),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.qr_code,
                        size: 40,
                        color: Color(0xFF363740), // QR code icon color
                      ),
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

  void _launchScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrCodeScannerWidget(
          venueId: venueId,
          onScanComplete: (success, message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: success ? Colors.green : Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          },
        ),
      ),
    );
  }
} 