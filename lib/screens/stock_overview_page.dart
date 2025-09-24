import 'package:flutter/material.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

class StockOverviewPage extends StatefulWidget {
  const StockOverviewPage({super.key});

  @override
  State<StockOverviewPage> createState() => _StockOverviewPageState();
}

class _StockOverviewPageState extends State<StockOverviewPage> {
  final ProductRepository _productRepository = ProductRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  
  List<Product> _products = [];
  List<Category> _categories = [];
  List<Product> _lowStockProducts = [];
  
  bool _isLoading = true;
  Map<String, int> _stockStats = {
    'total': 0,
    'lowStock': 0,
    'outOfStock': 0,
    'healthy': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final [products, categories] = await Future.wait([
        _productRepository.getAllProducts(),
        _categoryRepository.getAllCategories(),
      ]);
      
      _products = products as List<Product>;
      _categories = categories as List<Category>;
      
      _calculateStats();
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
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

  void _calculateStats() {
    _lowStockProducts = _products.where((product) => product.isLowStock).toList();
    
    _stockStats = {
      'total': _products.length,
      'lowStock': _lowStockProducts.length,
      'outOfStock': _products.where((p) => p.currentStock <= 0).length,
      'healthy': _products.where((p) => !p.isLowStock && p.currentStock > 0).length,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stok İstatistikleri
            _buildStatsCards(),
            
            const SizedBox(height: 24),
            
            // Düşük Stok Uyarıları
            if (_lowStockProducts.isNotEmpty) ...[
              _buildSectionHeader(
                'Düşük Stok Uyarıları',
                Icons.warning_amber_rounded,
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildLowStockList(),
              const SizedBox(height: 24),
            ],
            
            // Kategorilere Göre Dağılım
            _buildSectionHeader(
              'Kategorilere Göre Dağılım',
              Icons.pie_chart_outline,
              const Color(0xFF22C55E),
            ),
            const SizedBox(height: 12),
            _buildCategoryDistribution(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Toplam Ürün',
            _stockStats['total'].toString(),
            Icons.inventory_2,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Düşük Stok',
            _stockStats['lowStock'].toString(),
            Icons.warning_amber_rounded,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildLowStockList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _lowStockProducts.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey[200],
        ),
        itemBuilder: (context, index) {
          final product = _lowStockProducts[index];
          final category = _categories.firstWhere(
            (cat) => cat.id == product.categoryId,
            orElse: () => Category(
              id: '',
              name: 'Bilinmeyen',
              createdAt: DateTime.now(),
            ),
          );

          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 20,
              ),
            ),
            title: Text(
              product.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              '${category.name} • ${product.stockDisplayText}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: product.currentStock <= 0 
                    ? Colors.red.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                product.currentStock <= 0 ? 'TÜKENDİ' : 'AZALDI',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: product.currentStock <= 0 ? Colors.red : Colors.orange,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryDistribution() {
    if (_categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Kategori verisi bulunamadı',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey[200],
        ),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final categoryProducts = _products
              .where((product) => product.categoryId == category.id)
              .toList();
          
          final totalProducts = categoryProducts.length;
          final lowStockCount = categoryProducts
              .where((product) => product.isLowStock)
              .length;

          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.category_outlined,
                color: Color(0xFF22C55E),
                size: 20,
              ),
            ),
            title: Text(
              category.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              '$totalProducts ürün${lowStockCount > 0 ? ' • $lowStockCount düşük stok' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: lowStockCount > 0 ? Colors.orange : Colors.grey[600],
              ),
            ),
            trailing: Text(
              totalProducts.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF22C55E),
              ),
            ),
          );
        },
      ),
    );
  }
}