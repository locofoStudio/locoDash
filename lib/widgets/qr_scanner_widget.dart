import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerWidget extends StatefulWidget {
  final Function(String) onQRCodeDetected;
  final bool isScanning;

  const QRScannerWidget({
    Key? key,
    required this.onQRCodeDetected,
    this.isScanning = true,
  }) : super(key: key);

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  late MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            MobileScanner(
              controller: controller,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    widget.onQRCodeDetected(barcode.rawValue!);
                  }
                }
              },
            ),
            if (!widget.isScanning)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Text(
                    'Scanner Paused',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: ValueListenableBuilder(
                  valueListenable: controller.torchState,
                  builder: (context, state, child) {
                    switch (state) {
                      case TorchState.off:
                        return const Icon(Icons.flash_off, color: Colors.white);
                      case TorchState.on:
                        return const Icon(Icons.flash_on, color: Colors.white);
                    }
                  },
                ),
                onPressed: () => controller.toggleTorch(),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 