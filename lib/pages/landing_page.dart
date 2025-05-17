import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/custom_code/widgets/venue_user_metrics_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/custom_code/widgets/venue_coins_metrics_widget.dart';
import '/custom_code/widgets/venue_stats_widget.dart';
import '/custom_code/widgets/venue_activity_chart_widget.dart';
import '/custom_code/widgets/venue_clients_widget.dart';
import '/custom_code/widgets/users_list_widget.dart';
import '/custom_code/widgets/venue_leaderboard_widget.dart';
import '../utils/responsive_helper.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key, required this.venueId}) : super(key: key);

  final String venueId;

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
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
      print('Loading venues from venueProgress collection...');
      
      // Get unique venueIds from venueProgress collection
      final venueProgressQuery = await FirebaseFirestore.instance
          .collectionGroup('venueProgress')
          .get();
      
      print('Found ${venueProgressQuery.docs.length} venueProgress documents');
      
      // Extract unique venueIds
      Set<String> uniqueVenueIds = {};
      
      for (var doc in venueProgressQuery.docs) {
        try {
          final data = doc.data();
          if (data.containsKey('venueId') && data['venueId'] != null) {
            String venueId = data['venueId'] as String;
            uniqueVenueIds.add(venueId);
          } else {
            debugPrint('WARNING: Document ${doc.id} missing venueId field');
          }
        } catch (docError) {
          // Per-document error handling for more precise debugging
          debugPrint('Error processing document ${doc.id}: $docError');
          // Continue processing other documents
        }
      }
      
      print('Found ${uniqueVenueIds.length} unique venueIds: ${uniqueVenueIds.toList()}');
      
      // Convert to lists for the dropdown
      List<String> venueIds = uniqueVenueIds.toList();
      
      // Sort alphabetically but ensure baked and demo are at the beginning
      venueIds.sort((a, b) {
        if (a.toLowerCase() == 'baked') return -1;
        if (b.toLowerCase() == 'baked') return 1;
        if (a.toLowerCase() == 'demo') return -1;
        if (b.toLowerCase() == 'demo') return 1;
        return a.compareTo(b);
      });
      
      setState(() {
        _venueIds = venueIds;
        _venueNames = venueIds; // Using venueId as the display name
        _loadingVenues = false;
        
        // Select first venue if none selected
        if (_selectedVenue == null || _selectedVenue!.isEmpty) {
          _selectedVenue = venueIds.first;
        }
      });
      
      print('Venues loaded. Current selected venue: $_selectedVenue');
      print('Available venues: $_venueIds');
      
    } catch (e) {
      print('Error loading venues: $e');
      setState(() {
        // Fallback to default venues if Firebase query fails
        _venueNames = ['baked', 'demo'];
        _venueIds = ['baked', 'demo'];
        _selectedVenue = 'baked';
        _loadingVenues = false;
      });
    }
  }

  // Get venue name from venue ID
  String _getVenueName(String? venueId) {
    if (venueId == null || venueId.isEmpty) return 'Select Venue';
    
    // Capitalize the first letter of the venue id for display
    return venueId.substring(0, 1).toUpperCase() + venueId.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    // Check if the screen is mobile or larger (tablet/desktop)
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);
    
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
        child: Column(
          children: [
            // Tabs row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildTabRow(),
            ),
            
            // Main content with responsive layout
            Expanded(
              child: SingleChildScrollView(
                child: isLargeScreen 
                    ? _buildDesktopLayout() 
                    : _buildMobileLayout(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mobile layout - stacked widgets
  Widget _buildMobileLayout() {
    return _buildPageContent();
  }

  // Desktop layout - grid layout matching the screenshot
  Widget _buildDesktopLayout() {
    // Different content based on selected tab
    switch (_selectedIndex) {
      case 0: // Overview
        return _buildDesktopOverviewTab();
      case 1: // Users
        return _buildDesktopUsersTab();
      case 2: // Offers
        return Center(child: Text('Offers Content', style: TextStyle(color: Colors.white)));
      case 3: // Leaderboard
        return _buildDesktopLeaderboardTab();
      default:
        return const SizedBox();
    }
  }

  // Desktop layout for overview tab - grid layout matching the screenshot
  Widget _buildDesktopOverviewTab() {
    return Padding(
      padding: EdgeInsets.all(14),
      child: Column(
        children: [
          // Top row: Users, Activity, Venue Stats
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Users widget
              Expanded(
                flex: 1,
                child: VenueUserMetricsWidget(
                  venueId: _selectedVenue ?? '',
                  showPreviewData: false,
                ),
              ),
              SizedBox(width: 14),
              // Activity widget
              Expanded(
                flex: 2,
                child: VenueActivityChartWidget(
                  venueId: _selectedVenue ?? '',
                  showPreviewData: true,
                ),
              ),
              SizedBox(width: 14),
              // Venue Stats widget
              Expanded(
                flex: 1,
                child: VenueStatsWidget(
                  venueId: _selectedVenue ?? '',
                  showPreviewData: false,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          // Bottom row: Coins distributed, Clients, Top Rewards
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coins widget
              Expanded(
                flex: 1,
                child: VenueCoinsMetricsWidget(
                  venueId: _selectedVenue ?? '',
                  showPreviewData: false,
                ),
              ),
              SizedBox(width: 14),
              // Clients widget
              Expanded(
                flex: 1,
                child: VenueClientsWidget(
                  venueId: _selectedVenue ?? '',
                  showPreviewData: true, // Use preview data to match the design
                  onNavigateToUsersTab: () {
                    setState(() {
                      _selectedIndex = 1; // Navigate to Users tab
                    });
                  },
                ),
              ),
              SizedBox(width: 14),
              // Top Rewards widget (use the existing rewards widget)
              Expanded(
                flex: 1,
                child: _buildTopRewardsWidget(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Desktop layout for users tab
  Widget _buildDesktopUsersTab() {
    return Padding(
      padding: EdgeInsets.all(14),
      child: Column(
        children: [
          // Top row: User metrics
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: VenueUserMetricsWidget(
                  venueId: _selectedVenue ?? '',
                  showPreviewData: false,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          // Bottom row: Users list
          UsersListWidget(
            venueId: _selectedVenue ?? '',
            showPreviewData: false,
            width: double.infinity,
            height: 600,
          ),
        ],
      ),
    );
  }

  // Desktop layout for leaderboard tab
  Widget _buildDesktopLeaderboardTab() {
    return Padding(
      padding: EdgeInsets.all(14),
      child: VenueLeaderboardWidget(
        venueId: _selectedVenue ?? '',
        showPreviewData: false,
        width: double.infinity,
        height: 800,
      ),
    );
  }

  // Keep the original _buildPageContent method for mobile view
  Widget _buildPageContent() {
    // Existing mobile layout code
    switch (_selectedIndex) {
      case 0: // Overview
        return _buildOverviewTab();
      case 1: // Users
        return _buildUsersTab();
      case 2: // Offers
        return Center(child: Text('Offers Content', style: TextStyle(color: Colors.white)));
      case 3: // Leaderboard
        return _buildLeaderboardTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildVenueDropdown() {
    // Define a simple list of venue options
    final List<String> venueOptions = ['baked', 'demo'];
    
    return Container(
      height: 30,
      padding: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: _loadingVenues 
          ? Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : DropdownButton<String>(
              value: _selectedVenue ?? venueOptions.first,
              icon: Icon(Icons.arrow_drop_down, color: Colors.white),
              iconSize: 24,
              elevation: 16,
              dropdownColor: Color(0xFF1F2029),
              underline: Container(height: 0),  // Remove underline
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Roboto Flex',
              ),
              hint: Text(
                'Venue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Roboto Flex',
                ),
              ),
              onChanged: (String? newValue) {
                print("Selected venue: $newValue");
                setState(() {
                  _selectedVenue = newValue;
                  // Show brief loading animation
                  _loadingVenues = true;
                });
                
                // Reset loading state after a short delay to show feedback
                Future.delayed(Duration(milliseconds: 300), () {
                  if (mounted) {
                    setState(() {
                      _loadingVenues = false;
                    });
                  }
                });
              },
              items: venueOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      value.substring(0, 1).toUpperCase() + value.substring(1),
                    ),
                  ),
                );
              }).toList(),
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

  Widget _buildOverviewTab() {
    return Padding(
      padding: EdgeInsets.all(14), // Apply consistent 14px padding on all sides
      child: Column(
        children: [
          VenueUserMetricsWidget(
            venueId: _selectedVenue ?? '',
            showPreviewData: false,
          ),
          SizedBox(height: 14),
          VenueCoinsMetricsWidget(
            venueId: _selectedVenue ?? '',
            showPreviewData: false,
          ),
          SizedBox(height: 14),
          VenueStatsWidget(
            venueId: _selectedVenue ?? '',
            showPreviewData: false,
          ),
          SizedBox(height: 14),
          VenueActivityChartWidget(
            venueId: _selectedVenue ?? '',
            showPreviewData: true, // Use preview data for reliable display
          ),
          SizedBox(height: 14),
          VenueClientsWidget(
            venueId: _selectedVenue ?? '',
            showPreviewData: false, // Use real data from Firebase
            onNavigateToUsersTab: () {
              setState(() {
                _selectedIndex = 1; // Navigate to Users tab
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Padding(
      padding: EdgeInsets.all(14),
      child: Column(
        children: [
          VenueUserMetricsWidget(
            venueId: _selectedVenue ?? '',
            showPreviewData: false,
          ),
          SizedBox(height: 14),
          UsersListWidget(
            venueId: _selectedVenue ?? '',
            showPreviewData: false,
            width: double.infinity,
            height: 700,
          ),
        ],
      ),
    );
  }

  // Add new Leaderboard tab method
  Widget _buildLeaderboardTab() {
    return Padding(
      padding: EdgeInsets.all(14),
      child: VenueLeaderboardWidget(
        venueId: _selectedVenue ?? '',
        showPreviewData: false,
        width: double.infinity,
        height: 700,
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
      margin: EdgeInsets.zero, // Remove margin as padding is now handled by the parent
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
    // Determine font size based on screen width
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);
    final valueFontSize = isLargeScreen ? 36.0 : 48.0;
    
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
                  fontSize: valueFontSize,
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
                    fontSize: valueFontSize,
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