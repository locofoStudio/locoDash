// Only for web
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui' as ui;

typedef PlatformViewFactory = dynamic Function(int viewId);

void registerWebViewFactory(String viewType, PlatformViewFactory factory) {
  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(viewType, factory);
} 