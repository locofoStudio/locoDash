// Only for web
// ignore: avoid_web_libraries_in_flutter, uri_does_not_exist
import 'dart:ui_web' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;

typedef PlatformViewFactory = dynamic Function(int viewId);

void registerWebViewFactory(String viewType, PlatformViewFactory factory) {
  if (kIsWeb) {
  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(viewType, factory);
  }
} 