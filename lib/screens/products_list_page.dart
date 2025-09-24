import 'package:flutter/material.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import 'add_product_page.dart';
import 'product_detail_page.dart';

class ProductsListPage extends StatefulWidget {
  const ProductsListPage({super.key});

  @override
  State<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends State<ProductsListPage> {
  final ProductRepository _productRepository = ProductRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  
  List<Product> _products = [];
  List<Category> _categories = [];
  List<Product> _filteredProducts = [];
  
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategoryId;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Public method to refresh data from parent widgets
  void refreshData() {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final [products, categories] = await Future.wait([
        _productRepository.getAllProducts(),
        _categoryRepository.getAllCategories(),
      ]);
      
      setState(() {
        _products = products as List<Product>;
        _categories = categories as List<Category>;
        _filteredProducts = _products;
        _isLoading = false;
      });
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

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesSearch = _searchQuery.isEmpty ||
            product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (product.barcode?.contains(_searchQuery) ?? false);
        
        final matchesCategory = _selectedCategoryId == null ||
            product.categoryId == _selectedCategoryId;
        
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _filterProducts();
  }

  void _onCategorySelected(String? categoryId) {
    _selectedCategoryId = categoryId;
    _filterProducts();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
              children: [
                // Search and Filters Section
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          onChanged: _onSearchChanged,
                          decoration: const InputDecoration(
                            hintText: 'Ürün ara',
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Filter Pills
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // All Categories Filter
                            _buildFilterPill(
                              'Tümü',
                              _selectedCategoryId == null,
                              () => _onCategorySelected(null),
                            ),
                            
                            const SizedBox(width: 8),
                            
                            // Category Filters
                            ..._categories.map((category) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildFilterPill(
                                category.name,
                                _selectedCategoryId == category.id,
                                () => _onCategorySelected(category.id),
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Products List
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return _buildProductCard(product);
                          },
                        ),
                ),
              ],
            );
  }

  Widget _buildFilterPill(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF22C55E) : const Color(0xFFE0F2E7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF22C55E),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final category = _categories.firstWhere(
      (cat) => cat.id == product.categoryId,
      orElse: () => Category(
        id: '',
        name: 'Bilinmeyen',
        createdAt: DateTime.now(),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.04),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(product: product),
              ),
            ).then((result) {
              if (result == true) {
                // Ürün silindi, listeyi yenile
                _loadData();
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Product Icon/Image Placeholder
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2E7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF22C55E),
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Stok: ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Flexible(
                            child: Text(
                              product.stockDisplayText,
                              style: TextStyle(
                                fontSize: 14,
                                color: product.isLowStock ? Colors.red : Colors.grey[600],
                                fontWeight: product.isLowStock ? FontWeight.w600 : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (product.isLowStock) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.warning_rounded,
                              size: 16,
                              color: Colors.red,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Price and Actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.priceDisplayText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              final result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddProductPage(product: product),
                                ),
                              );
                              if (result == true) {
                                // Ürün güncellendi, listeyi yenile
                                _loadData();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedCategoryId != null
                ? 'Arama kriterlerinize uygun ürün bulunamadı'
                : 'Henüz ürün eklenmemiş',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedCategoryId != null
                ? 'Farklı arama terimleri deneyin'
                : 'İlk ürününüzü eklemek için + butonuna dokunun',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}