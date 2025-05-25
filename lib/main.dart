import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'pages/landing_page.dart';
import 'backend/backend.dart';
import 'backend/firebase_options.dart';
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
      home: Builder(
          builder: (context) {
            // Initialize with a simple error handler
            return const LandingPage(venueId: 'demo');
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
