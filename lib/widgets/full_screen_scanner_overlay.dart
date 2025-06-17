/// Full-screen overlay that shows the existing HTML5 QR-scanner page inside an iframe.
/// Web-only. On receiving a postMessage `{type: 'qr_scanned', data: <code>}` it
/// pops itself from the Navigator and returns the scanned string.
library;

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../custom_code/widgets/web_view_registry.dart';

class FullScreenScannerOverlay extends StatefulWidget {
  const FullScreenScannerOverlay({super.key});

  @override
  State<FullScreenScannerOverlay> createState() => _FullScreenScannerOverlayState();
}

class _FullScreenScannerOverlayState extends State<FullScreenScannerOverlay> {
  /// Ensure the view factory is registered only once.
  static bool _viewFactoryRegistered = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _registerViewFactoryOnce();
      html.window.addEventListener('message', _onMessage);
    }
  }

  void _registerViewFactoryOnce() {
    if (_viewFactoryRegistered) return;
    _viewFactoryRegistered = true;

    registerWebViewFactory('qr-scanner-frame', (int viewId) {
      final currentPath = html.window.location.pathname ?? '/';
      final base = currentPath.startsWith('/dashboard') ? '/dashboard/' : '/';
      final iframe = html.IFrameElement()
        ..src = '${base}qr_scanner_standalone.html'
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%';
      return iframe;
    });
  }

  void _onMessage(html.Event event) {
    if (!mounted) return;
    if (event is html.MessageEvent) {
      final data = event.data;
      if (data is Map) {
        if (data['type'] == 'qr_scanned') {
          final String? code = data['data']?.toString();
          Navigator.of(context).pop(code);
        } else if (data['type'] == 'qr_cancel') {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      html.window.removeEventListener('message', _onMessage);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If not on web, show empty container – this widget is web-exclusive.
    if (!kIsWeb) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Scan QR Code'),
      ),
      body: const HtmlElementView(viewType: 'qr-scanner-frame'),
    );
  }
} 