import 'package:flutter/material.dart';
import '../models/models.dart';
import '../core/responsive_helper.dart';

class CartItemWidget extends StatelessWidget {
  final OrderItem item;
  final VoidCallback? onRemove;
  final Function(double)? onQuantityChanged;
  final bool isEditable;

  const CartItemWidget({
    super.key,
    required this.item,
    this.onRemove,
    this.onQuantityChanged,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getVerticalSpacing(context)),
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
        padding: ResponsiveHelper.getScreenPadding(context),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 400) {
              return _buildVerticalLayout(context);
            } else {
              return _buildHorizontalLayout(context);
            }
          },
        ),
      ),
    );
  }

  Widget _buildVerticalLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductInfo(context),
        SizedBox(height: ResponsiveHelper.getVerticalSpacing(context) * 0.5),
        _buildQuantityAndPrice(context),
        if (isEditable) ...[
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context) * 0.5),
          _buildActions(),
        ],
      ],
    );
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildProductInfo(context),
        ),
        SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context)),
        Expanded(
          flex: 2,
          child: _buildQuantityAndPrice(context),
        ),
        if (isEditable) ...[
          SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context)),
          _buildActions(),
        ],
      ],
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.product?.name ?? 'Bilinmeyen Ürün',
          style: TextStyle(
            fontSize: ResponsiveHelper.getTitleFontSize(context),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (item.product?.description != null) ...[
          const SizedBox(height: 4),
          Text(
            item.product!.description!,
            style: TextStyle(
              fontSize: ResponsiveHelper.getBodyFontSize(context),
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 4),
        Text(
          'Birim Fiyat: ${item.formattedUnitPrice}',
          style: TextStyle(
            fontSize: ResponsiveHelper.getBodyFontSize(context),
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityAndPrice(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isEditable && onQuantityChanged != null)
          _buildQuantityControls(context)
        else
          Text(
            'Miktar: ${item.formattedQuantity}',
            style: TextStyle(
              fontSize: ResponsiveHelper.getSubtitleFontSize(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            item.formattedTotalPrice,
            style: TextStyle(
              fontSize: ResponsiveHelper.getTitleFontSize(context),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF22C55E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityControls(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuantityButton(
          icon: Icons.remove,
          onPressed: () {
            if (item.quantity > 0.1) {
              onQuantityChanged?.call(item.quantity - 0.1);
            }
          },
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            item.formattedQuantity,
            style: TextStyle(
              fontSize: ResponsiveHelper.getSubtitleFontSize(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildQuantityButton(
          icon: Icons.add,
          onPressed: () {
            onQuantityChanged?.call(item.quantity + 0.1);
          },
        ),
      ],
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: const Color(0xFF22C55E),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onRemove != null)
          IconButton(
            onPressed: onRemove,
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              padding: const EdgeInsets.all(8),
            ),
          ),
      ],
    );
  }
}