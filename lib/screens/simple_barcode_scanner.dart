import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SimpleBarcodeScanner extends StatefulWidget {
  const SimpleBarcodeScanner({super.key});

  @override
  State<SimpleBarcodeScanner> createState() => _SimpleBarcodeScannerState();
}

class _SimpleBarcodeScannerState extends State<SimpleBarcodeScanner> {
  late MobileScannerController _controller;
  bool _hasScanned = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.unrestricted, // Daha hızlı tanıma
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false, // Performans artışı
      formats: const [BarcodeFormat.all], // Tüm barkod formatları
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasScanned || _isDisposed) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    setState(() => _hasScanned = true);
    
    // Kamerayı kapat ve barkodu geri döndür
    _controller.stop().then((_) {
      if (!_isDisposed && mounted) {
        Navigator.of(context).pop(barcode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Barkod Tara'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            onPressed: _controller.toggleTorch,
            icon: const Icon(Icons.flash_on),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
            scanWindow: Rect.fromCenter(
              center: MediaQuery.of(context).size.center(Offset.zero),
              width: 350, // Daha büyük alan
              height: 200, // Biraz daha yüksek
            ),
            overlayBuilder: (context, constraints) {
              return _buildScannerOverlay();
            },
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Barkodu kare içine yerleştirin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderColor: const Color(0xFF22C55E),
          borderRadius: 16,
          borderLength: 30,
          borderWidth: 4,
          cutOutWidth: 350, // Scan window ile eşleştirdik  
          cutOutHeight: 200,
        ),
      ),
    );
  }
}

// Scanner overlay shape - QR tarama sayfasından kopyalıyoruz
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutWidth;
  final double cutOutHeight;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutWidth = 320,
    this.cutOutHeight = 180,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderWidthSize = width / 2;
    final borderOffset = borderWidth / 2;
    final adjustedBorderLength = borderLength > cutOutWidth / 2 + borderWidth * 2
        ? borderWidthSize / 2
        : borderLength;
    final adjustedCutOutWidth = cutOutWidth < width ? cutOutWidth : width - borderOffset;
    final adjustedCutOutHeight = cutOutHeight < height ? cutOutHeight : height - borderOffset;

    final backgroundPath = Path()
      ..addRect(rect)
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.center,
            width: adjustedCutOutWidth + borderOffset,
            height: adjustedCutOutHeight + borderOffset,
          ),
          Radius.circular(borderRadius),
        ),
      )
      ..fillType = PathFillType.evenOdd;
    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(backgroundPath, backgroundPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final top = rect.center.dy - adjustedCutOutHeight / 2;
    final left = rect.center.dx - adjustedCutOutWidth / 2;
    final right = rect.center.dx + adjustedCutOutWidth / 2;
    final bottom = rect.center.dy + adjustedCutOutHeight / 2;

    // Draw the four corner lines
    canvas.drawPath(
      Path()
        ..moveTo(left, top + adjustedBorderLength)
        ..quadraticBezierTo(left, top, left + borderRadius, top)
        ..lineTo(left + adjustedBorderLength, top),
      borderPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(right - adjustedBorderLength, top)
        ..quadraticBezierTo(right, top, right, top + borderRadius)
        ..lineTo(right, top + adjustedBorderLength),
      borderPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(right, bottom - adjustedBorderLength)
        ..quadraticBezierTo(right, bottom, right - borderRadius, bottom)
        ..lineTo(right - adjustedBorderLength, bottom),
      borderPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(left + adjustedBorderLength, bottom)
        ..quadraticBezierTo(left, bottom, left, bottom - borderRadius)
        ..lineTo(left, bottom - adjustedBorderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}