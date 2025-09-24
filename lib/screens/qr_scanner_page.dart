import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import 'product_detail_page.dart';
import 'add_product_page.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  late MobileScannerController _controller;
  final ProductRepository _productRepository = ProductRepository();
  
  bool _isScanning = false;
  bool _hasFoundProduct = false;
  bool _isDisposed = false;
  Product? _foundProduct;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.unrestricted, // Daha hızlı tanıma
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false, // Performans için görüntü döndürme
      formats: const [BarcodeFormat.all], // Tüm formatları destekle
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isScanning || _hasFoundProduct || _isDisposed) return;
    
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final barcode = barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    setState(() => _isScanning = true);

    try {
      // Kamerayı durduralım ki CPU kullanımı azalsın
      await _controller.stop();
      
      // Barkod ile ürün ara
      final products = await _productRepository.searchProducts(barcode);
      
      if (products.isNotEmpty && !_isDisposed) {
        // Ürün bulundu
        setState(() {
          _foundProduct = products.first;
          _hasFoundProduct = true;
          _isScanning = false;
        });
        
        
        // Scanner'ı durdur
        await _controller.stop();
        
        // Ürün detay sayfasını göster
        _showProductDetails(_foundProduct!);
      } else {
        // Ürün bulunamadı
        setState(() => _isScanning = false);
        _showNotFoundDialog(barcode);
      }
    } catch (e) {
      setState(() => _isScanning = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showProductDetails(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(product: product),
      ),
    ).then((_) {
      // ProductDetailPage'den geri dönüldüğünde scanner'ı resetle
      _resetScanner();
    });
  }

  void _showNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.search_off,
          color: Colors.orange,
          size: 48,
        ),
        title: const Text('Ürün Bulunamadı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Barkod: $barcode'),
            const SizedBox(height: 8),
            const Text(
              'Bu barkoda sahip ürün sistemde kayıtlı değil.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanner();
            },
            child: const Text('Tekrar Tara'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // AddProductPage'e barkod ile yönlendir
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddProductPage(initialBarcode: barcode),
                ),
              ).then((_) {
                _resetScanner();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Yeni Ürün Ekle'),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    if (_isDisposed) return;
    
    setState(() {
      _hasFoundProduct = false;
      _foundProduct = null;
      _isScanning = false;
    });
    
    // Kamerayı yeniden başlat
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Scanner View
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
            scanWindow: Rect.fromCenter(
              center: MediaQuery.of(context).size.center(Offset.zero),
              width: 300, // Daha büyük alan - kolay odaklanma
              height: 300,
            ),
            overlayBuilder: (context, constraints) {
              return _buildScannerOverlay();
            },
          ),
          
          // Top Controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Flash Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: _controller.toggleTorch,
                      icon: const Icon(
                        Icons.flash_on,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Camera Switch
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: _controller.switchCamera,
                      icon: const Icon(
                        Icons.flip_camera_ios,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isScanning) ...[
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ürün aranıyor...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ürün barkodunu kare içine yerleştirin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
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
          cutOutWidth: 300, // Scan window ile eşleştirdik
          cutOutHeight: 300,
        ),
      ),
    );
  }
}

// Custom Shape for QR Scanner Overlay
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