import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanner extends StatefulWidget {
  final Function(String) onCodeScanned;

  const QRScanner({
    super.key,
    required this.onCodeScanned,
  });

  @override
  QRScannerState createState() => QRScannerState();
}

class QRScannerState extends State<QRScanner> {
  late MobileScannerController controller;
  bool _isScanned = false;
  bool _isTorchOn = false;
  bool _isFrontCamera = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _toggleTorch() {
    setState(() {
      _isTorchOn = !_isTorchOn;
      controller.toggleTorch();
    });
  }

  void _switchCamera() {
    setState(() {
      _isFrontCamera = !_isFrontCamera;
      controller.switchCamera();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? Colors.yellow : Colors.grey,
            ),
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: Icon(
              _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
            ),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (BarcodeCapture capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isScanned) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  _isScanned = true;
                  widget.onCodeScanned(code);
                  Navigator.of(context).pop(code);
                }
              }
            },
          ),
          // Overlay con le indicazioni
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.green.withOpacity(0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Testo di istruzioni
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Point the camera at the QR code shown on the server',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
