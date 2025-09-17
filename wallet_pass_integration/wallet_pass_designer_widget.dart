import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

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
  // Design state
  Color _backgroundColor = const Color(0xFF3C414C);
  Color _textColor = Colors.white;
  Color _labelColor = const Color(0xFFFF6633);
  Color _stripColor = const Color(0xFFC5C352);
  
  String _organizationName = 'LocoLoyalty';
  String _headerText = 'LocoLoyalty';
  String _balanceLabel = 'BALANCE';
  String _venueLabel = 'VENUE';
  String _nameLabel = 'NAME';
  
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
            },
            'layout': {
              'style': 'stacked',
              'fieldLabels': {
                'balance': _balanceLabel,
                'venue': _venueLabel,
                'name': _nameLabel,
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
            'Preview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: _buildPassPreview(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassPreview() {
    return Container(
      width: 300,
      height: 180,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Strip
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: _stripColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                _headerText,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Primary Field
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _balanceLabel,
                        style: TextStyle(
                          color: _labelColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '1,234',
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Secondary Field
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _venueLabel,
                        style: TextStyle(
                          color: _labelColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.venueId,
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // QR Code Placeholder
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _textColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code,
                      color: Colors.black,
                      size: 40,
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
      child: Row(
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
              // Simple color picker dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Pick $label Color'),
                  content: SingleChildScrollView(
                    child: BlockPicker(
                      pickerColor: color,
                      onColorChanged: onChanged,
                    ),
                  ),
                ),
              );
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
      const Color(0xFF3C414C),
      const Color(0xFFC5C352),
      const Color(0xFF6FA6A0),
      const Color(0xFFFF6633),
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
