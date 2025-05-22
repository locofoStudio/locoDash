typedef PlatformViewFactory = dynamic Function(int viewId);

void registerWebViewFactory(String viewType, PlatformViewFactory factory) {
  // No-op on non-web platforms
} 