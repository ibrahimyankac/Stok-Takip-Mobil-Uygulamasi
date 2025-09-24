import 'package:flutter/material.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../core/responsive_helper.dart';

class DailySalesPage extends StatefulWidget {
  const DailySalesPage({super.key});

  @override
  State<DailySalesPage> createState() => _DailySalesPageState();
}

class _DailySalesPageState extends State<DailySalesPage> {
  final OrderRepository _orderRepository = OrderRepository();
  
  List<Order> _todaySales = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  
  DateTime _selectedDate = DateTime.now();
  double _totalDailySales = 0.0;
  int _totalOrderCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDailySales();
  }

  Future<void> _loadDailySales() async {
    setState(() => _isLoading = true);

    try {
      final sales = await _orderRepository.getOrdersByDateRange(
        startDate: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
        endDate: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59),
      );

      setState(() {
        _todaySales = sales;
        _totalDailySales = sales.fold(0.0, (sum, order) => sum + order.totalAmount);
        _totalOrderCount = sales.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Satış verileri yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshSales() async {
    setState(() => _isRefreshing = true);
    await _loadDailySales();
    setState(() => _isRefreshing = false);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF22C55E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadDailySales();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _refreshSales,
            child: _buildBody(),
          ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Günlük Satışlar',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: const Color(0xFF22C55E),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _selectDate,
          icon: const Icon(Icons.calendar_today),
          tooltip: 'Tarih Seç',
        ),
        IconButton(
          onPressed: _refreshSales,
          icon: _isRefreshing 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.refresh),
          tooltip: 'Yenile',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildDateAndSummary(),
        Expanded(child: _buildSalesList()),
      ],
    );
  }

  Widget _buildDateAndSummary() {
    final isToday = _selectedDate.day == DateTime.now().day &&
                   _selectedDate.month == DateTime.now().month &&
                   _selectedDate.year == DateTime.now().year;

    return Container(
      margin: ResponsiveHelper.getScreenPadding(context),
      padding: ResponsiveHelper.getScreenPadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isToday ? 'Bugünün Satışları' : 'Seçilen Gün Satışları',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getBodyFontSize(context),
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF22C55E),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Toplam Satış',
                  '₺${_totalDailySales.toStringAsFixed(2)}',
                  Icons.monetization_on,
                  Colors.green,
                ),
              ),
              SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context)),
              Expanded(
                child: _buildSummaryCard(
                  'Sipariş Sayısı',
                  _totalOrderCount.toString(),
                  Icons.shopping_cart,
                  const Color(0xFF22C55E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getHorizontalSpacing(context)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: ResponsiveHelper.getIconSize(context) + 4),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context) / 2),
          Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveHelper.getBodyFontSize(context) - 1,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context) / 4),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveHelper.getSubtitleFontSize(context),
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSalesList() {
    if (_todaySales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
            Text(
              'Bu tarihte satış bulunmuyor',
              style: TextStyle(
                fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getVerticalSpacing(context) / 2),
            Text(
              'Farklı bir tarih seçebilir veya yeni satış yapabilirsiniz',
              style: TextStyle(
                fontSize: ResponsiveHelper.getBodyFontSize(context),
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: ResponsiveHelper.getScreenPadding(context),
      itemCount: _todaySales.length,
      itemBuilder: (context, index) {
        final order = _todaySales[index];
        return _buildSalesCard(order);
      },
    );
  }

  Widget _buildSalesCard(Order order) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getVerticalSpacing(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: ResponsiveHelper.getScreenPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          order.orderNumber,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getBodyFontSize(context),
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(order.status),
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusText(order.status),
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getBodyFontSize(context) - 1,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(order.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₺${order.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
              
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: ResponsiveHelper.getIconSize(context) - 2,
                    color: Colors.grey[500],
                  ),
                  SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context) / 2),
                  Text(
                    order.formattedCreatedAt,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getBodyFontSize(context),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              if (order.notes?.isNotEmpty == true) ...[
                SizedBox(height: ResponsiveHelper.getVerticalSpacing(context) / 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note,
                      size: ResponsiveHelper.getIconSize(context) - 2,
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context) / 2),
                    Expanded(
                      child: Text(
                        order.notes!,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getBodyFontSize(context),
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return const Color(0xFF22C55E);
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Tamamlandı';
      case 'pending':
        return 'Bekliyor';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return 'Bilinmeyen';
    }
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sipariş Detayları',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getTitleFontSize(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: OrderDetailWidget(order: order),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OrderDetailWidget extends StatelessWidget {
  final Order order;

  const OrderDetailWidget({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getScreenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderInfo(context),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context) * 1.5),
          _buildOrderItemsList(),
        ],
      ),
    );
  }

  Widget _buildOrderInfo(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getScreenPadding(context),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Sipariş No:', order.orderNumber),
          _buildInfoRow('Durum:', _getStatusText(order.status)),
          _buildInfoRow('Tarih:', order.formattedCreatedAt),
          _buildInfoRow('Toplam Tutar:', '₺${order.totalAmount.toStringAsFixed(2)}'),
          if (order.notes?.isNotEmpty == true)
            _buildInfoRow('Notlar:', order.notes!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sipariş Ürünleri',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...?order.items?.map((item) => _buildOrderItemCard(item)),
      ],
    );
  }

  Widget _buildOrderItemCard(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? 'Bilinmeyen Ürün',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.productBarcode?.isNotEmpty == true)
                  Text(
                    'Barkod: ${item.productBarcode}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              '${item.quantity} adet',
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '₺${item.unitPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '₺${item.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Tamamlandı';
      case 'pending':
        return 'Bekliyor';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return 'Bilinmeyen';
    }
  }
}