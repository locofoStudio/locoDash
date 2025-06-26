# Anonymous User System & Google Review Updates

## Overview
This document outlines the comprehensive updates made to the dashboard widgets to support the new anonymous user tracking system and Google review management functionality.

## Anonymous User Identification Method

**Key Approach**: Anonymous users are identified by `userType = "anonymous"` in the `userVenueProgress` collection.

**Implementation Logic**:
1. **Filter by Venue First**: Query `userVenueProgress` collection where `venueId = selectedVenue` to get all venue activity
2. **Check User Type**: Use the `userType` field directly from each document to identify anonymous users
3. **Get User ID**: Use the `userId` field directly from the document data (no parsing needed)
4. **Access User Data**: Get conversion status, session count, and coins from the `users` collection using the `userId`

**Database Structure**:
- **userVenueProgress documents** contain: `userId`, `userType`, `venueId`, and activity data
- **Anonymous users** have `userType: "anonymous"` and `displayName: "Guest"` in the users collection
- **Document IDs** are NOT in "uid-venueId" format - use the `userId` field instead

**Benefits**:
- Direct field access without document ID parsing
- Clear separation between user types
- Reliable and performant queries
- Easier to maintain and debug

## New Features Added

### 1. Anonymous User Analytics Widget
**File**: `lib/custom_code/widgets/anonymous_user_analytics_widget.dart`

**Purpose**: Track anonymous user behavior and conversion patterns at venues.

**Key Metrics Displayed**:
- Total anonymous users with venue activity
- Conversion rate (anonymous → registered)
- Conversion status breakdown (converted, pending, abandoned)
- Average session count per anonymous user
- Total coins earned by anonymous users

**Database Queries**:
- `userVenueProgress` collection: `WHERE venueId == selectedVenue` to get all venue activity first
- Check `userType` field directly to identify anonymous users (`userType == 'anonymous'`)
- Use `userId` field directly from document data (no parsing needed)
- `users` collection: Individual lookups for conversion status, session count, and coins

### 2. Google Review Management Widget
**File**: `lib/custom_code/widgets/google_review_management_widget.dart`

**Purpose**: Manage Google review links and coin images for venues.

**Features**:
- View current review link and coin image status
- Edit mode with form inputs for both fields
- Save/cancel functionality
- Visual status indicators (configured/not set)

**Database Operations**:
- Reads from `venues` collection: `reviewLink` and `coinImage` fields
- Updates venue documents with new review link and coin image URLs

## Updated Existing Widgets

### 1. Venue User Metrics Widget
**File**: `lib/custom_code/widgets/venue_user_metrics_widget.dart`

**Changes Made**:
- Added anonymous user tracking alongside registered users
- Split display into two columns: "Registered Users" and "Anonymous Users"
- Updated database queries to use `userVenueProgress` collection
- Added `userType` field checking to categorize users
- Enhanced metrics to show both user types separately

**New Metrics**:
- Monthly/Weekly/Daily/Total counts for both registered and anonymous users
- Visual distinction using opacity for anonymous user metrics

### 2. Venue Stats Widget
**File**: `lib/custom_code/widgets/venue_stats_widget.dart`

**Changes Made**:
- Maintained existing `userVenueProgress` collection usage
- Maintained existing functionality with database structure

### 3. Venue Coins Metrics Widget
**File**: `lib/custom_code/widgets/venue_coins_metrics_widget.dart`

**Changes Made**:
- Maintained existing `userVenueProgress` collection usage
- Maintained existing coin tracking functionality

### 4. Venue Activity Chart Widget
**File**: `lib/custom_code/widgets/venue_activity_chart_widget.dart`

**Changes Made**:
- Maintained existing `userVenueProgress` collection usage
- Enhanced anonymous user tracking in daily activity charts
- Improved user categorization logic

### 5. Users List Widget
**File**: `lib/custom_code/widgets/users_list_widget.dart`

**Changes Made**:
- Maintained existing `userVenueProgress` collection usage
- Maintained existing user listing and CSV export functionality

## Database Schema Changes Supported

### Users Collection New Fields
```javascript
{
  userType: "anonymous" | "email" | "google" | "apple",
  displayName: "Guest" | actualName,
  userId: uid, // Always equals uid field
  conversionStatus: "pending" | "converted" | "abandoned",
  anonymousCreatedAt: timestamp,
  sessionCount: number,
  totalCoinsEarned: number
}
```

### UserVenueProgress Collection Changes
```javascript
{
  venueId: string, // Now top-level field
  userType: string, // Now top-level field
  // ... existing fields
}
```

### Venues Collection New Fields
```javascript
{
  reviewLink: string, // Google review URL (optional)
  coinImage: string   // Venue coin image URL (optional)
}
```

## Key Queries Implemented

### Anonymous User Analytics
```javascript
// First, get all venue activity (ALWAYS filter by venueId)
db.collection('userVenueProgress')
  .where('venueId', '==', venueId)

// For each document, check userType field directly
if (doc.data().userType === 'anonymous') {
  const userId = doc.data().userId; // Get userId from document data
  
  // Get user details from users collection
  db.collection('users')
    .doc(userId)
    .get()
    // Access conversionStatus, sessionCount, totalCoinsEarned
}
```

### Google Review Management
```javascript
// Get venue review data
db.collection('venues').doc(venueId).get()

// Update venue review data
db.collection('venues').doc(venueId).update({
  reviewLink: url,
  coinImage: imageUrl
})
```

### Enhanced User Metrics
```javascript
// Get all venue progress with user type tracking
db.collection('userVenueProgress')
  .where('venueId', '==', venueId)
  // Then filter by userType in application logic
```

## Widget Index Updates
**File**: `lib/custom_code/widgets/index.dart`

Added exports for new widgets:
- `anonymous_user_analytics_widget.dart`
- `google_review_management_widget.dart`

## Usage Recommendations

### Dashboard Integration
1. **Anonymous User Analytics Widget**: Place prominently to monitor conversion funnel
2. **Google Review Management Widget**: Include in venue settings/configuration section
3. **Updated User Metrics**: Use to compare registered vs anonymous user engagement

### Monitoring Key Metrics
1. **Conversion Rate**: Track anonymous to registered user conversion
2. **Anonymous Engagement**: Monitor session counts and coin earnings
3. **Review Coverage**: Track which venues have review links configured

### Future Enhancements
1. **Conversion Triggers**: Add functionality to track what causes anonymous users to register
2. **Review Analytics**: Track review link click-through rates
3. **Coin Image Management**: Add image upload functionality
4. **Anonymous User Journey**: Detailed funnel analysis from first visit to conversion

## Testing Recommendations

### Data Validation
1. Verify anonymous user counts match actual database records
2. Test conversion status updates and tracking
3. Validate Google review link and coin image updates

### Performance Testing
1. Test widget performance with large numbers of anonymous users
2. Verify query efficiency with new collection structure
3. Monitor dashboard load times with additional widgets

### User Experience Testing
1. Test edit mode functionality in Google Review Management widget
2. Verify responsive design of split user metrics display
3. Test error handling for missing venue data

## Deployment Notes

### Database Migration
- Ensure `userVenueProgress` collection exists with proper indexes
- Verify `userType` field is populated for existing records
- Add `reviewLink` and `coinImage` fields to venues collection

### Widget Registration
- Import new widgets in FlutterFlow
- Configure widget parameters and styling
- Test widget integration in dashboard layouts

### Monitoring
- Set up alerts for anonymous user conversion rates
- Monitor query performance on new collection structure
- Track usage of Google review management features 