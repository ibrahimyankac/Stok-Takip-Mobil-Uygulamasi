import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../core/responsive_helper.dart';
import 'simple_barcode_scanner.dart';

class AddProductPage extends StatefulWidget {
  final Product? product; // null ise yeni ürün, değilse düzenleme
  final String? initialBarcode; // Barkod tarayıcıdan gelen değer

  const AddProductPage({
    super.key, 
    this.product,
    this.initialBarcode,
  });

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final ProductRepository _productRepository = ProductRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final UnitRepository _unitRepository = UnitRepository();

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _priceController = TextEditingController();

  // Dropdown values
  String? _selectedCategoryId;
  String? _selectedUnitId;

  // Data lists
  List<Category> _categories = [];
  List<Unit> _units = [];

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.product != null;
    _loadData();
    _initializeForm();
  }

  void _initializeForm() {
    if (_isEditMode && widget.product != null) {
      final product = widget.product!;
      _nameController.text = product.name;
      _descriptionController.text = product.description ?? '';
      _barcodeController.text = product.barcode ?? '';
      _stockController.text = product.currentStock.toString();
      _minStockController.text = product.minStockLevel.toString();
      _priceController.text = product.currentPrice.toString();
      _selectedCategoryId = product.categoryId;
      _selectedUnitId = product.unitId;
    } else if (widget.initialBarcode != null) {
      // Barkod tarayıcıdan gelen değeri set et
      _barcodeController.text = widget.initialBarcode!;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final [categories, units] = await Future.wait([
        _categoryRepository.getAllCategories(),
        _unitRepository.getAllUnits(),
      ]);

      setState(() {
        _categories = categories as List<Category>;
        _units = units as List<Unit>;
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
      _barcodeController.text = result;
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null || _selectedUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kategori ve birim seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final product = Product(
        id: _isEditMode ? widget.product!.id : '', // Backend generates ID for new products
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        categoryId: _selectedCategoryId!,
        unitId: _selectedUnitId!,
        barcode: _barcodeController.text.trim().isEmpty 
            ? null 
            : _barcodeController.text.trim(),
        currentStock: double.parse(_stockController.text),
        minStockLevel: double.parse(_minStockController.text),
        currentPrice: double.parse(_priceController.text),
        createdAt: _isEditMode ? widget.product!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditMode) {
        await _productRepository.updateProduct(product);
      } else {
        await _productRepository.createProduct(product);
      }

      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Ürün güncellendi!' : 'Ürün eklendi!'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() => _isSaving = false);
      
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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_isEditMode ? 'Ürün Düzenle' : 'Yeni Ürün'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _showDeleteDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),
                    _buildCategoryUnitSection(),
                    const SizedBox(height: 24),
                    _buildStockPriceSection(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Temel Bilgiler',
      icon: Icons.info_outline,
      children: [
        _buildTextFormField(
          controller: _nameController,
          label: 'Ürün Adı',
          hint: 'Ürün adını girin (Türkçe karakter kullanabilirsiniz)',
          required: true,
          inputFormatters: [
            // Türkçe karakterleri kabul eden formatter
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZçÇğĞıİöÖşŞüÜ0-9\s\-_.(),]')),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ürün adı gerekli';
            }
            if (value.trim().length < 2) {
              return 'Ürün adı en az 2 karakter olmalı';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextFormField(
          controller: _descriptionController,
          label: 'Açıklama',
          hint: 'Ürün açıklaması (isteğe bağlı, Türkçe karakter kullanabilirsiniz)',
          maxLines: 3,
          inputFormatters: [
            // Türkçe karakterleri kabul eden formatter
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZçÇğĞıİöÖşŞüÜ0-9\s\-_.(),!?\n]')),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextFormField(
          controller: _barcodeController,
          label: 'Barkod',
          hint: 'Barkod numarası (isteğe bağlı)',
          keyboardType: TextInputType.number,
          suffixIcon: IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryUnitSection() {
    return _buildSection(
      title: 'Kategori ve Birim',
      icon: Icons.category_outlined,
      children: [
        // Responsive layout: küçük ekranlarda dikey, büyük ekranlarda yatay
        LayoutBuilder(
          builder: (context, constraints) {
            // Eğer genişlik 400px'den küçükse dikey düzenle
            if (constraints.maxWidth < 400) {
              return Column(
                children: [
                  _buildDropdownField<String>(
                    label: 'Kategori',
                    value: _selectedCategoryId,
                    items: _categories.map((category) => DropdownMenuItem(
                      value: category.id,
                      child: Text(
                        category.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedCategoryId = value),
                    validator: (value) {
                      if (value == null) return 'Kategori seçin';
                      return null;
                    },
                  ),
                  SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
                  _buildDropdownField<String>(
                    label: 'Birim',
                    value: _selectedUnitId,
                    items: _units.map((unit) => DropdownMenuItem(
                      value: unit.id,
                      child: Text(
                        '${unit.name} (${unit.shortName})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedUnitId = value),
                    validator: (value) {
                      if (value == null) return 'Birim seçin';
                      return null;
                    },
                  ),
                ],
              );
            } else {
              // Büyük ekranlarda yatay düzenle
              return Row(
                children: [
                  Expanded(
                    child: _buildDropdownField<String>(
                      label: 'Kategori',
                      value: _selectedCategoryId,
                      items: _categories.map((category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(
                          category.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedCategoryId = value),
                      validator: (value) {
                        if (value == null) return 'Kategori seçin';
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context)),
                  Expanded(
                    child: _buildDropdownField<String>(
                      label: 'Birim',
                      value: _selectedUnitId,
                      items: _units.map((unit) => DropdownMenuItem(
                        value: unit.id,
                        child: Text(
                          '${unit.name} (${unit.shortName})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedUnitId = value),
                      validator: (value) {
                        if (value == null) return 'Birim seçin';
                        return null;
                      },
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildStockPriceSection() {
    return _buildSection(
      title: 'Stok ve Fiyat',
      icon: Icons.inventory_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextFormField(
                controller: _stockController,
                label: 'Mevcut Stok',
                hint: '0',
                required: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    // Virgülü noktaya çevir
                    final newText = newValue.text.replaceAll(',', '.');
                    return newValue.copyWith(text: newText);
                  }),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Stok miktarı gerekli';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Geçerli sayı girin';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextFormField(
                controller: _minStockController,
                label: 'Minimum Stok',
                hint: '0',
                required: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    // Virgülü noktaya çevir
                    final newText = newValue.text.replaceAll(',', '.');
                    return newValue.copyWith(text: newText);
                  }),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Min. stok gerekli';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Geçerli sayı girin';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextFormField(
          controller: _priceController,
          label: 'Birim Fiyat (₺)',
          hint: '0.00',
          required: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              // Virgülü noktaya çevir
              final newText = newValue.text.replaceAll(',', '.');
              return newValue.copyWith(text: newText);
            }),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Fiyat gerekli';
            }
            if (double.tryParse(value) == null) {
              return 'Geçerli fiyat girin';
            }
            if (double.parse(value) < 0) {
              return 'Fiyat negatif olamaz';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF22C55E), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        hintText: hint,
        suffixIcon: suffixIcon,
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
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: '$label *',
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
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22C55E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isEditMode ? 'Güncelle' : 'Kaydet',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürünü Sil'),
        content: Text('${widget.product!.name} ürününü silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteProduct();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct() async {
    setState(() => _isSaving = true);
    
    try {
      await _productRepository.deleteProduct(widget.product!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ürün silindi!'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}