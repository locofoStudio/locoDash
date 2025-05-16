import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/landing_page_mobile.dart';
import 'backend/backend.dart';
import 'backend/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
      home: Builder(
          builder: (context) {
            // Initialize with a simple error handler
            return const LandingPageMobile(venueId: 'demo');
          },
        ),
      routes: {
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
