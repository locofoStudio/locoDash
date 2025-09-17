# 🎯 Dashboard Wallet Pass Integration Guide

This guide provides step-by-step instructions to integrate Apple Wallet pass creation and customization into the venue dashboard.

## 📋 Overview

We're adding a new "Wallet Pass" tab (Tab 4) to the existing dashboard navigation, allowing venue owners to:
- Design custom Apple Wallet passes
- Preview passes in real-time
- Save configurations to the wallet service
- Test pass creation with their venue data

## 🏗️ Architecture

```
Dashboard Tab 4 → Pass Designer → Wallet Functions → Pass Preview
      ↑                                    ↓
Venue Selection                    locowallet-30799 project
```

## 📁 Current Dashboard Structure

Based on analysis of `/lib/pages/landing_page.dart`:

**Existing Tabs:**
- Tab 0: Analytics (default)
- Tab 1: Users  
- Tab 2: Offers
- Tab 3: Leaderboard
- **Tab 4: Wallet Pass (NEW)** ✨

**Navigation System:**
- `_selectedIndex` controls active tab
- `_buildTabRow()` creates tab buttons
- `_buildTabButton()` creates individual tabs
- Responsive layout with `_buildDesktopLayout()` and `_buildMobileLayout()`

## 🚀 Step-by-Step Implementation

### **STEP 1: Add Wallet Pass Tab to Navigation**

**File:** `/lib/pages/landing_page.dart`

**1.1** Find the `_buildTabRow()` method (around line 703) and add the new tab:

```dart
Widget _buildTabRow() {
  return Row(
    children: [
      _buildTabButton('Analytics', 0),
      _buildTabButton('Users', 1),
      const SizedBox(width: 8),
      _buildTabButton('Offers', 2),
      const SizedBox(width: 8),
      _buildTabButton('Leaderboard', 3),
      const SizedBox(width: 8),
      _buildTabButton('Wallet Pass', 4), // NEW TAB
    ],
  );
}
```

**1.2** Update the desktop layout switch statement in `_buildDesktopLayout()`:

```dart
Widget _buildDesktopLayout() {
  switch (_selectedIndex) {
    case 0: // Analytics
      return _buildDesktopAnalyticsTab();
    case 1: // Users
      return _buildDesktopUsersTab();
    case 2: // Offers
      return _buildDesktopOffersTab();
    case 3: // Leaderboard
      return _buildDesktopLeaderboardTab();
    case 4: // Wallet Pass
      return _buildDesktopWalletPassTab(); // NEW METHOD
    default:
      return _buildDesktopAnalyticsTab();
  }
}
```

**1.3** Update the mobile layout switch statement in `_buildMobileLayout()`:

```dart
Widget _buildMobileLayout() {
  switch (_selectedIndex) {
    case 0: // Analytics
      return _buildAnalyticsTab();
    case 1: // Users
      return _buildUsersTab();
    case 2: // Offers
      return _buildOffersTab();
    case 3: // Leaderboard
      return _buildLeaderboardTab();
    case 4: // Wallet Pass
      return _buildWalletPassTab(); // NEW METHOD
    default:
      return _buildAnalyticsTab();
  }
}
```

### **STEP 2: Create Wallet Pass Tab Content Methods**

**File:** `/lib/pages/landing_page.dart`

Add these methods after the existing tab methods:

```dart
// Desktop wallet pass tab
Widget _buildDesktopWalletPassTab() {
  if (_selectedVenue == null) {
    return const Center(
      child: Text(
        'No venue selected',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
    child: WalletPassDesignerWidget(
      venueId: _selectedVenue!,
      showPreviewData: false,
      width: double.infinity,
      height: 700,
    ),
  );
}

// Mobile wallet pass tab
Widget _buildWalletPassTab() {
  if (_selectedVenue == null) {
    return const Center(
      child: Text(
        'No venue selected',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
    child: WalletPassDesignerWidget(
      venueId: _selectedVenue!,
      showPreviewData: false,
    ),
  );
}
```

### **STEP 3: Create Wallet Pass Designer Widget**

**File:** `/lib/custom_code/widgets/wallet_pass_designer_widget.dart` (NEW FILE)

```dart
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
        app: Firebase.app(), // TODO: Configure for locowallet project
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
                  fontSize: 14,
                ),
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
              // TODO: Implement color picker dialog
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
```

### **STEP 4: Add Firebase Configuration for Wallet Functions**

