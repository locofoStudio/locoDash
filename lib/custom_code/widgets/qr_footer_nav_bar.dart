import 'package:flutter/material.dart';

class QrFooterNavBar extends StatelessWidget {
  final VoidCallback onTap;
  const QrFooterNavBar({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      width: double.infinity,
      color: const Color(0xFFC5C352),
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: QrCodeIcon(
            size: 40,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class QrCodeIcon extends StatelessWidget {
  final double size;
  final Color color;
  const QrCodeIcon({Key? key, this.size = 40, this.color = Colors.black}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _QrCodePainter(color: color),
      size: Size(size, size),
    );
  }
}

class _QrCodePainter extends CustomPainter {
  final Color color;
  _QrCodePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    // Draw border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ),
      borderPaint,
    );
    // Draw QR code squares (simplified)
    final squarePaint = Paint()..color = color;
    double s = size.width / 8;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if ((i == 0 || i == 2) && (j == 0 || j == 2)) {
          canvas.drawRect(Rect.fromLTWH(i * s, j * s, s, s), squarePaint);
        }
      }
    }
    // Center dot
    canvas.drawRect(Rect.fromLTWH(3.5 * s, 3.5 * s, s, s), squarePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 