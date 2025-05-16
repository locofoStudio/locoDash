import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/custom_code/widgets/venue_user_metrics_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/custom_code/widgets/venue_coins_metrics_widget.dart';
import '/custom_code/widgets/venue_stats_widget.dart';

class LandingPageMobile extends StatefulWidget {
  const LandingPageMobile({Key? key, required this.venueId}) : super(key: key);

  final String venueId;

  @override
  _LandingPageMobileState createState() => _LandingPageMobileState();
}

class _LandingPageMobileState extends State<LandingPageMobile> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  String? _selectedVenue;
  List<String> _venueNames = [];
  List<String> _venueIds = [];
  bool _loadingVenues = true;
  bool _dropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedVenue = widget.venueId;
    _loadVenues();
  }

  // Load venues from Firestore
  Future<void> _loadVenues() async {
    setState(() {
      _loadingVenues = true;
    });

    try {
      print('Loading venues from Firestore...');
      final venuesSnapshot = await FirebaseFirestore.instance.collection('venues').get();
      
      print('Found ${venuesSnapshot.docs.length} venues in the collection');
      for (var doc in venuesSnapshot.docs) {
        print('Venue document ID: ${doc.id}');
        print('Venue data: ${doc.data()}');
      }
      
      List<String> names = [];
      List<String> ids = [];
      
      for (var doc in venuesSnapshot.docs) {
        final data = doc.data();
        final name = data['name'] as String? ?? doc.id;
        print('Processing venue: $name (${doc.id})');
        names.add(name);
        ids.add(doc.id);
      }
      
      // Ensure we include 'Baked' and 'Demo' if they don't exist
      if (!names.contains('Baked') && !names.contains('baked')) {
        print('Adding default Baked venue as it was not found');
        names.add('Baked');
        ids.add('baked'); // using lowercase ID as convention
      }
      
      if (!names.contains('Demo') && !names.contains('demo')) {
        print('Adding default Demo venue as it was not found');
        names.add('Demo');
        ids.add('demo'); // using lowercase ID as convention
      }
      
      setState(() {
        _venueNames = names;
        _venueIds = ids;
        _loadingVenues = false;

        // If we have venues and no venue is selected yet, select the first one
        if (_venueIds.isNotEmpty && (_selectedVenue == null || _selectedVenue!.isEmpty || _selectedVenue == 'preview-venue' || _selectedVenue == 'venue-123')) {
          // Prioritize selecting 'baked' or 'Baked' venue if available
          final bakedIndex = _venueIds.indexWhere((id) => id.toLowerCase() == 'baked');
          if (bakedIndex >= 0) {
            _selectedVenue = _venueIds[bakedIndex];
          } else {
            _selectedVenue = _venueIds.first;
          }
          print('Selected venue: ${_selectedVenue}');
        }
      });
    } catch (e) {
      print('Error loading venues: $e');
      setState(() {
        // Fallback to default venues if Firebase query fails
        _venueNames = ['Baked', 'Demo'];
        _venueIds = ['baked', 'demo'];
        _selectedVenue = 'baked';
        _loadingVenues = false;
      });
    }
  }

  // Get venue name from venue ID
  String _getVenueName(String? venueId) {
    if (venueId == null || venueId.isEmpty) return 'Select Venue';
    final index = _venueIds.indexOf(venueId);
    if (index >= 0 && index < _venueNames.length) {
      return _venueNames[index];
    }
    return 'Unknown Venue';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFF1F2029),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2029),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 15,
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome',
                  style: TextStyle(
                    fontFamily: 'Roboto Flex',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  'Locofo Studio',
                  style: TextStyle(
                    fontFamily: 'Roboto Flex',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Spacer(),
            _buildVenueDropdown(),
          ],
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        top: true,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _buildTabRow(),
              ),
              _buildPageContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVenueDropdown() {
    return Stack(
      children: [
        // The dropdown button
        InkWell(
          onTap: () {
            setState(() {
              _dropdownOpen = !_dropdownOpen;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _loadingVenues
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _getVenueName(_selectedVenue),
                        style: TextStyle(
                          fontFamily: 'Roboto Flex',
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                SizedBox(width: 4),
                Icon(
                  _dropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        // The dropdown menu
        if (_dropdownOpen)
          Positioned(
            top: 38,
            right: 0,
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildDropdownMenuItems(),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildDropdownMenuItems() {
    // If there are no venues yet, show loading
    if (_venueNames.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        )
      ];
    }
    
    List<Widget> items = [];
    
    // Add Baked option at the top if it exists
    final bakedIndex = _venueNames.indexWhere(
        (name) => name.toLowerCase() == 'baked');
    if (bakedIndex >= 0) {
      items.add(_buildDropdownItem('Baked', () {
        setState(() {
          _selectedVenue = _venueIds[bakedIndex];
          _dropdownOpen = false;
        });
      }));
    }
    
    // Add Demo option at the top if it exists
    final demoIndex = _venueNames.indexWhere(
        (name) => name.toLowerCase() == 'demo');
    if (demoIndex >= 0) {
      items.add(_buildDropdownItem('Demo', () {
        setState(() {
          _selectedVenue = _venueIds[demoIndex];
          _dropdownOpen = false;
        });
      }));
    }
    
    // Add divider if we added special venues
    if (bakedIndex >= 0 || demoIndex >= 0) {
      items.add(Divider(color: Colors.white.withOpacity(0.1), height: 1));
    }
    
    // Add all other venues
    for (int i = 0; i < _venueNames.length; i++) {
      final name = _venueNames[i];
      // Skip Baked and Demo since they're already at the top
      if (name.toLowerCase() == 'baked' || name.toLowerCase() == 'demo') {
        continue;
      }
      
      items.add(_buildDropdownItem(name, () {
        setState(() {
          _selectedVenue = _venueIds[i];
          _dropdownOpen = false;
        });
      }));
    }
    
    return items;
  }

  Widget _buildDropdownItem(String text, VoidCallback onTap) {
    final isSelected = _getVenueName(_selectedVenue) == text;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            isSelected
                ? Icon(Icons.circle, size: 8, color: Colors.white)
                : SizedBox(width: 8),
            SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Roboto Flex',
                color: Colors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabRow() {
    return Row(
      children: [
        _buildTabButton('Overview', 0),
        SizedBox(width: 8),
        _buildTabButton('Users', 1),
        SizedBox(width: 8),
        _buildTabButton('Offers', 2),
        SizedBox(width: 8),
        _buildTabButton('Leaderboard', 3),
      ],
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Roboto Flex',
            color: Colors.white,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent() {
    switch (_selectedIndex) {
      case 0: // Overview
        return _buildOverviewTab();
      case 1: // Users
        return _buildUsersTab();
      case 2: // Offers
        return Center(child: Text('Offers Content', style: TextStyle(color: Colors.white)));
      case 3: // Leaderboard
        return Center(child: Text('Leaderboard Content', style: TextStyle(color: Colors.white)));
      default:
        return const SizedBox();
    }
  }

  Widget _buildOverviewTab() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16), // Remove horizontal padding to allow widgets to handle their own padding
      child: Column(
        children: [
          VenueUserMetricsWidget(
            venueId: _selectedVenue ?? '',
            showPreviewData: false,
          ),
          SizedBox(height: 16),
          VenueCoinsMetricsWidget(
            venueId: _selectedVenue ?? '',
            showPreviewData: false,
          ),
          SizedBox(height: 16),
          VenueStatsWidget(
            venueId: _selectedVenue ?? '',
            showPreviewData: false,
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: VenueUserMetricsWidget(
        venueId: _selectedVenue ?? '',
        showPreviewData: false,
      ),
    );
  }

  // Widget to display Rewards Collected metrics
  Widget _buildRewardsCollectedWidget() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF363740),
        borderRadius: BorderRadius.circular(31.0),
      ),
      padding: EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rewards collected',
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 22),
          _buildMetricRow(
            'Monthly',
            '568',
            const Color(0xFFC5C352),
            'Coin value',
            r'$0.25',
            Colors.white,
          ),
          SizedBox(height: 7),
          _buildMetricRow(
            'Weekly',
            '154',
            const Color(0xFFBF9BF2),
            'Total Spend',
            r'$500',
            const Color(0xFFF87C58),
          ),
          SizedBox(height: 7),
          _buildMetricRow(
            'Today',
            '008',
            const Color(0xFF6FA6A0),
            '',
            '',
            Colors.white,
          ),
        ],
      ),
    );
  }

  // Widget to display Top Rewards 
  Widget _buildTopRewardsWidget() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF363740),
        borderRadius: BorderRadius.circular(31.0),
      ),
      padding: EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top rewards',
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reward',
                      style: TextStyle(
                        fontFamily: 'Roboto Flex',
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Capuccino',
                      style: TextStyle(
                        fontFamily: 'Roboto Flex',
                        color: const Color(0xFFC5C352),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildMetricRow(
            'Total orders / month',
            '154',
            const Color(0xFFBF9BF2),
            'Total Spend',
            r'$323',
            const Color(0xFFF87C58),
          ),
        ],
      ),
    );
  }

  // Widget to display Clients
  Widget _buildClientsWidget() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF363740),
        borderRadius: BorderRadius.circular(31.0),
      ),
      padding: EdgeInsets.fromLTRB(32, 32, 32, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clients',
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Customer name',
                style: TextStyle(
                  fontFamily: 'Roboto Flex',
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              Text(
                'Sessions',
                style: TextStyle(
                  fontFamily: 'Roboto Flex',
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildClientItem('Arlene McCoy'),
          _buildClientItem('Arlene McCoy'),
          _buildClientItem('Arlene McCoy'),
          _buildClientItem('Arlene McCoy'),
          SizedBox(height: 16),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                'Load more',
                style: TextStyle(
                  fontFamily: 'Roboto Flex',
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildClientItem(String name) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 15,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Roboto Flex',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Customer@email.com',
                  style: TextStyle(
                    fontFamily: 'Roboto Flex',
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '012',
            style: TextStyle(
              fontFamily: 'Roboto Flex',
              color: const Color(0xFF6FA6A0),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String leftLabel, String leftValue, Color leftValueColor, String rightLabel, String rightValue, Color rightValueColor) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                leftLabel,
                style: TextStyle(
                  fontFamily: 'Roboto Flex',
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              Text(
                leftValue,
                style: TextStyle(
                  fontFamily: 'Roboto Flex',
                  color: leftValueColor,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (rightLabel.isNotEmpty) 
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rightLabel,
                  style: TextStyle(
                    fontFamily: 'Roboto Flex',
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  rightValue,
                  style: TextStyle(
                    fontFamily: 'Roboto Flex',
                    color: rightValueColor,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
} 