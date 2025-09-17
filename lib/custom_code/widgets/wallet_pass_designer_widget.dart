import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:io';

class WalletPassDesignerWidget extends StatefulWidget {
  final String venueId;
  final bool showPreviewData;
  final double? width;
  final double? height;

  const WalletPassDesignerWidget({
    super.key,
    required this.venueId,
    this.showPreviewData = false,
    this.width,
    this.height,
  });

  @override
  State<WalletPassDesignerWidget> createState() => _WalletPassDesignerWidgetState();
}

class _WalletPassDesignerWidgetState extends State<WalletPassDesignerWidget> {
  // Design state - Apple Wallet inspired defaults
  Color _backgroundColor = const Color(0xFFEEEEEE); // Light gray background
  Color _textColor = Colors.black;
  Color _labelColor = const Color(0xFF777777); // Gray for labels
  Color _stripColor = const Color(0xFF007AFF); // iOS Blue for strip
  
  String _organizationName = 'LocoLoyalty';
  String _headerText = 'LocoLoyalty';
  String _balanceLabel = 'BALANCE';
  String _venueLabel = 'VENUE';
  String _nameLabel = 'NAME';
  String _balanceValue = '100.00';
  String _nameValue = 'displayName';
  String _qrCodeText = '11223344556677';
  
