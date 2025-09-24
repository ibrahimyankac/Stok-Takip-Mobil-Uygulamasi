import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../core/responsive_helper.dart';
import '../widgets/widgets.dart';
import 'simple_barcode_scanner.dart';

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({super.key});

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final ProductRepository _productRepository = ProductRepository();
  final OrderRepository _orderRepository = OrderRepository();

  // Form controllers
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  // Data lists
  List<Product> _products = [];
  
  // Cart state
  final List<OrderItem> _cartItems = [];
  double _totalAmount = 0.0;

  // UI state
  bool _isLoading = false;
  bool _isProcessing = false;
  String _searchQuery = '';
  bool _showProductSelector = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final products = await _productRepository.getAllProducts();

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veri yükleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const SimpleBarcodeScanner(),
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _addProductByBarcode(result);
    }
  }

  Future<void> _addProductByBarcode(String barcode) async {
    try {
      final product = _products.firstWhere(
        (p) => p.barcode == barcode,
        orElse: () => throw Exception('Barkod bulunamadı'),
      );

      if (product.currentStock <= 0) {
        throw Exception('Bu ürün stokta yok');
      }

      _addProductToCart(product, 1.0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Barkod hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addProductToCart(Product product, double quantity) {
    // Sepette var mı kontrol et
    final existingIndex = _cartItems.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingIndex >= 0) {
      // Varsa miktarı artır
      final existingItem = _cartItems[existingIndex];
      final newQuantity = existingItem.quantity + quantity;
      
      if (newQuantity > product.currentStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stok miktarını aştınız'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      _cartItems[existingIndex] = existingItem.copyWith(
        quantity: newQuantity,
        totalPrice: newQuantity * existingItem.unitPrice,
      );
    } else {
      // Yoksa yeni ekle
      if (quantity > product.currentStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stok miktarını aştınız'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final orderItem = OrderItem(
        id: '', // Temporary ID
        orderId: '', // Will be set when order is created
        productId: product.id,
        quantity: quantity,
        unitPrice: product.currentPrice,
        totalPrice: quantity * product.currentPrice,
        createdAt: DateTime.now(),
        product: product,
      );

      _cartItems.add(orderItem);
    }

    _calculateTotal();
    setState(() {});
  }

  void _updateCartItemQuantity(int index, double newQuantity) {
    if (newQuantity <= 0) {
      _removeCartItem(index);
      return;
    }

    final item = _cartItems[index];
    final product = item.product!;
    
    if (newQuantity > product.currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stok miktarını aştınız'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _cartItems[index] = item.copyWith(
      quantity: newQuantity,
      totalPrice: newQuantity * item.unitPrice,
    );

    _calculateTotal();
    setState(() {});
  }

  void _removeCartItem(int index) {
    _cartItems.removeAt(index);
    _calculateTotal();
    setState(() {});
  }

  void _calculateTotal() {
    _totalAmount = _cartItems.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
  }

  Future<void> _createOrder() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sepetiniz boş'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final order = await _orderRepository.createOrder(
        items: _cartItems,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sipariş oluşturuldu: ${order.orderNumber}'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );

        // Sepeti temizle
        _cartItems.clear();
        _totalAmount = 0.0;
        _notesController.clear();
        setState(() {});
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sipariş oluşturma hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showProductModal() {
    setState(() => _showProductSelector = true);
  }

  void _hideProductSelector() {
    setState(() {
      _showProductSelector = false;
      _quantityController.clear();
      _searchQuery = '';
    });
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    
    return _products.where((product) {
      return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (product.barcode?.contains(_searchQuery) ?? false);
    }).toList();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Yeni Sipariş'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                setState(() {
                  _cartItems.clear();
                  _totalAmount = 0.0;
                });
              },
              tooltip: 'Sepeti Temizle',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    _buildActionButtons(),
                    Expanded(
                      child: _cartItems.isEmpty
                          ? _buildEmptyCart()
                          : _buildCartList(),
                    ),
                    if (_cartItems.isNotEmpty) _buildOrderSummary(),
                  ],
                ),
                if (_showProductSelector) _buildProductSelector(),
              ],
            ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      color: Colors.white,
      padding: ResponsiveHelper.getScreenPadding(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 400) {
            return Column(
              children: [
                _buildScanButton(),
                SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
                _buildManualAddButton(),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(child: _buildScanButton()),
                SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context)),
                Expanded(child: _buildManualAddButton()),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildScanButton() {
    return ElevatedButton.icon(
      onPressed: _scanBarcode,
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text('Barkod Tara'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF22C55E),
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, ResponsiveHelper.getButtonHeight(context)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildManualAddButton() {
    return ElevatedButton.icon(
      onPressed: _showProductModal,
      icon: const Icon(Icons.add_shopping_cart),
      label: const Text('Manuel Ekle'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, ResponsiveHelper.getButtonHeight(context)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Sepetiniz Boş',
            style: TextStyle(
              fontSize: ResponsiveHelper.getTitleFontSize(context),
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ürün eklemek için barkod tarayın\nveya manuel olarak ekleyin',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveHelper.getBodyFontSize(context),
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    return ListView.builder(
      padding: ResponsiveHelper.getScreenPadding(context),
      itemCount: _cartItems.length,
      itemBuilder: (context, index) {
        return CartItemWidget(
          item: _cartItems[index],
          onQuantityChanged: (newQuantity) {
            _updateCartItemQuantity(index, newQuantity);
          },
          onRemove: () => _removeCartItem(index),
        );
      },
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      color: Colors.white,
      padding: ResponsiveHelper.getScreenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notes field
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Sipariş Notu (İsteğe Bağlı)',
              hintText: 'Sipariş hakkında not ekleyin...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF22C55E)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            maxLines: 2,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZçÇğĞıİöÖşŞüÜ0-9\s\-_.(),!?\n]')),
            ],
          ),
          
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
          
          // Total summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Toplam (${_cartItems.length} ürün):',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '₺${_totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getTitleFontSize(context),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF22C55E),
                ),
              ),
            ],
          ),
          
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
          
          // Create order button
          SizedBox(
            width: double.infinity,
            height: ResponsiveHelper.getButtonHeight(context),
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _createOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Siparişi Onayla',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelector() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            margin: ResponsiveHelper.getScreenPadding(context),
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: ResponsiveHelper.getScreenPadding(context),
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ürün Seç',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getTitleFontSize(context),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: _hideProductSelector,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                
                // Search
                Padding(
                  padding: ResponsiveHelper.getScreenPadding(context),
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Ürün ara...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                
                // Product list
                Expanded(
                  child: ListView.builder(
                    padding: ResponsiveHelper.getScreenPadding(context),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return ListTile(
                        title: Text(product.name),
                        subtitle: Text('Stok: ${product.currentStock} - ₺${product.currentPrice.toStringAsFixed(2)}'),
                        onTap: () {
                          _showQuantityDialog(product);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQuantityDialog(Product product) {
    _quantityController.text = '1';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Miktar Belirle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ürün: ${product.name}'),
            Text('Stok: ${product.currentStock}'),
            Text('Fiyat: ₺${product.currentPrice.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Miktar',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final newText = newValue.text.replaceAll(',', '.');
                  return newValue.copyWith(text: newText);
                }),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = double.tryParse(_quantityController.text);
              if (quantity != null && quantity > 0) {
                _addProductToCart(product, quantity);
                Navigator.of(context).pop();
                _hideProductSelector();
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }
}