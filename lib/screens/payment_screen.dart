import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../utils/app_theme.dart';
import 'orders_screen.dart';

class PaymentScreen extends StatefulWidget {
  final List<Product> cartItems;
  final int subtotal;
  final VoidCallback? onPaymentSuccess;

  const PaymentScreen({
    super.key,
    required this.cartItems,
    required this.subtotal,
    this.onPaymentSuccess,
  });

  static const int kDeliveryFee = 5000;
  int get total => subtotal + kDeliveryFee;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  AppColors c = AppColors.light;
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _scrollCtrl  = ScrollController();

  bool _isLoading   = false;
  bool _orderPlaced = false;
  bool _orderSaved  = false;
  bool _openedBank  = false;
  String _orderNumber = '';

  void _markOrderPlaced() {
    widget.onPaymentSuccess?.call();
    if (mounted) setState(() => _orderPlaced = true);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedAddress();
  }

  Future<void> _loadSavedAddress() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final addr = snap.data()?['address'] as Map<String, dynamic>?;
      if (addr != null && mounted) {
        final parts = <String>[];
        if ((addr['city'] ?? '').isNotEmpty) parts.add(addr['city']);
        if ((addr['district'] ?? '').isNotEmpty) parts.add(addr['district']);
        if ((addr['khoroo'] ?? '').isNotEmpty) parts.add('${addr['khoroo']}-р хороо');
        if ((addr['street'] ?? '').isNotEmpty) parts.add(addr['street']);
        if ((addr['floor'] ?? '').isNotEmpty) parts.add('${addr['floor']}-р давхар');
        if ((addr['door'] ?? '').isNotEmpty) parts.add('${addr['door']}-р тоот');
        if (parts.isNotEmpty) setState(() => _addressCtrl.text = parts.join(', '));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _openedBank && !_orderPlaced) {
      _markOrderPlaced();
    }
  }

  String _fmt(int amount) => amount
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _currentMonth() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

  String get _txnRef {
    final phone   = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    if (phone.isEmpty && address.isEmpty) return 'OH-PENDING';
    if (phone.isNotEmpty && address.isNotEmpty) return '$phone $address';
    return phone.isNotEmpty ? phone : address;
  }

  Future<void> _confirmAndPay({bool directConfirm = false}) async {
    final phone   = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();

    if (phone.isEmpty) {
      _snack('Утасны дугаараа оруулна уу', Colors.orange);
      return;
    }
    if (address.isEmpty) {
      _snack('Хүргэлтийн хаягаа оруулна уу', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    final orderNum = 'OH-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

    try {
      await FirebaseFirestore.instance.collection('orders').add({
        'orderNumber': orderNum,
        'items': widget.cartItems.map((p) => {
              'productId':         p.id,
              'name':              p.name,
              'category':          p.category,
              'size':              p.selectedSize ?? 'M',
              'imageUrl':          p.imageUrl,
              'priceMNT':          p.discountedPriceMNT?.toInt() ?? (p.price * 1000).round(),
              'originalPriceMNT':  (p.price * 1000).round(),
            }).toList(),
        'subtotal':      widget.subtotal,
        'deliveryFee':   PaymentScreen.kDeliveryFee,
        'totalAmount':   widget.total,
        'phone':         phone,
        'address':       address,
        'txnRef':        '$phone $address',
        'paymentMethod': 'khan_bank',
        'status':        'pending',
        'userId':        FirebaseAuth.instance.currentUser?.uid ?? '',
        'createdAt':     FieldValue.serverTimestamp(),
        'month':         _currentMonth(),
      });

      setState(() { _orderNumber = orderNum; _isLoading = false; });

      if (directConfirm) { _markOrderPlaced(); return; }

      if (kIsWeb) {
        setState(() => _orderSaved = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
                duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
          }
        });
      } else {
        setState(() => _openedBank = true);
        try {
          final url = defaultTargetPlatform == TargetPlatform.iOS
              ? 'https://apps.apple.com/app/id1555908766'
              : 'https://play.google.com/store/apps/details?id=mn.khanbank.android';
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } catch (_) { _markOrderPlaced(); }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _snack('Алдаа гарлаа: $e', Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    c = context.c;
    if (_orderPlaced) return _buildSuccess();

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: const Text('Төлбөр')),
      body: SingleChildScrollView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeliveryBanner(),
            const SizedBox(height: 16),
            _buildOrderSummary(),
            const SizedBox(height: 20),

            _sectionTitle('Хүргэлтийн мэдээлэл'),
            const SizedBox(height: 12),
            _buildField(
              controller: _phoneCtrl,
              label: 'Утасны дугаар *',
              hint: '9999-9999',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            _buildField(
              controller: _addressCtrl,
              label: 'Хүргэлтийн хаяг *',
              hint: 'Дүүрэг, хороо, байр, тоот...',
              icon: Icons.location_on_outlined,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            _sectionTitle('Банкны мэдээлэл'),
            const SizedBox(height: 12),
            _buildBankCard(),
            const SizedBox(height: 32),
            _buildPayButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: TextStyle(
          color: c.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w800));

  Widget _buildDeliveryBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAF0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.6)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.local_shipping_outlined, color: Color(0xFF388E3C), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Хүргэлтийн хугацаа: 3 хоног',
                    style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                SizedBox(height: 3),
                Text('Төлбөр баталгаажсаны дараа 3 хоногт хүргэгдэнэ.',
                    style: TextStyle(
                        color: Color(0xFF388E3C), fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Захиалгын дэлгэрэнгүй',
              style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
          SizedBox(height: 12),
          ...widget.cartItems.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    // Product image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        p.imageUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: c.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.checkroom_outlined,
                              color: c.primary, size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name + size
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: TextStyle(
                                  color: c.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: c.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: c.primary.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'Хэмжээ: ${p.selectedSize ?? 'M'}',
                                  style: TextStyle(
                                      color: c.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    // Price (discounted if applicable)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_fmt(p.discountedPriceMNT?.toInt() ?? (p.price * 1000).round())}₮',
                          style: TextStyle(
                              color: c.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                        if (p.discountedPriceMNT != null)
                          Text('${_fmt((p.price * 1000).round())}₮',
                              style: TextStyle(
                                  color: c.textSecondary,
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough)),
                      ],
                    ),
                  ],
                ),
              )),
          Divider(color: c.border, height: 20),
          _sumRow('Бараа нийт', '${_fmt(widget.subtotal)}₮', c.textSecondary),
          SizedBox(height: 6),
          _sumRow('Хүргэлт', '+${_fmt(PaymentScreen.kDeliveryFee)}₮',
              const Color(0xFF388E3C)),
          Divider(color: c.border, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Нийт дүн',
                  style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
              Text('${_fmt(widget.total)}₮',
                  style: TextStyle(
                      color: c.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 22)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sumRow(String label, String value, Color vc) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(color: c.textSecondary, fontSize: 13)),
            Text(value,
                style: TextStyle(color: vc, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: c.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: c.textPrimary, fontSize: 14),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: c.textSecondary),
            prefixIcon: Icon(icon, color: c.primary, size: 20),
            filled: true,
            fillColor: c.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.primary, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildBankCard() {
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A4A8A).withValues(alpha: 0.4), width: 1.5),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1A4A8A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Text('ХААН БАНК',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 1)),
                const Spacer(),
                const Text('🇲🇳', style: TextStyle(fontSize: 22)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _copyRow('Дансны дугаар', '5619401212', copyable: true),
                const SizedBox(height: 10),
                _copyRow('Хүлээн авагч', 'Гарьд Гантөмөр'),
                const SizedBox(height: 10),
                _copyRow('Банкны нэр', 'Хаан Банк (Khan Bank)'),
                const SizedBox(height: 10),
                _copyRow('Шилжүүлэх дүн', '${_fmt(widget.total)}₮', copyable: true),
                const SizedBox(height: 10),
                _copyRow('Гүйлгээний утга', _txnRef, copyable: true),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 17),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Гүйлгээний утга талбарт утасны дугаараа заавал зөв оруулна уу.',
                          style: TextStyle(
                              color: Colors.orange, fontSize: 11, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _copyRow(String label, String value, {bool copyable = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: c.card, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.border)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: c.textSecondary, fontSize: 11)),
                SizedBox(height: 3),
                Text(value,
                    style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                _snack('$label хуулагдлаа', c.primary);
              },
              child: Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.copy_rounded, color: c.primary, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    if (_orderSaved) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.blue, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Захиалга хадгалагдлаа. Дээрх дансруу шилжүүлэлт хийгээд доорх товчийг дарна уу.',
                    style: TextStyle(color: Colors.blue, fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF388E3C),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _markOrderPlaced,
              icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
              label: const Text('Би төлбөр хийлээ',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }

    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: c.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(color: c.primary, strokeWidth: 2)),
            SizedBox(width: 10),
            Text('Хадгалж байна...',
                style: TextStyle(color: c.primary, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 64,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A4A8A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _confirmAndPay(directConfirm: false),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 18),
                  const SizedBox(height: 4),
                  const Text('Хаан Банк апп',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('${_fmt(widget.total)}₮',
                      style: const TextStyle(color: Colors.lightBlue, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 64,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF388E3C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _confirmAndPay(directConfirm: true),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                  SizedBox(height: 4),
                  Text('Төлбөр хийсэн',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('Захиалга баталгаажуулах',
                      style: TextStyle(color: Colors.lightGreenAccent, fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF388E3C).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded,
                      color: Color(0xFF388E3C), size: 60),
                ),
                SizedBox(height: 24),
                Text('Захиалга амжилттай!',
                    style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
                SizedBox(height: 10),
                Text(
                  'Таны захиалга хүлээн авагдлаа.\nТөлбөр баталгаажсаны дараа 3 хоногт хүргэгдэнэ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textSecondary, height: 1.5),
                ),
                SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Column(
                    children: [
                      _successRow(Icons.receipt_long_outlined, 'Захиалгын дугаар', _orderNumber),
                      Divider(color: c.border, height: 20),
                      _successRow(Icons.phone_outlined, 'Утас', _phoneCtrl.text.trim()),
                      Divider(color: c.border, height: 20),
                      _successRow(Icons.location_on_outlined, 'Хаяг', _addressCtrl.text.trim()),
                      Divider(color: c.border, height: 20),
                      // Ordered items with image + size
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Захиалсан бараа',
                            style: TextStyle(
                                color: c.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 10),
                      ...widget.cartItems.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    p.imageUrl,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 52,
                                      height: 52,
                                      color: c.primary.withValues(alpha: 0.1),
                                      child: Icon(Icons.checkroom_outlined,
                                          color: c.primary, size: 22),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name,
                                          style: TextStyle(
                                              color: c.textPrimary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      SizedBox(height: 3),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: c.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          'Хэмжээ: ${p.selectedSize ?? 'M'}',
                                          style: TextStyle(
                                              color: c.primary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${_fmt(p.discountedPriceMNT?.toInt() ?? (p.price * 1000).round())}₮',
                                      style: TextStyle(
                                          color: c.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                    if (p.discountedPriceMNT != null)
                                      Text('${_fmt((p.price * 1000).round())}₮',
                                          style: TextStyle(
                                              color: c.textSecondary,
                                              fontSize: 10,
                                              decoration: TextDecoration.lineThrough)),
                                  ],
                                ),
                              ],
                            ),
                          )),
                      Divider(color: c.border, height: 20),
                      _successRow(Icons.shopping_bag_outlined, 'Бараа нийт', '${_fmt(widget.subtotal)}₮'),
                      Divider(color: c.border, height: 20),
                      _successRow(Icons.local_shipping_outlined, 'Хүргэлт', '+${_fmt(PaymentScreen.kDeliveryFee)}₮'),
                      Divider(color: c.border, height: 20),
                      _successRow(Icons.payments_outlined, 'Нийт дүн', '${_fmt(widget.total)}₮'),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const OrdersScreen(standalone: true))),
                  icon: const Icon(Icons.history_rounded, color: Colors.white, size: 20),
                  label: const Text('Захиалгын түүх харах',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: c.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                    child: Text('Нүүр хуудас руу буцах',
                        style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _successRow(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, color: c.primary, size: 20),
          SizedBox(width: 12),
          Text(label,
              style: TextStyle(color: c.textSecondary, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
        ],
      );
}
