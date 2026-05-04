import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/app_theme.dart';
import 'payment_screen.dart';

class CartScreen extends StatefulWidget {
  final List<Product> cartItems;
  final Function(int) onRemove;
  final VoidCallback? onPaymentSuccess;

  const CartScreen({
    super.key,
    required this.cartItems,
    required this.onRemove,
    this.onPaymentSuccess,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  AppColors c = AppColors.light;
  static const int kDeliveryFee = 5000;

  int _toMNT(double price) => (price * 1000).round();

  String _fmt(int amount) => amount
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  int get _subtotal =>
      widget.cartItems.fold(0, (sum, p) => sum + _toMNT(p.price));
  int get _total => _subtotal + kDeliveryFee;

  @override
  Widget build(BuildContext context) {
    c = context.c;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Миний сагс'),
      ),
      body: widget.cartItems.isEmpty ? _buildEmpty() : _buildCart(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_bag_outlined,
                color: c.primary, size: 48),
          ),
          SizedBox(height: 20),
          Text('Сагс хоосон байна',
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('Бараа нэмж эхлээрэй',
              style: TextStyle(color: c.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildCart() {
    return Column(
      children: [
        // Delivery info banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FAF0),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.6)),
          ),
          child: const Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: Color(0xFF388E3C), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Хүргэлт 2–3 ажлын өдрийн дотор. Хүргэлтийн үнэ: 5,000₮',
                  style: TextStyle(
                      color: Color(0xFF2E7D32), fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ),

        // Items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.cartItems.length,
            itemBuilder: (_, i) {
              final item = widget.cartItems[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: Row(
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(14)),
                      child: Container(
                        width: 90,
                        height: 90,
                        color: Colors.white,
                        child: Image.asset(
                          item.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(Icons.checkroom,
                                color: c.primary, size: 36),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name,
                                style: TextStyle(
                                    color: c.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: c.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(item.category,
                                  style: TextStyle(
                                      color: c.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                            ),
                            SizedBox(height: 8),
                            Text('${_fmt(_toMNT(item.price))}₮',
                                style: TextStyle(
                                    color: c.primary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                    // Delete
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          color: c.textSecondary, size: 22),
                      onPressed: () {
                        widget.onRemove(i);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Summary
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4))
            ],
          ),
          child: Column(
            children: [
              _summaryRow('Бараа нийт', '${_fmt(_subtotal)}₮',
                  c.textSecondary),
              SizedBox(height: 8),
              _summaryRow('Хүргэлт (2–3 хоног)',
                  '+${_fmt(kDeliveryFee)}₮', const Color(0xFF388E3C)),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: c.border),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Нийт дүн',
                      style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                  Text('${_fmt(_total)}₮',
                      style: TextStyle(
                          color: c.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentScreen(
                      cartItems: widget.cartItems,
                      subtotal: _subtotal,
                      onPaymentSuccess: widget.onPaymentSuccess,
                    ),
                  ),
                ),
                child: const Text('Төлбөр хийх',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: c.textSecondary, fontSize: 14)),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      );
}
