import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/landing_page.dart';
import 'pages/login_page.dart';
import 'pages/cashier_scanner_page.dart';

import 'backend/backend.dart';
import 'backend/firebase_options.dart';
import 'services/auth_service.dart';
// ignore: avoid_web_libraries_in_flutter

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set URL strategy for web platform
  usePathUrlStrategy();
  
  bool firebaseInitialized = false;
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await Backend.initialize();
    firebaseInitialized = true;
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  
  runApp(MyApp(firebaseInitialized: firebaseInitialized));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  
  const MyApp({super.key, this.firebaseInitialized = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loco Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto Flex',
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => firebaseInitialized
            ? const LoginPage()
            : const Center(child: Text('Error initializing Firebase')),
        '/dashboard': (context) => firebaseInitialized
            ? const DashboardWrapper()
            : const Center(child: Text('Error initializing Firebase')),
        '/cashier': (context) => firebaseInitialized
            ? const CashierScannerPage()
            : const Center(child: Text('Error initializing Firebase')),
        'UsersPageMobile': (context) => const Scaffold(
          backgroundColor: Color(0xFF1F2029),
          body: Center(
            child: Text(
              'Users Page Coming Soon',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Roboto Flex',
                fontSize: 24,
              ),
            ),
          ),
        ),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  String? _selectedVenueId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasData) {
          // User is signed in - show dashboard
          if (_selectedVenueId == null) {
            // Load user's venues and select the first one
            _loadUserVenues();
            return const Center(child: CircularProgressIndicator());
          }
          
          // Show dashboard for authenticated users
          return LandingPage(venueId: _selectedVenueId!);
        }
        
        // User is not signed in
        return const LoginPage();
      },
    );
  }

  Future<void> _loadUserVenues() async {
    try {
      final venues = await _authService.getUserVenues();
      if (venues.isNotEmpty) {
        setState(() {
          _selectedVenueId = venues[0];
        });
      }
    } catch (e) {
      // Handle error - maybe show error message or sign out
      await _authService.signOut();
    }
  }
}

// Wrapper specifically for dashboard route
class DashboardWrapper extends StatefulWidget {
  const DashboardWrapper({super.key});

  @override
  State<DashboardWrapper> createState() => _DashboardWrapperState();
}

class _DashboardWrapperState extends State<DashboardWrapper> {
  final AuthService _authService = AuthService();
  String? _selectedVenueId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasData) {
          if (_selectedVenueId == null) {
            _loadUserVenues();
            return const Center(child: CircularProgressIndicator());
          }
          return LandingPage(venueId: _selectedVenueId!);
        }
        
        return const LoginPage();
      },
    );
  }

  Future<void> _loadUserVenues() async {
    try {
      final venues = await _authService.getUserVenues();
      if (venues.isNotEmpty) {
        setState(() {
          _selectedVenueId = venues[0];
        });
      }
    } catch (e) {
      await _authService.signOut();
    }
  }
}
