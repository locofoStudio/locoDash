import 'dart:async';
import 'dart:html';
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:js/js_util.dart' as js_util;

class WebQrScannerView extends StatefulWidget {
  final void Function(String code) onScan;
  const WebQrScannerView({Key? key, required this.onScan}) : super(key: key);

  @override
  State<WebQrScannerView> createState() => _WebQrScannerViewState();
}

class _WebQrScannerViewState extends State<WebQrScannerView> {
  late html.VideoElement _video;
  late html.CanvasElement _canvas;
  late html.DivElement _container;
  StreamSubscription<html.Event>? _canPlaySub;
  bool _scanning = false;
  bool _cameraStarted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initWebScanner();
    }
  }

  void _initWebScanner() {
    // Register the view factory only once
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'web-qr-scanner-view',
      (int viewId) {
        _container = html.DivElement();
        _container.style.width = '100%';
        _container.style.height = '100%';
        _container.style.position = 'relative';

        _video = html.VideoElement();
        _video.style.width = '100%';
        _video.style.borderRadius = '10px';
        _video.setAttribute('autoplay', 'true');
        _video.setAttribute('playsinline', 'true');
        _video.setAttribute('muted', 'true');
        _container.append(_video);

        _canvas = html.CanvasElement();
        _canvas.style.display = 'none';
        _container.append(_canvas);

        _startCamera();
        return _container;
      },
    );
  }

  Future<void> _startCamera() async {
    try {
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {'facingMode': 'environment'}
      });
      _video.srcObject = stream;
      await _video.play();
      _cameraStarted = true;
      _scanLoop();
    } catch (e) {
      setState(() {
        _error = 'Camera error: $e';
      });
    }
  }

  void _scanLoop() async {
    if (!_cameraStarted || _scanning) return;
    _scanning = true;
    while (mounted && _cameraStarted) {
      if (_video.readyState == html.MediaElement.HAVE_ENOUGH_DATA) {
        _canvas.width = _video.videoWidth;
        _canvas.height = _video.videoHeight;
        final ctx = _canvas.context2D;
        ctx.drawImage(_video, 0, 0);
        final imageData = ctx.getImageData(0, 0, _canvas.width!, _canvas.height!);
        final jsQR = js_util.getProperty(html.window, 'jsQR');
        if (jsQR != null) {
          final result = js_util.callMethod(jsQR, 'call', [null, imageData.data, imageData.width, imageData.height, {'inversionAttempts': 'dontInvert'}]);
          if (result != null && js_util.getProperty(result, 'data') != null && js_util.getProperty(result, 'data').toString().isNotEmpty) {
            widget.onScan(js_util.getProperty(result, 'data').toString());
            break;
          }
        }
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
    _scanning = false;
  }

  @override
  void dispose() {
    try {
      _video.srcObject?.getTracks().forEach((track) => track.stop());
    } catch (_) {}
    _canPlaySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Center(child: Text('Web QR scanner only works on web.'));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    return SizedBox(
      width: 350,
      height: 350,
      child: HtmlElementView(viewType: 'web-qr-scanner-view'),
    );
  }
} 