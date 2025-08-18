import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class CoinInputWidget extends StatefulWidget {
  final Function(double) onAmountChanged;
  final int calculatedCoins;
  final VoidCallback onAwardCoins;
  final bool isLoading;

  const CoinInputWidget({
    super.key,
    required this.onAmountChanged,
    required this.calculatedCoins,
    required this.onAwardCoins,
    this.isLoading = false,
  });

  @override
  State<CoinInputWidget> createState() => _CoinInputWidgetState();
}

class _CoinInputWidgetState extends State<CoinInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF374151), Color(0xFF4B5563)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.attach_money,
                color: const Color(0xFFFBBF24),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Purchase Amount',
                style: GoogleFonts.robotoFlex(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Amount input
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: GoogleFonts.robotoFlex(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: GoogleFonts.robotoFlex(
                  fontSize: 24,
                  color: Colors.white.withOpacity(0.3),
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'HK\$',
                    style: GoogleFonts.robotoFlex(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFBBF24),
                    ),
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0.0;
                widget.onAmountChanged(amount);
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Conversion info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFBBF24).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calculate,
                  size: 16,
                  color: const Color(0xFFFBBF24),
                ),
                const SizedBox(width: 8),
                Text(
                  'Conversion: HK\$1 = 0.8 coins',
                  style: GoogleFonts.robotoFlex(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Calculated coins display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Coins to Award',
                  style: GoogleFonts.robotoFlex(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      size: 24,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.calculatedCoins.toString(),
                      style: GoogleFonts.robotoFlex(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Award button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (widget.calculatedCoins > 0 && !widget.isLoading) 
                  ? widget.onAwardCoins 
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                disabledBackgroundColor: Colors.grey.shade600,
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      '✨ AWARD ${widget.calculatedCoins} COINS',
                      style: GoogleFonts.robotoFlex(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          
          // Quick amount buttons
          const SizedBox(height: 16),
          Text(
            'Quick Amounts',
            style: GoogleFonts.robotoFlex(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildQuickAmountButton('10'),
              const SizedBox(width: 8),
              _buildQuickAmountButton('25'),
              const SizedBox(width: 8),
              _buildQuickAmountButton('50'),
              const SizedBox(width: 8),
              _buildQuickAmountButton('100'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountButton(String amount) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          _controller.text = amount;
          widget.onAmountChanged(double.parse(amount));
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(
            color: const Color(0xFF6366F1).withOpacity(0.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(
          '\$$amount',
          style: GoogleFonts.robotoFlex(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
