// Automatic FlutterFlow imports
// Imports other custom widgets
// Imports custom actions
// Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/responsive_helper.dart';

class GoogleReviewManagementWidget extends StatefulWidget {
  const GoogleReviewManagementWidget({
    super.key,
    required this.venueId,
    this.width,
    this.height,
    this.backgroundColor = const Color(0xFF363740),
    this.textColor = const Color(0xFFFCFDFF),
    this.primaryColor = const Color(0xFF4285F4),
    this.successColor = const Color(0xFF4CAF50),
    this.warningColor = const Color(0xFFFF9800),
    this.showPreviewData = false,
  });

  final String venueId;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final Color textColor;
  final Color primaryColor;
  final Color successColor;
  final Color warningColor;
  final bool showPreviewData;

  @override
  _GoogleReviewManagementWidgetState createState() => _GoogleReviewManagementWidgetState();
}

class _GoogleReviewManagementWidgetState extends State<GoogleReviewManagementWidget> {
  Map<String, dynamic> _venueData = {
    'reviewLink': '',
    'coinImage': '',
    'hasReviewLink': false,
    'hasCoinImage': false,
  };
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  
  final TextEditingController _reviewLinkController = TextEditingController();
  final TextEditingController _coinImageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVenueData();
  }

  @override
  void didUpdateWidget(GoogleReviewManagementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.venueId != widget.venueId) {
      _loadVenueData();
    }
  }

  @override
  void dispose() {
    _reviewLinkController.dispose();
    _coinImageController.dispose();
    super.dispose();
  }

  Future<void> _loadVenueData() async {
    if (widget.showPreviewData) {
      setState(() {
        _venueData = {
          'reviewLink': 'https://g.page/r/example/review',
          'coinImage': 'https://example.com/coin.png',
          'hasReviewLink': true,
          'hasCoinImage': true,
        };
        _reviewLinkController.text = _venueData['reviewLink'];
        _coinImageController.text = _venueData['coinImage'];
        _isLoading = false;
      });
      return;
    }

    if (widget.venueId.isEmpty) {
      setState(() {
        _venueData = {
          'reviewLink': '',
          'coinImage': '',
          'hasReviewLink': false,
          'hasCoinImage': false,
        };
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading venue data for: ${widget.venueId}');

      final venueDoc = await FirebaseFirestore.instance
          .collection('venues')
          .doc(widget.venueId)
          .get();

      if (venueDoc.exists) {
        final data = venueDoc.data() as Map<String, dynamic>;
        final reviewLink = data['reviewLink'] as String? ?? '';
        final coinImage = data['coinImage'] as String? ?? '';

        setState(() {
          _venueData = {
            'reviewLink': reviewLink,
            'coinImage': coinImage,
            'hasReviewLink': reviewLink.isNotEmpty,
            'hasCoinImage': coinImage.isNotEmpty,
          };
          _reviewLinkController.text = reviewLink;
          _coinImageController.text = coinImage;
          _isLoading = false;
        });

        print('Loaded venue data - Review Link: ${reviewLink.isNotEmpty}, Coin Image: ${coinImage.isNotEmpty}');
      } else {
        print('Venue document not found: ${widget.venueId}');
        setState(() {
          _venueData = {
            'reviewLink': '',
            'coinImage': '',
            'hasReviewLink': false,
            'hasCoinImage': false,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading venue data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveVenueData() async {
    if (widget.venueId.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final reviewLink = _reviewLinkController.text.trim();
      final coinImage = _coinImageController.text.trim();

      await FirebaseFirestore.instance
          .collection('venues')
          .doc(widget.venueId)
          .update({
        'reviewLink': reviewLink,
        'coinImage': coinImage,
      });

      setState(() {
        _venueData = {
          'reviewLink': reviewLink,
          'coinImage': coinImage,
          'hasReviewLink': reviewLink.isNotEmpty,
          'hasCoinImage': coinImage.isNotEmpty,
        };
        _isEditing = false;
        _isSaving = false;
      });

      print('Saved venue data successfully');
    } catch (e) {
      print('Error saving venue data: $e');
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      _reviewLinkController.text = _venueData['reviewLink'];
      _coinImageController.text = _venueData['coinImage'];
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minWidth: 300),
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(31.0),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(32.0, 32.0, 32.0, 32.0),
            child: _isEditing ? _buildEditView() : _buildDataView(),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isEditing = !_isEditing;
                  if (!_isEditing) {
                    _cancelEditing();
                  }
                });
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.textColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _isEditing ? Icons.close : Icons.edit,
                  color: widget.textColor.withOpacity(0.7),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
          child: Text(
            'Google Reviews',
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: widget.textColor,
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Column(
            children: [
              _buildStatusCard(
                'Review Link',
                _venueData['hasReviewLink'] ? 'Configured' : 'Not Set',
                _venueData['hasReviewLink'] ? widget.successColor : widget.warningColor,
                _venueData['reviewLink'],
              ),
              const SizedBox(height: 16),
              _buildStatusCard(
                'Coin Image',
                _venueData['hasCoinImage'] ? 'Configured' : 'Not Set',
                _venueData['hasCoinImage'] ? widget.successColor : widget.warningColor,
                _venueData['coinImage'],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildEditView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
          child: Text(
            'Edit Google Reviews',
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: widget.textColor,
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (_isSaving)
          const Center(child: CircularProgressIndicator())
        else
          Column(
            children: [
              _buildEditField(
                'Google Review Link',
                _reviewLinkController,
                'https://g.page/r/your-venue/review',
              ),
              const SizedBox(height: 16),
              _buildEditField(
                'Coin Image URL',
                _coinImageController,
                'https://example.com/coin-image.png',
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveVenueData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancelEditing,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.textColor,
                        side: BorderSide(color: widget.textColor.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatusCard(String label, String status, Color statusColor, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Roboto Flex',
                  color: widget.textColor,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontFamily: 'Roboto Flex',
                    color: Colors.white,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (value.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Roboto Flex',
                color: widget.textColor.withOpacity(0.7),
                fontSize: 12.0,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor,
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: widget.textColor,
            fontSize: 14.0,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Roboto Flex',
              color: widget.textColor.withOpacity(0.5),
              fontSize: 14.0,
            ),
            filled: true,
            fillColor: widget.textColor.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: widget.textColor.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: widget.textColor.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: widget.primaryColor),
            ),
          ),
        ),
      ],
    );
  }
} 