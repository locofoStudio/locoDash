import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'dart:typed_data';

class ItemCreationWidget extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final VoidCallback? onCancel;
  const ItemCreationWidget({super.key, this.initialData, this.onCancel});

  @override
  State<ItemCreationWidget> createState() => _ItemCreationWidgetState();
}

class _ItemCreationWidgetState extends State<ItemCreationWidget> {
  final TextEditingController _offerNameController = TextEditingController();
  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _offerPriceController = TextEditingController();
  final TextEditingController _offerInfoController = TextEditingController();
  final TextEditingController _maxItemController = TextEditingController();
  String _selectedVenue = 'Select Venue';
  String? _selectedFilePath; // Local path on desktop/mobile
  Uint8List? _selectedFileBytes; // Raw bytes on web/mobile when path is null
  String? _selectedFileName; // Original filename, used for Storage path
  bool _isLoading = false;
  bool _isAvailable = true;
  List<String> _venues = ['Select Venue'];
  String? _currentUserId;
  Map<String, bool> _venueOwnership = {};
  String? _documentId;
  bool _isUsingSuggestedPrice = true;
  bool _fileChanged = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    if (widget.initialData != null) {
      _offerNameController.text = widget.initialData!['OfferName'] ?? '';
      _originalPriceController.text = widget.initialData!['originalPrice']?.toString() ?? '';
      _offerPriceController.text = widget.initialData!['OfferPrice']?.toString() ?? '';
      _offerInfoController.text = widget.initialData!['OfferInfo'] ?? '';
      _selectedVenue = widget.initialData!['venueId'] ?? 'Select Venue';
      _documentId = widget.initialData!['id'];
      _selectedFilePath = widget.initialData!['OfferPhoto'];
      _isUsingSuggestedPrice = false; // When editing, we don't use suggested price
      _isAvailable = widget.initialData!['available'] ?? true;
      _maxItemController.text = widget.initialData!['maxRedemptions']?.toString() ?? '';
    }

