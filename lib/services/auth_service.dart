import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user's venues
  Future<List<String>> getUserVenues() async {
    if (currentUser == null) {
      throw Exception('No user is currently signed in');
    }

    final userDoc = await _firestore
        .collection('venueOwners')
        .doc(currentUser!.uid)
        .get();

    if (!userDoc.exists) {
      throw Exception('No venues found for this account');
    }

    final venues = userDoc.data()?['venues'] as List<dynamic>;
    return venues.map((venue) => venue.toString()).toList();
  }

  // Check if user has access to a specific venue
  Future<bool> hasAccessToVenue(String venueId) async {
    if (currentUser == null) {
      return false;
    }

    try {
      final venues = await getUserVenues();
      return venues.contains(venueId);
    } catch (e) {
      return false;
    }
  }
} 