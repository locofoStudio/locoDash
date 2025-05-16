import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/landing_page_mobile.dart';
import 'backend/backend.dart';
import 'backend/firebase_options.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F2029)),
        useMaterial3: true,
        fontFamily: 'Roboto Flex',
        scaffoldBackgroundColor: const Color(0xFF1F2029),
      ),
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) {
          // Initialize with a simple error handler
          try {
            return const LandingPageMobile(venueId: 'baked');
          } catch (e) {
            print('Error initializing LandingPageMobile: $e');
            return Scaffold(
              backgroundColor: const Color(0xFF1F2029),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Loco Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Roboto Flex',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            );
          }
        }
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