  // Image assets
  String? _stripImagePath;
  String? _logoImagePath;
  
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadVenueConfig();
  }

  Future<void> _loadVenueConfig() async {
    // TODO: Load existing config from wallet functions
  }

  Future<void> _pickStripImage() async {
    try {
      setState(() {
        _statusMessage = 'Selecting strip image...';
      });
      
      // Create file input element
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();
      
      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          
          // Check file size (max 5MB)
          if (file.size > 5 * 1024 * 1024) {
            setState(() {
              _statusMessage = 'Image too large. Please select an image under 5MB.';
            });
            return;
          }
          
          final reader = html.FileReader();
          
          reader.onLoadEnd.listen((e) {
            setState(() {
              _stripImagePath = reader.result as String;
              _statusMessage = 'Strip image uploaded successfully! Path: ${_stripImagePath?.substring(0, 50)}...';
            });
          });
          
          reader.onError.listen((e) {
            setState(() {
              _statusMessage = 'Error reading strip image file.';
            });
          });
          
          reader.readAsDataUrl(file);
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error picking strip image: $e';
      });
    }
  }

  Future<void> _pickLogoImage() async {
    try {
      setState(() {
        _statusMessage = 'Selecting logo image...';
      });
      
      // Create file input element
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();
      
      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          
          // Check file size (max 5MB)
          if (file.size > 5 * 1024 * 1024) {
            setState(() {
              _statusMessage = 'Image too large. Please select an image under 5MB.';
            });
            return;
          }
          
          final reader = html.FileReader();
          
          reader.onLoadEnd.listen((e) {
            setState(() {
              _logoImagePath = reader.result as String;
              _statusMessage = 'Logo image uploaded successfully! Path: ${_logoImagePath?.substring(0, 50)}...';
            });
          });
          
          reader.onError.listen((e) {
            setState(() {
              _statusMessage = 'Error reading logo image file.';
            });
          });
          
          reader.readAsDataUrl(file);
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error picking logo image: $e';
      });
    }
  }

  Future<void> _saveConfig() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      // Call wallet function to save config
      final functions = FirebaseFunctions.instanceFor(
        region: 'us-central1',
        // TODO: Configure for locowallet project
      );
      
      final saveConfig = functions.httpsCallable('saveVenuePassConfig');
      
      final config = {
        'venueId': widget.venueId,
        'config': {
          'venueId': widget.venueId,
          'design': {
            'colors': {
              'background': 'rgb(${_backgroundColor.red}, ${_backgroundColor.green}, ${_backgroundColor.blue})',
              'text': 'rgb(${_textColor.red}, ${_textColor.green}, ${_textColor.blue})',
              'label': 'rgb(${_labelColor.red}, ${_labelColor.green}, ${_labelColor.blue})',
              'strip': 'rgb(${_stripColor.red}, ${_stripColor.green}, ${_stripColor.blue})',
            },
            'branding': {
              'organizationName': _organizationName,
              'headerText': _headerText,
              'stripImagePath': _stripImagePath,
              'logoImagePath': _logoImagePath,
            },
            'layout': {
              'style': 'stacked',
              'fieldLabels': {
                'balance': _balanceLabel,
                'venue': _venueLabel,
                'name': _nameLabel,
              },
              'fieldValues': {
                'balance': _balanceValue,
                'name': _nameValue,
              },
            },
          },
          'template': {
            'id': 'default',
            'name': 'Default Template',
          },
          'metadata': {
            'created': DateTime.now().toIso8601String(),
            'updated': DateTime.now().toIso8601String(),
            'status': 'active',
          },
        },
      };

      await saveConfig.call(config);
      
      setState(() {
        _statusMessage = 'Configuration saved successfully!';
      });
      
    } catch (error) {
      setState(() {
        _statusMessage = 'Error saving configuration: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCreatePass() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final functions = FirebaseFunctions.instanceFor(
        region: 'us-central1',
        // TODO: Configure for locowallet project
      );
      
      final createPass = functions.httpsCallable('createPass');
      
      final result = await createPass.call({
        'venueId': widget.venueId,
        'balance': 1234,
        'venueName': widget.venueId,
        'displayName': 'Test User',
      });
      
      setState(() {
        _statusMessage = 'Test pass created successfully! URL: ${result.data['applePassUrl']}';
      });
      
    } catch (error) {
      setState(() {
        _statusMessage = 'Error creating test pass: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF363740),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Controls Panel (Left Side)
          Expanded(
            flex: 1,
            child: _buildControlsPanel(),
          ),
          // Preview Panel (Right Side)
          Expanded(
            flex: 1,
            child: _buildPreviewPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pass Designer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testCreatePass,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6FA6A0),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveConfig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC5C352),
                      foregroundColor: Colors.black,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Status Message
          if (_statusMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _statusMessage!.contains('Error') ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _statusMessage!.contains('Error') ? Colors.red : Colors.green,
                ),
              ),
              child: Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessage!.contains('Error') ? Colors.red : Colors.green,
                  fontSize: 12,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          
          // Controls
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Branding', [
                    _buildTextField('Organization Name', _organizationName, (value) {
                      setState(() => _organizationName = value);
                    }),
                    _buildTextField('Header Text', _headerText, (value) {
                      setState(() => _headerText = value);
                    }),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  _buildSection('Images', [
                    _buildImagePicker('Strip Image (358x130px)', _stripImagePath, _pickStripImage),
                    _buildImagePicker('Logo Image (56x56px)', _logoImagePath, _pickLogoImage),
                    const SizedBox(height: 8),
                    Text(
                      '• Strip image: Background for the header area\n• Logo image: Centered logo in the header\n• Images will be automatically resized to fit',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  _buildSection('Colors', [
                    _buildColorPicker('Background', _backgroundColor, (color) {
                      setState(() => _backgroundColor = color);
                    }),
                    _buildColorPicker('Text', _textColor, (color) {
                      setState(() => _textColor = color);
                    }),
                    _buildColorPicker('Labels', _labelColor, (color) {
                      setState(() => _labelColor = color);
                    }),
                    _buildColorPicker('Strip', _stripColor, (color) {
                      setState(() => _stripColor = color);
                    }),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  _buildSection('Field Labels', [
                    _buildTextField('Balance Label', _balanceLabel, (value) {
                      setState(() => _balanceLabel = value);
                    }),
                    _buildTextField('Venue Label', _venueLabel, (value) {
                      setState(() => _venueLabel = value);
                    }),
                    _buildTextField('Name Label', _nameLabel, (value) {
                      setState(() => _nameLabel = value);
                    }),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  _buildSection('Field Values', [
                    _buildTextField('Balance Value', _balanceValue, (value) {
                      setState(() => _balanceValue = value);
                    }),
                    _buildTextField('Name Value', _nameValue, (value) {
                      setState(() => _nameValue = value);
                    }),
                    _buildTextField('QR Code Text', _qrCodeText, (value) {
                      setState(() => _qrCodeText = value);
                    }),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // Test Pass Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _testCreatePass,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34C759),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Create Test Pass',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Live Preview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Apple Wallet Pass',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: _buildPassPreview(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassPreview() {
    return Container(
      width: 358, // Exact width from your design
      height: 502, // Exact height from your design
      decoration: BoxDecoration(
        color: _backgroundColor, // Use the customizable background color
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: Colors.black.withOpacity(0.16),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Main content column
          Positioned(
            left: 0,
            top: 0,
            child: Column(
              children: [
                // Header section with logo, text, and balance
                Container(
                  width: 358,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      // Logo (24x24 black circle)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Logo text
                      Text(
                        _headerText,
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                      const Spacer(),
                      // Balance section (right aligned)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _balanceLabel,
                            style: TextStyle(
                              color: _labelColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'SF Pro Text',
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\$${_balanceValue}',
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 21,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Strip image (130px height)
                Container(
                  width: 358,
                  height: 130,
                  decoration: BoxDecoration(
                    color: _stripColor,
                    image: _stripImagePath != null 
                      ? DecorationImage(
                          image: NetworkImage(_stripImagePath!),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {
                            print('Error loading strip image: $exception');
                          },
                        )
                      : null,
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _logoImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _logoImagePath!,
                              fit: BoxFit.cover,
                              width: 56,
                              height: 56,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 56,
                                  height: 56,
                                  color: Colors.red,
                                  child: const Icon(
                                    Icons.error,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.star,
                            color: _stripColor,
                            size: 32,
                          ),
                    ),
                  ),
                ),
                
                // Content fields section
                Container(
                  width: 358,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    children: [
                      // Three fields row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Field C (left)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nameLabel,
                                style: TextStyle(
                                  color: _labelColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'SF Pro Text',
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _nameValue,
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'SF Pro Text',
                                ),
                              ),
                            ],
                          ),
                          
                          // Field D (center)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _venueLabel,
                                style: TextStyle(
                                  color: _labelColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'SF Pro Text',
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.venueId,
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'SF Pro Text',
                                ),
                              ),
                            ],
                          ),
                          
                          // Field E (right)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Field E',
                                style: TextStyle(
                                  color: _labelColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'SF Pro Text',
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'A',
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'SF Pro Text',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // QR Code section (positioned at bottom)
          Positioned(
            left: 0,
            top: 310,
            child: Container(
              width: 358,
              height: 176,
              child: Center(
                child: Column(
                  children: [
                    // QR Code container
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: Container(
                          width: 118,
                          height: 118,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.qr_code,
                            color: Colors.white,
                            size: 80,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // QR Code text
                    Text(
                      _qrCodeText,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Small logo at bottom left
          Positioned(
            left: 7,
            top: 475,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.black.withOpacity(0.16),
                  width: 0.5,
                ),
              ),
            ),
          ),
          
          // Paywave icon at bottom right
          Positioned(
            right: 6,
            top: 462,
            child: Container(
              width: 32,
              height: 32,
              child: Center(
                child: Container(
                  width: 19.13,
                  height: 29.98,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildTextField(String label, String value, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: value,
            onChanged: onChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF2A2D35),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker(String label, Color color, Function(Color) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: () {
                  _showColorPickerDialog(label, color, onChanged);
                },
                child: Container(
                  width: 40,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Hex code input
          Container(
            height: 36,
            child: TextFormField(
              initialValue: '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText: '#FFFFFF',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.6)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (value) {
                if (value.startsWith('#') && value.length == 7) {
                  try {
                    final hexColor = Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
                    onChanged(hexColor);
                  } catch (e) {
                    // Invalid hex color, ignore
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPickerDialog(String label, Color color, Function(Color) onChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Pick $label Color',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color palette
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Common colors
                  _buildColorSwatch(Colors.white, onChanged),
                  _buildColorSwatch(Colors.black, onChanged),
                  _buildColorSwatch(Colors.grey, onChanged),
                  _buildColorSwatch(Colors.red, onChanged),
                  _buildColorSwatch(Colors.green, onChanged),
                  _buildColorSwatch(Colors.blue, onChanged),
                  _buildColorSwatch(Colors.yellow, onChanged),
                  _buildColorSwatch(Colors.orange, onChanged),
                  _buildColorSwatch(Colors.purple, onChanged),
                  _buildColorSwatch(Colors.pink, onChanged),
                  _buildColorSwatch(Colors.teal, onChanged),
                  _buildColorSwatch(Colors.cyan, onChanged),
                  _buildColorSwatch(Colors.indigo, onChanged),
                  _buildColorSwatch(Colors.brown, onChanged),
                  _buildColorSwatch(Colors.amber, onChanged),
                  _buildColorSwatch(Colors.lime, onChanged),
                  // iOS colors
                  _buildColorSwatch(const Color(0xFF007AFF), onChanged),
                  _buildColorSwatch(const Color(0xFF34C759), onChanged),
                  _buildColorSwatch(const Color(0xFFFF9500), onChanged),
                  _buildColorSwatch(const Color(0xFFFF3B30), onChanged),
                  _buildColorSwatch(const Color(0xFFAF52DE), onChanged),
                  _buildColorSwatch(const Color(0xFF5AC8FA), onChanged),
                  _buildColorSwatch(const Color(0xFFFF2D92), onChanged),
                  _buildColorSwatch(const Color(0xFFFFCC00), onChanged),
                  // Custom colors
                  _buildColorSwatch(const Color(0xFF1A1A1A), onChanged),
                  _buildColorSwatch(const Color(0xFF2C2C2E), onChanged),
                  _buildColorSwatch(const Color(0xFF3A3A3C), onChanged),
                  _buildColorSwatch(const Color(0xFF48484A), onChanged),
                  _buildColorSwatch(const Color(0xFF8E8E93), onChanged),
                  _buildColorSwatch(const Color(0xFFC7C7CC), onChanged),
                  _buildColorSwatch(const Color(0xFFD1D1D6), onChanged),
                  _buildColorSwatch(const Color(0xFFF2F2F7), onChanged),
                ],
              ),
              const SizedBox(height: 16),
              // Hex input in dialog
              TextFormField(
                initialValue: '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  labelText: 'Hex Code',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: '#FFFFFF',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.6)),
                  ),
                ),
                onChanged: (value) {
                  if (value.startsWith('#') && value.length == 7) {
                    try {
                      final hexColor = Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
                      onChanged(hexColor);
                    } catch (e) {
                      // Invalid hex color, ignore
                    }
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSwatch(Color color, Function(Color) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(color),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(String label, String? imagePath, VoidCallback onPick) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onPick,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2D35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Choose Image',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              if (imagePath != null) ...[
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (label.contains('Strip')) {
                        _stripImagePath = null;
                      } else {
                        _logoImagePath = null;
                      }
                    });
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// Simple color picker widget
class BlockPicker extends StatelessWidget {
  final Color pickerColor;
  final Function(Color) onColorChanged;

  const BlockPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      // Apple Wallet inspired colors
      const Color(0xFF007AFF), // iOS Blue
      const Color(0xFF34C759), // iOS Green
      const Color(0xFFFF9500), // iOS Orange
      const Color(0xFFFF3B30), // iOS Red
      const Color(0xFFAF52DE), // iOS Purple
      const Color(0xFFFF2D92), // iOS Pink
      const Color(0xFF5AC8FA), // iOS Light Blue
      const Color(0xFFFFCC00), // iOS Yellow
      
      // Standard colors
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.black,
      Colors.white,
      
      // Custom brand colors
      const Color(0xFF1A1A1A), // Dark background
      const Color(0xFF3C414C), // Medium dark
      const Color(0xFFC5C352), // Brand yellow
      const Color(0xFF6FA6A0), // Brand teal
      const Color(0xFFFF6633), // Brand orange
    ];

    return Wrap(
      children: colors.map((color) => GestureDetector(
        onTap: () {
          onColorChanged(color);
          Navigator.of(context).pop();
        },
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color == pickerColor ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
        ),
      )).toList(),
    );
  }
}
