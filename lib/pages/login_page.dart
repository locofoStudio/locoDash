import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'landing_page.dart';
import '../utils/responsive_helper.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      final venues = await _authService.getUserVenues();
      
      if (venues.isEmpty) {
        throw Exception('No venues found for this account');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An error occurred during login';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF1F2029),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: isLargeScreen ? _buildDesktopLayout() : _buildMobileLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left side - Sign in form
        _buildSignInForm(isLargeScreen: true),
        const SizedBox(width: 155),
        // Right side - Logo and Welcome text
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.string(
              '''<svg xmlns="http://www.w3.org/2000/svg" width="199" height="199" viewBox="0 0 199 199" fill="none">
                <path d="M198.053 154.856H185.108C183.83 154.856 183.525 154.119 184.428 153.223L186.544 151.107C186.696 150.955 186.823 150.643 186.823 150.427V57.1894C186.823 56.9734 186.696 56.6684 186.544 56.5095L143.087 12.9439C142.928 12.7851 142.623 12.6643 142.407 12.6643H48.5092C48.2931 12.6643 47.988 12.7914 47.8291 12.9439L45.7256 15.0472C44.8168 15.9559 44.0796 15.6509 44.0859 14.3673L44.1368 0.95958C44.1368 0.432167 43.7046 6.92004e-05 43.1771 6.92004e-05H0.959633C0.438508 -0.00628517 0 0.425812 0 0.953225V154.456C0 154.672 0.127104 154.977 0.273273 155.136L43.7872 198.695C43.9398 198.854 44.2512 198.981 44.4673 198.981H99.5032V154.856H73.1546C72.9321 154.856 72.6271 154.729 72.4746 154.577L44.1368 126.242L44.0351 126.141V85.5236L44.1368 85.4219L72.4746 57.0878C72.6334 56.9289 72.9385 56.8018 73.1546 56.8018H112.983C113.205 56.8018 113.51 56.9289 113.663 57.0878L141.822 85.2504C141.981 85.4029 142.102 85.7079 142.102 85.9303V125.759C142.102 125.976 141.975 126.287 141.822 126.439L113.656 154.596C113.497 154.755 113.192 154.875 112.976 154.875V199H198.04C198.568 199 199 198.574 199 198.047V155.835C199 155.307 198.568 154.875 198.04 154.875L198.053 154.856Z" fill="#C5C352"/>
                </svg>''',
              width: 199,
              height: 199,
            ),
            const SizedBox(height: 27),
            const Text(
              'Welcome to Locotag',
              style: TextStyle(
                color: Color(0xFFC5C352),
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto Flex',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo and Welcome text
        SvgPicture.string(
          '''<svg xmlns="http://www.w3.org/2000/svg" width="67" height="67" viewBox="0 0 199 199" fill="none">
            <path d="M198.053 154.856H185.108C183.83 154.856 183.525 154.119 184.428 153.223L186.544 151.107C186.696 150.955 186.823 150.643 186.823 150.427V57.1894C186.823 56.9734 186.696 56.6684 186.544 56.5095L143.087 12.9439C142.928 12.7851 142.623 12.6643 142.407 12.6643H48.5092C48.2931 12.6643 47.988 12.7914 47.8291 12.9439L45.7256 15.0472C44.8168 15.9559 44.0796 15.6509 44.0859 14.3673L44.1368 0.95958C44.1368 0.432167 43.7046 6.92004e-05 43.1771 6.92004e-05H0.959633C0.438508 -0.00628517 0 0.425812 0 0.953225V154.456C0 154.672 0.127104 154.977 0.273273 155.136L43.7872 198.695C43.9398 198.854 44.2512 198.981 44.4673 198.981H99.5032V154.856H73.1546C72.9321 154.856 72.6271 154.729 72.4746 154.577L44.1368 126.242L44.0351 126.141V85.5236L44.1368 85.4219L72.4746 57.0878C72.6334 56.9289 72.9385 56.8018 73.1546 56.8018H112.983C113.205 56.8018 113.51 56.9289 113.663 57.0878L141.822 85.2504C141.981 85.4029 142.102 85.7079 142.102 85.9303V125.759C142.102 125.976 141.975 126.287 141.822 126.439L113.656 154.596C113.497 154.755 113.192 154.875 112.976 154.875V199H198.04C198.568 199 199 198.574 199 198.047V155.835C199 155.307 198.568 154.875 198.04 154.875L198.053 154.856Z" fill="#C5C352"/>
            </svg>''',
          width: 67,
          height: 67,
        ),
        const SizedBox(height: 16),
        const Text(
          'Welcome to Locotag',
          style: TextStyle(
            color: Color(0xFFC5C352),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto Flex',
          ),
        ),
        const SizedBox(height: 32),
        // Sign in form
        _buildSignInForm(isLargeScreen: false),
      ],
    );
  }

  Widget _buildSignInForm({required bool isLargeScreen}) {
    return Container(
      width: isLargeScreen ? 396 : 252,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF363740),
        borderRadius: BorderRadius.circular(31),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Sign In',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto Flex',
            ),
          ),
          const SizedBox(height: 22),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: const TextStyle(color: Color(0xFFDCDCDC)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFF525E5C)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFF525E5C)),
              ),
              filled: true,
              fillColor: Colors.transparent,
            ),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 19),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: const TextStyle(color: Color(0xFFDCDCDC)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFF525E5C)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFF525E5C)),
              ),
              filled: true,
              fillColor: Colors.transparent,
            ),
            style: const TextStyle(color: Colors.white),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE86526),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
              shadowColor: const Color(0xFF1F2029),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Sign in',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFB8C5CD),
                      fontFamily: 'Roboto Flex',
                    ),
                  ),
          ),
        ],
      ),
    );
  }
} 