**File:** `/lib/services/wallet_service.dart` (NEW FILE)

```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

class WalletService {
  static FirebaseFunctions? _functions;
  
  static FirebaseFunctions get functions {
    _functions ??= FirebaseFunctions.instanceFor(
      region: 'us-central1',
      // TODO: Configure for locowallet-30799 project
      // This will need to be updated once the functions are deployed
    );
    return _functions!;
  }
  
  static Future<Map<String, dynamic>> createPass({
    required String venueId,
    int? balance,
    String? venueName,
    String? displayName,
  }) async {
    try {
      final createPass = functions.httpsCallable('createPass');
      final result = await createPass.call({
        'venueId': venueId,
        if (balance != null) 'balance': balance,
        if (venueName != null) 'venueName': venueName,
        if (displayName != null) 'displayName': displayName,
      });
      
      return Map<String, dynamic>.from(result.data);
    } catch (error) {
      throw Exception('Failed to create pass: $error');
    }
  }
  
  static Future<void> saveVenuePassConfig({
    required String venueId,
    required Map<String, dynamic> config,
  }) async {
    try {
      final saveConfig = functions.httpsCallable('saveVenuePassConfig');
      await saveConfig.call({
        'venueId': venueId,
        'config': config,
      });
    } catch (error) {
      throw Exception('Failed to save config: $error');
    }
  }
  
  static Future<Map<String, dynamic>?> getVenuePassConfig({
    required String venueId,
  }) async {
    try {
      final getConfig = functions.httpsCallable('getVenuePassConfig');
      final result = await getConfig.call({
        'venueId': venueId,
      });
      
      final data = Map<String, dynamic>.from(result.data);
      return data['config'];
    } catch (error) {
      throw Exception('Failed to get config: $error');
    }
  }
}
```

### **STEP 5: Update Dependencies**

**File:** `pubspec.yaml`

Add these dependencies if not already present:

```yaml
dependencies:
  # ... existing dependencies
  cloud_functions: ^4.5.0
  firebase_core: ^2.24.0
```

### **STEP 6: Import the New Widget**

**File:** `/lib/pages/landing_page.dart`

Add this import at the top:

```dart
import '/custom_code/widgets/wallet_pass_designer_widget.dart';
```

## 🧪 Testing Plan

### **Phase 1: UI Testing**
1. **Add the tab** - Verify new "Wallet Pass" tab appears
2. **Tab navigation** - Ensure clicking switches to wallet pass content
3. **Venue selection** - Confirm venue selector works with wallet tab
4. **Responsive layout** - Test on desktop and mobile layouts

### **Phase 2: Designer Testing**
1. **Color changes** - Verify color pickers update preview
2. **Text changes** - Confirm text fields update preview
3. **Real-time preview** - Ensure preview updates immediately
4. **Save functionality** - Test configuration saving

### **Phase 3: Integration Testing**
1. **Function calls** - Verify calls to wallet functions work
2. **Error handling** - Test error scenarios and user feedback
3. **Data persistence** - Confirm configs are saved and loaded
4. **Cross-project access** - Verify venue data is accessible

## 🚀 Deployment Checklist

### **Before Starting:**
- [ ] Ensure wallet functions are deployed to `locowallet-30799`
- [ ] Verify Firebase authentication is configured
- [ ] Confirm venue selection system is working

### **Implementation Steps:**
- [ ] Step 1: Add wallet pass tab to navigation
- [ ] Step 2: Create tab content methods
- [ ] Step 3: Create wallet pass designer widget
- [ ] Step 4: Add wallet service for function calls
- [ ] Step 5: Update dependencies
- [ ] Step 6: Add imports

### **Testing Steps:**
- [ ] UI testing: Tab navigation and layout
- [ ] Designer testing: Controls and preview
- [ ] Integration testing: Function calls and data flow
- [ ] End-to-end testing: Complete venue workflow

## 📞 Support

- **Main documentation**: `/wallet_pass_integration/README.md` (this file)
- **Wallet functions**: `/locowallet-functions/README.md`
- **Original implementation**: `/wallet_pass/README.md`

## 🎯 Next Steps

After completing this integration:
1. **Deploy wallet functions** to `locowallet-30799`
2. **Test complete flow** from dashboard to pass creation
3. **Add main app integration** for user pass downloads
4. **Implement certificate management** for production signing

---

**Ready to implement!** Use this guide with AI in your dashboard project to add the wallet pass functionality step by step. 🚀
