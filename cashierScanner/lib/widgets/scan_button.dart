import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'full_screen_scanner_overlay.dart';

class ScanButton extends StatelessWidget {
  final Function(String) onScan;
  final bool isLoading;

  const ScanButton({
    super.key,
    required this.onScan,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLoading 
              ? [Colors.grey.shade400, Colors.grey.shade600]
              : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isLoading ? Colors.grey : const Color(0xFF6366F1)).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : () => _startScan(context),
          borderRadius: BorderRadius.circular(140),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Processing...',
                    style: GoogleFonts.robotoFlex(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.qr_code_scanner,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'TAP TO SCAN',
                    style: GoogleFonts.robotoFlex(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customer QR Code',
                    style: GoogleFonts.robotoFlex(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startScan(BuildContext context) async {
    try {
      final result = await showGeneralDialog<String>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Close QR Scanner',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const FullScreenScannerOverlay(),
        transitionBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOut))
              .animate(anim),
          child: child,
        ),
      );

      if (result != null && result.isNotEmpty) {
        print('=== CASHIER SCANNER QR DETECTED ===');
        print('QR Code: $result');
        onScan(result);
      }
    } catch (e) {
      print('Error starting scanner: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start scanner: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
