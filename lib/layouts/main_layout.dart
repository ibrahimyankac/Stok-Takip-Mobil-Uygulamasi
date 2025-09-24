import 'package:flutter/material.dart';
import '../screens/products_list_page.dart';
import '../screens/stock_overview_page.dart';
import '../screens/qr_scanner_page.dart';
import '../screens/settings_page.dart';
import '../screens/add_product_page.dart';
import '../screens/create_order_page.dart';
import '../screens/daily_sales_page.dart';
import 'widgets/app_bottom_navigation.dart';
import 'widgets/app_header.dart';
import '../core/cache_manager.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final GlobalKey<State<ProductsListPage>> _productsListKey = GlobalKey<State<ProductsListPage>>();
  CacheManager? _cacheManager;

  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    _initCache();
    _pages = [
      ProductsListPage(key: _productsListKey),
      const StockOverviewPage(),
      const CreateOrderPage(),
      const QRScannerPage(),
    ];
  }

  final List<String> _titles = [
    'Ürünler',
    'Stok Durumu',
    'Sipariş Oluştur',
    'QR Kod Tara',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppHeader(
        title: _titles[_currentIndex],
      ),
      drawer: _buildDrawer(),
      body: _pages[_currentIndex],
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _saveTabIndex(index);
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory,
                    size: 48,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Stok Takip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Günlük Satışlar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DailySalesPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ayarlar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Hakkında'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Stok Takip Uygulaması',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.inventory,
        size: 48,
        color: Color(0xFF22C55E),
      ),
      children: const [
        Text('Ürünlerin stok takibini kolaylaştırmak için geliştirilmiş bir uygulamadır.'),
      ],
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_currentIndex) {
      case 0: // Ürünler sayfası
        return FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddProductPage(),
              ),
            );
            
            // Eğer ürün eklendi ise sayfayı yenile
            if (result == true && _productsListKey.currentState != null) {
              // ProductsListPage'i yenile
              (_productsListKey.currentState! as dynamic).refreshData();
            }
          },
          backgroundColor: const Color(0xFF22C55E),
          child: const Icon(Icons.add, color: Colors.white),
        );
      case 1: // Stok durumu sayfası - floating button gerekmez
        return null;
      case 2: // Sipariş oluşturma sayfası - floating button gerekmez
        return null;
      case 3: // QR tarama sayfası - Scanner'da floating button gerekmez
        return null;
      default:
        return null;
    }
  }

  Future<void> _initCache() async {
    _cacheManager = await CacheManager.getInstance();
    await _loadLastTabIndex();
  }

  Future<void> _loadLastTabIndex() async {
    if (_cacheManager != null) {
      final savedIndex = _cacheManager!.getSelectedTabIndex();
      setState(() {
        _currentIndex = savedIndex;
      });
    }
  }

  Future<void> _saveTabIndex(int index) async {
    if (_cacheManager != null) {
      await _cacheManager!.setSelectedTabIndex(index);
    }
  }
}