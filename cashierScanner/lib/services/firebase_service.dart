import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user data from QR scan result
  static Future<UserModel> getUserFromScan(ScanResult scanResult) async {
    try {
      print('=== CASHIER FIREBASE LOOKUP ===');
      print('Looking up docId: "${scanResult.docId}"');
      print('UserId: "${scanResult.userId}"');
      print('VenueId: "${scanResult.venueId}"');

      // Get user progress document
      final progressDoc = await _firestore
          .collection('userVenueProgress')
          .doc(scanResult.docId)
          .get();

      if (!progressDoc.exists) {
        throw Exception('User not found in venue system');
      }

      final progressData = progressDoc.data()!;
      
      // Get additional user info from users collection
      final userDoc = await _firestore
          .collection('users')
          .doc(scanResult.userId)
          .get();

      Map<String, dynamic> userData = {};
      if (userDoc.exists) {
        userData = userDoc.data()!;
      }

      // Merge data for UserModel
      final combinedData = {
        ...progressData,
        ...userData,
      };

      print('✅ User found: ${combinedData['displayName'] ?? 'Unknown'}');
      print('💰 Current coins: ${combinedData['coin'] ?? 0}');

      return UserModel.fromFirestore(
        combinedData,
        scanResult.userId,
        scanResult.venueId,
      );
    } catch (e) {
      print('❌ Error getting user: $e');
      rethrow;
    }
  }

  /// Award coins to user (same logic as dashboard)
  static Future<void> awardCoins({
    required String userId,
    required String venueId,
    required int coinsToAward,
  }) async {
    try {
      print('=== AWARDING COINS ===');
      print('User: $userId');
      print('Venue: $venueId');
      print('Coins to award: $coinsToAward');

      final docId = '$userId-$venueId';
      final docRef = _firestore.collection('userVenueProgress').doc(docId);
      
      final doc = await docRef.get();
      if (!doc.exists) {
        throw Exception('User progress not found');
      }

      final currentData = doc.data()!;
      final currentCoins = (currentData['coin'] ?? 0) as int;
      final currentCoinsFromVenue = (currentData['coinsFromVenue'] ?? 0) as int;
      
      final newCoins = currentCoins + coinsToAward;
      final newCoinsFromVenue = currentCoinsFromVenue + coinsToAward;

      // Update coins and set hasPlayed to false so user can play game
      await docRef.update({
        'coin': newCoins,
        'coinsFromVenue': newCoinsFromVenue,
        'hasPlayed': false, // Allow user to play the game
        'lastCoinUpdate': FieldValue.serverTimestamp(),
      });

      print('✅ Coins awarded successfully!');
      print('💰 New total: $newCoins coins');
      print('🎮 hasPlayed set to false - user can play game');
    } catch (e) {
      print('❌ Error awarding coins: $e');
      rethrow;
    }
  }

  /// Calculate coins from price (same logic as dashboard)
  static int calculateCoins(double priceHkd) {
    if (priceHkd <= 0) return 0;
    return (priceHkd * 0.8).ceil(); // 80% conversion rate
  }
}
