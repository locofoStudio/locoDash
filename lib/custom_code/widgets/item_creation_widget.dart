import 'package:flutter/material.dart';

class ItemCreationWidget extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final VoidCallback? onCancel;
  const ItemCreationWidget({Key? key, this.initialData, this.onCancel}) : super(key: key);

  @override
  State<ItemCreationWidget> createState() => _ItemCreationWidgetState();
}

class _ItemCreationWidgetState extends State<ItemCreationWidget> {
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _suggestedCoinPriceController = TextEditingController();
  final TextEditingController _itemDescriptionController = TextEditingController();
  String _selectedCategory = 'Baked';

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _itemNameController.text = widget.initialData!['name'] ?? '';
      _originalPriceController.text = widget.initialData!['originalPrice']?.toString() ?? '';
      _suggestedCoinPriceController.text = widget.initialData!['coins']?.toString() ?? '';
      _itemDescriptionController.text = widget.initialData!['description'] ?? '';
      _selectedCategory = widget.initialData!['category'] ?? 'Baked';
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _originalPriceController.dispose();
    _suggestedCoinPriceController.dispose();
    _itemDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final width = isMobile ? 323.0 : 453.0;

    return Container(
      width: width,
      padding: const EdgeInsets.all(40.5),
      decoration: BoxDecoration(
        color: const Color(0xFF363C40),
        borderRadius: BorderRadius.circular(31),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Item',
                style: TextStyle(
                  color: Color(0xFFFCFDFF),
                  fontSize: 20,
                ),
              ),
              PopupMenuButton<String>(
                offset: const Offset(0, 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: const Color(0xFF0F2533),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'Baked',
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD9D9D9),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Baked',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Demo',
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD9D9D9),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Demo',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFFCFDFF)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCategory,
                        style: const TextStyle(
                          color: Color(0xFFFCFDFF),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFFDCDCDC),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _itemNameController,
            style: const TextStyle(color: Color(0xFFDCDCDC)),
            decoration: InputDecoration(
              hintText: 'Item Name',
              hintStyle: const TextStyle(color: Color(0xFFDCDCDC)),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFF525E5D)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFF525E5D)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFF525E5D)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _originalPriceController,
                      style: const TextStyle(color: Color(0xFFDCDCDC)),
                      decoration: InputDecoration(
                        hintText: 'Original Price',
                        hintStyle: const TextStyle(color: Color(0xFFDCDCDC)),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: const BorderSide(color: Color(0xFF525E5D)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: const BorderSide(color: Color(0xFF525E5D)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: const BorderSide(color: Color(0xFF525E5D)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _suggestedCoinPriceController,
                      style: const TextStyle(color: Color(0xFFC5C352)),
                      decoration: InputDecoration(
                        hintText: 'suggested coin price',
                        hintStyle: const TextStyle(color: Color(0xFFC5C352)),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: const BorderSide(color: Color(0xFF525E5D)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: const BorderSide(color: Color(0xFF525E5D)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: const BorderSide(color: Color(0xFF525E5D)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _itemDescriptionController,
            maxLines: 5,
            style: const TextStyle(color: Color(0xFFDCDCDC)),
            decoration: InputDecoration(
              hintText: 'Item Description',
              hintStyle: const TextStyle(color: Color(0xFFDCDCDC)),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFF525E5D)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFF525E5D)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFF525E5D)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Attachment Icon
              Container(
                width: 22,
                height: 23,
                child: CustomPaint(
                  painter: AttachmentIconPainter(),
                ),
              ),
              // Add Item Button
              Container(
                width: 113,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFE86526),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      offset: Offset(-2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: () {
                    // TODO: Implement add item functionality
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Add item',
                    style: TextStyle(
                      color: Color(0xFFB8C5CD),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (widget.onCancel != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom painter for the attachment icon
class AttachmentIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFCFDFF)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(5.98032, 23)
      ..cubicTo(4.50459, 23, 3.12244, 22.3487, 2.12492, 21.3102)
      ..cubicTo(0.190371, 19.2965, -0.348335, 15.7818, 2.36346, 12.9596)
      ..lineTo(13.4891, 1.37717)
      ..cubicTo(14.6167, 0.203676, 16.0514, -0.250467, 17.4244, 0.133267)
      ..cubicTo(18.7746, 0.508785, 19.8794, 1.65998, 20.2412, 3.06466)
      ..cubicTo(20.6087, 4.49632, 20.1739, 5.99018, 19.0474, 7.16368)
      ..lineTo(8.40678, 18.2415)
      ..cubicTo(7.7996, 18.874, 7.11252, 19.2483, 6.42316, 19.3234)
      ..cubicTo(5.7395, 19.3985, 5.0878, 19.1709, 4.63127, 18.6956)
      ..cubicTo(3.80495, 17.8319, 3.68625, 16.2113, 5.06269, 14.7797)
      ..lineTo(12.5361, 6.99939)
      ..cubicTo(12.8431, 6.6802, 13.3407, 6.6802, 13.6478, 6.99939)
      ..cubicTo(13.9548, 7.31858, 13.9548, 7.83726, 13.6478, 8.15646)
      ..lineTo(6.1732, 15.9379)
      ..cubicTo(5.52721, 16.6091, 5.46787, 17.251, 5.74292, 17.5386)
      ..cubicTo(5.86391, 17.6629, 6.04652, 17.7204, 6.25766, 17.6958)
      ..cubicTo(6.58066, 17.6618, 6.94931, 17.4423, 7.29513, 17.0844)
      ..lineTo(17.9357, 6.00779)
      ..cubicTo(18.6662, 5.24736, 18.9458, 4.35316, 18.7232, 3.49064)
      ..cubicTo(18.612, 3.06886, 18.3966, 2.68377, 18.0981, 2.3727)
      ..cubicTo(17.7996, 2.06164, 17.4279, 1.83513, 17.0192, 1.71514)
      ..cubicTo(16.1906, 1.48396, 15.3301, 1.77616, 14.5996, 2.53659)
      ..lineTo(3.47397, 14.119)
      ..cubicTo(1.40132, 16.277, 1.8978, 18.7613, 3.23543, 20.1543)
      ..cubicTo(4.57421, 21.5472, 6.95844, 22.0659, 9.03223, 19.9055)
      ..lineTo(20.1579, 8.32309)
      ..cubicTo(20.2304, 8.24723, 20.3169, 8.18698, 20.4124, 8.14586)
      ..cubicTo(20.5078, 8.10473, 20.6102, 8.08355, 20.7137, 8.08355)
      ..cubicTo(20.8172, 8.08355, 20.9196, 8.10473, 21.015, 8.14586)
      ..cubicTo(21.1105, 8.18698, 21.197, 8.24723, 21.2695, 8.32309)
      ..cubicTo(21.4172, 8.47759, 21.5, 8.68557, 21.5, 8.90221)
      ..cubicTo(21.5, 9.11885, 21.4172, 9.32683, 21.2695, 9.48133)
      ..lineTo(10.1439, 21.0637)
      ..cubicTo(8.8325, 22.4273, 7.36361, 23, 5.98032, 23)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 