import 'package:flutter/material.dart';

class ItemCreationWidget extends StatefulWidget {
  const ItemCreationWidget({super.key});

  @override
  State<ItemCreationWidget> createState() => _ItemCreationWidgetState();
}

class _ItemCreationWidgetState extends State<ItemCreationWidget> {
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _suggestedCoinPriceController = TextEditingController();
  final TextEditingController _itemDescriptionController = TextEditingController();
  final String _selectedCategory = 'Baked';

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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
        ],
      ),
    );
  }
} 