    // Add listener to original price controller
    _originalPriceController.addListener(_updateSuggestedPrice);
  }

  void _updateSuggestedPrice() {
    if (_isUsingSuggestedPrice) {
      final originalPrice = double.tryParse(_originalPriceController.text) ?? 0.0;
      final suggestedPrice = originalPrice * 11;
      _offerPriceController.text = suggestedPrice.toStringAsFixed(2);
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      print('Current user: ${user?.uid}');
      if (user != null) {
        setState(() {
          _currentUserId = user.uid;
        });
        await _loadVenues();
      } else {
        print('No user logged in');
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadVenues() async {
    try {
      print('Loading venues for user: $_currentUserId');
      
      // First get the venue owner document for the current user
      final venueOwnerDoc = await FirebaseFirestore.instance
          .collection('venueOwners')
          .doc(_currentUserId)
          .get();

      if (!venueOwnerDoc.exists) {
        print('No venue owner document found for user');
        return;
      }

      // Get the list of venue IDs the user owns
      final List<dynamic> ownedVenueIds = venueOwnerDoc.data()?['venues'] ?? [];
      print('User owns venues: $ownedVenueIds');

      if (ownedVenueIds.isEmpty) {
        print('User has no venues');
        return;
      }

      // Get the venue details for each owned venue
      final venues = await Future.wait(
        ownedVenueIds.map((venueId) async {
          final venueDoc = await FirebaseFirestore.instance
              .collection('venues')
              .doc(venueId.toString())
              .get();
          return venueDoc.data()?['name'] as String? ?? venueId.toString();
        }),
      );

      print('Available venues: $venues');

      setState(() {
        _venues = ['Select Venue'] + venues;
        _venueOwnership = {
          for (var venueId in ownedVenueIds)
            venueId.toString(): true
        };
        if (_venues.length > 1) {
          _selectedVenue = _venues[1]; // Select first available venue by default
        }
      });
    } catch (e) {
      print('Error loading venues: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading venues: $e')),
      );
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final picked = result.files.first;
        setState(() {
          _selectedFilePath = picked.path; // may be null on web
          _selectedFileBytes = picked.bytes; // null on desktop
          _selectedFileName = picked.name;
          _fileChanged = true;
        });
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error selecting file. Please try again.')),
      );
    }
  }

  Future<void> _addOffer() async {
    if (_selectedVenue == 'Select Venue') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a venue')),
      );
      return;
    }

    final venueId = _venues.firstWhere((v) => v == _selectedVenue, orElse: () => '');
    if (venueId.isEmpty || !_venueOwnership.containsKey(venueId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'You do not have permission to add offers to this venue')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload the image (supports both path+File and raw bytes)
      String? photoUrl;
      if (_fileChanged) {
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('offers')
              .child(venueId)
              .child(_selectedFileName ?? 'img_${DateTime.now().millisecondsSinceEpoch}');

          if (_selectedFileBytes != null) {
            // Web / bytes path
            await storageRef.putData(_selectedFileBytes!);
          } else if (_selectedFilePath != null) {
            final file = File(_selectedFilePath!);
            await storageRef.putFile(file);
          }

          photoUrl = await storageRef.getDownloadURL();
        } catch (e) {
          print('Upload error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image upload failed')),
          );
        }
      }

      final offerData = {
        'OfferName': _offerNameController.text,
        'OfferInfo': _offerInfoController.text,
        'OfferPrice': double.tryParse(_offerPriceController.text) ?? 0.0,
        'originalPrice': double.tryParse(_originalPriceController.text) ?? 0.0,
        'OfferPhoto': photoUrl,
        'venueId': venueId,
        'createdBy': _currentUserId,
        'available': _isAvailable,
        'maxRedemptions': int.tryParse(_maxItemController.text) ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_documentId != null) {
        // Update existing document
        await FirebaseFirestore.instance
            .collection('offers')
            .doc(_documentId)
            .update(offerData);
      } else {
        // Create new document with deterministic id "OfferName-venueId"
        offerData['createdAt'] = FieldValue.serverTimestamp();
        final docId = '${_offerNameController.text.trim().replaceAll(' ', '_')}-$venueId';
        await FirebaseFirestore.instance
            .collection('offers')
            .doc(docId)
            .set(offerData);
      }

      if (widget.onCancel != null) {
        widget.onCancel!();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Error ${_documentId != null ? 'updating' : 'creating'} offer: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteOffer() async {
    if (_documentId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete offer'),
        content: const Text('Are you sure you want to delete this offer?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('offers').doc(_documentId).delete();
      if (widget.onCancel != null) widget.onCancel!();
    } catch (e) {
      print('Delete error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting offer: $e')),
      );
    }
  }

  @override
  void dispose() {
    _originalPriceController.removeListener(_updateSuggestedPrice);
    _offerNameController.dispose();
    _originalPriceController.dispose();
    _offerPriceController.dispose();
    _offerInfoController.dispose();
    _maxItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final width = isMobile ? MediaQuery.of(context).size.width * 0.9 : 453.0;

    return Container(
      width: width,
      padding: EdgeInsets.all(isMobile ? 20.0 : 40.5),
      decoration: BoxDecoration(
        color: const Color(0xFF363C40),
        borderRadius: BorderRadius.circular(31),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _documentId != null ? 'Edit Item' : 'Add Item',
                  style: const TextStyle(
                    color: Color(0xFFFCFDFF),
                    fontSize: 20,
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedVenue,
                  dropdownColor: const Color(0xFF0F2533),
                  style: const TextStyle(color: Color(0xFFFCFDFF)),
                  underline: Container(
                    height: 1,
                    color: const Color(0xFFFCFDFF),
                  ),
                  items: _venues.map((String venue) {
                    return DropdownMenuItem<String>(
                      value: venue,
                      child: Text(venue),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedVenue = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(_offerNameController, 'Offer name'),
            const SizedBox(height: 20),
            _buildTextField(_originalPriceController, 'Original price', isNumeric: true),
            const SizedBox(height: 10),
            Text(
              'Suggested price (Original Price × 11)',
              style: TextStyle(
                color: const Color(0xFFFCFDFF).withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            _buildTextField(_offerPriceController, 'Offer price', isNumeric: true),
            const SizedBox(height: 20),
            _buildTextField(_offerInfoController, 'Offer info', maxLines: 3),
            const SizedBox(height: 20),
            // Availability and Max Item
            Row(
              children: [
                const Text('Available', style: TextStyle(color: Color(0xFFFCFDFF), fontSize: 14)),
                const SizedBox(width: 12),
                Switch(
                  value: _isAvailable,
                  activeColor: const Color(0xFFE9724C),
                  onChanged: (val) {
                    setState(() {
                      _isAvailable = val;
                    });
                  },
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildTextField(_maxItemController, 'Max item', isNumeric: true),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _pickFile,
                  child: SizedBox(
                    width: 22,
                    height: 23,
                    child: CustomPaint(
                      painter: AttachmentIconPainter(),
                    ),
                  ),
                ),
                if (_selectedFilePath != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'File selected: ${_selectedFilePath!.split('/').last}',
                        style: const TextStyle(color: Color(0xFFDCDCDC)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: 130,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addOffer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE9724C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(31),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : Text(
                            _documentId != null ? 'Update Item' : 'Add Item',
                            style: const TextStyle(
                              color: Color(0xFFFCFDFF),
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                if (_documentId != null) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _deleteOffer,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                  ),
                ]
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () {
                  if (widget.onCancel != null) {
                    widget.onCancel!();
                  }
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Color(0xFFE9724C),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumeric = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFCFDFF),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(color: Color(0xFFDCDCDC)),
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: label,
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
      ],
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