// LANDING PAGE MODIFICATIONS FOR WALLET PASS INTEGRATION
// File: /lib/pages/landing_page.dart

// ========================================
// 1. ADD IMPORT AT THE TOP OF THE FILE
// ========================================
// Add this import after the existing imports:
import '/custom_code/widgets/wallet_pass_designer_widget.dart';

// ========================================
// 2. MODIFY _buildTabRow() METHOD
// ========================================
// Find the _buildTabRow() method (around line 703) and replace it with:
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

// ========================================
// 3. MODIFY _buildDesktopLayout() METHOD
// ========================================
// Find the _buildDesktopLayout() method and update the switch statement:
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

// ========================================
// 4. MODIFY _buildMobileLayout() METHOD
// ========================================
// Find the _buildMobileLayout() method and update the switch statement:
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

// ========================================
// 5. ADD NEW METHODS AT THE END OF THE CLASS
// ========================================
// Add these methods before the closing brace of the _LandingPageState class:

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

// ========================================
// SUMMARY OF CHANGES:
// ========================================
// 1. Added import for WalletPassDesignerWidget
// 2. Added "Wallet Pass" tab button to _buildTabRow()
// 3. Added case 4 to _buildDesktopLayout() switch
// 4. Added case 4 to _buildMobileLayout() switch
// 5. Added _buildDesktopWalletPassTab() method
// 6. Added _buildWalletPassTab() method
//
// These changes will add a new "Wallet Pass" tab that shows the 
// pass designer widget when a venue is selected.
