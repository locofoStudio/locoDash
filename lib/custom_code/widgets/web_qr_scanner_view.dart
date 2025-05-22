import 'dart:async';
import 'dart:html';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:js/js.dart';

// This is the JS interop to register a factory
@JS('window.flutterWebRenderer')
external set flutterWebRenderer(String renderer);

@JS('window.flutterCanvasKit')
external set flutterCanvasKit(Object canvasKit);

class WebQrScannerView extends StatefulWidget {
  final void Function(String code) onScan;
  const WebQrScannerView({Key? key, required this.onScan}) : super(key: key);

  @override
  State<WebQrScannerView> createState() => _WebQrScannerViewState();
}

class _WebQrScannerViewState extends State<WebQrScannerView> {
  late VideoElement _video;
  late CanvasElement _canvas;
  late DivElement _container;
  StreamSubscription<Event>? _canPlaySub;
  bool _scanning = false;
  bool _cameraStarted = false;
  String? _error;
  Timer? _scanTimer;
  final String viewType = 'web-qr-scanner-view';
  bool _viewRegistered = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initWebScanner();
    }
  }

  void _initWebScanner() {
    if (!_viewRegistered) {
      _viewRegistered = true;
      
      // Register a view factory with a unique id
      js.context.callMethod('eval', [
        '''
        if (!window.hasRegisteredView) {
          window.hasRegisteredView = true;
          const viewType = 'web-qr-scanner-view';
          const viewFactory = (viewId) => {
            const container = document.createElement('div');
            container.style.width = '100%';
            container.style.height = '100%';
            container.style.position = 'relative';
            container.style.backgroundColor = '#242529';
            container.style.borderRadius = '10px';
            container.style.overflow = 'hidden';
            
            const video = document.createElement('video');
            video.style.width = '100%';
            video.style.height = '100%';
            video.style.objectFit = 'cover';
            video.style.borderRadius = '10px';
            video.setAttribute('autoplay', 'true');
            video.setAttribute('playsinline', 'true');
            video.setAttribute('muted', 'true');
            container.appendChild(video);
            
            const canvas = document.createElement('canvas');
            canvas.style.display = 'none';
            container.appendChild(canvas);
            
            window.videoElement = video;
            window.canvasElement = canvas;
            
            navigator.mediaDevices.getUserMedia({
              video: {
                facingMode: 'environment',
                width: {ideal: 1280},
                height: {ideal: 720},
              }
            }).then(stream => {
              video.srcObject = stream;
              video.play();
            }).catch(err => {
              console.error('Camera error:', err);
              const errorDiv = document.createElement('div');
              errorDiv.innerText = 'Camera error: ' + err.message;
              errorDiv.style.color = 'red';
              errorDiv.style.textAlign = 'center';
              errorDiv.style.padding = '10px';
              container.appendChild(errorDiv);
            });
            
            return container;
          };
          
          // Register the view
          window.flutter_inappwebview = window.flutter_inappwebview || {};
          window.flutter_inappwebview[viewType] = {
            create: viewFactory
          };
        }
        '''
      ]);
      
      // Start scanning after a delay to allow the camera to initialize
      Future.delayed(Duration(seconds: 1), () {
        _startScanning();
      });
    }
  }
 
  void _startScanning() {
    if (_scanTimer != null) return;
    
    _scanTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      _scanFrame();
    });
  }

  void _scanFrame() {
    try {
      final result = js.context.callMethod('eval', [
        '''
        (function() {
          if (!window.videoElement || !window.canvasElement) return null;
          if (window.videoElement.readyState !== 4) return null;
          
          const canvas = window.canvasElement;
          const video = window.videoElement;
          
          canvas.width = video.videoWidth;
          canvas.height = video.videoHeight;
          
          const ctx = canvas.getContext('2d');
          ctx.drawImage(video, 0, 0);
          
          if (typeof jsQR === 'function') {
            const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
            const code = jsQR(imageData.data, imageData.width, imageData.height, {
              inversionAttempts: 'dontInvert'
            });
            
            if (code && code.data) {
              return code.data;
            }
          }
          return null;
        })();
        '''
      ]);
      
      if (result != null && result is String && result.isNotEmpty) {
        widget.onScan(result);
        _stopScanning();
      }
    } catch (e) {
      print('Scan error: $e');
    }
  }

  void _stopScanning() {
    _scanTimer?.cancel();
    _scanTimer = null;
    _scanning = false;
  }

  @override
  void dispose() {
    _stopScanning();
    _canPlaySub?.cancel();
    try {
      js.context.callMethod('eval', [
        '''
        if (window.videoElement && window.videoElement.srcObject) {
          const tracks = window.videoElement.srcObject.getTracks();
          tracks.forEach((track) => track.stop());
        }
        '''
      ]);
    } catch (_) {}
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
    return Container(
      width: 350,
      height: 350,
      decoration: BoxDecoration(
        color: const Color(0xFF242529),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const HtmlElementView(viewType: 'web-qr-scanner-view'),
    );
  }
} 