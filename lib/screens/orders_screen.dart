import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_theme.dart';

class OrdersScreen extends StatefulWidget {
  final bool standalone;
  const OrdersScreen({super.key, this.standalone = false});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  AppColors c = AppColors.light;

  DateTime _deadline(DateTime from) {
    final d = from.add(const Duration(days: 3));
    return DateTime(d.year, d.month, d.day);
  }

  String _fmtDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  String _fmt(int v) => v
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    c = context.c;
    final user = FirebaseAuth.instance.currentUser;
    final uid  = user?.uid ?? '';

    final body = StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: c.primary));
        }

        final docs = (snap.data?.docs ?? [])
          ..sort((a, b) {
            final at = (a.data() as Map)['createdAt'] as Timestamp?;
            final bt = (b.data() as Map)['createdAt'] as Timestamp?;
            if (at == null && bt == null) return 0;
            if (at == null) return 1;
            if (bt == null) return -1;
            return bt.compareTo(at);
          });

        int totalSpent = 0;
        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          final s = data['status'] as String? ?? '';
          if (s == 'accepted' || s == 'delivered') {
            totalSpent += (data['totalAmount'] as num?)?.toInt() ?? 0;
          }
        }

        return Column(
          children: [
            _buildHeader(context, uid, user, docs.length, totalSpent),
            docs.isEmpty
                ? Expanded(child: _buildEmpty(context))
                : Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      itemCount: docs.length,
                      itemBuilder: (ctx, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        return _OrderCard(
                          data: data,
                          fmt: _fmt,
                          fmtDate: _fmtDate,
                          deadline: _deadline,
                        );
                      },
                    ),
                  ),
          ],
        );
      },
    );

    if (widget.standalone) {
      return Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(title: const Text('Захиалгын түүх')),
        body: body,
      );
    }
    return body;
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_bag_outlined,
                color: c.primary, size: 44),
          ),
          SizedBox(height: 20),
          Text('Захиалга байхгүй байна',
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('Бараа захиалсны дараа\nэнд харагдана',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String uid, User? user,
      int orderCount, int totalSpent) {
    return FutureBuilder<DocumentSnapshot>(
      future: uid.isNotEmpty
          ? FirebaseFirestore.instance.collection('users').doc(uid).get()
          : null,
      builder: (ctx, snap) {
        final data      = snap.data?.data() as Map<String, dynamic>?;
        final displayId = data?['userDisplayId'] as String? ??
            (uid.length >= 6 ? 'U-${uid.substring(0, 6).toUpperCase()}' : 'U-???');
        final name  = data?['displayName'] as String? ?? user?.displayName ?? '';
        final email = data?['email'] as String? ?? user?.email ?? '';
        final initial = name.isNotEmpty
            ? name[0].toUpperCase()
            : email.isNotEmpty
                ? email[0].toUpperCase()
                : '?';

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          color: c.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long_rounded,
                      color: c.primary, size: 18),
                  SizedBox(width: 8),
                  Text('Захиалгын түүх',
                      style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
              SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(initial,
                            style: TextStyle(
                                color: c.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (name.isNotEmpty)
                            Text(name,
                                style: TextStyle(
                                    color: c.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          Text(email,
                              style: TextStyle(color: c.textSecondary, fontSize: 11),
                              overflow: TextOverflow.ellipsis),
                          SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: c.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('ID: $displayId',
                                style: TextStyle(
                                    color: c.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$orderCount захиалга',
                            style: TextStyle(
                                color: c.textSecondary, fontSize: 11)),
                        SizedBox(height: 4),
                        Text('${_fmt(totalSpent)}₮',
                            style: TextStyle(
                                color: c.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        Text('нийт зарцуулсан',
                            style: TextStyle(color: c.textSecondary, fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _OrderCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String Function(int) fmt;
  final String Function(DateTime) fmtDate;
  final DateTime Function(DateTime) deadline;

  const _OrderCard({
    required this.data,
    required this.fmt,
    required this.fmtDate,
    required this.deadline,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  AppColors c = AppColors.light;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    c = context.c;
    final status    = widget.data['status'] as String? ?? 'pending';
    final createdAt = (widget.data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final dl        = widget.deadline(createdAt);
    final now       = DateTime.now();
    final today     = DateTime(now.year, now.month, now.day);
    final daysLeft  = dl.difference(today).inDays;
    final items     = (widget.data['items'] as List<dynamic>?) ?? [];
    final total     = (widget.data['totalAmount'] as num?)?.toInt() ?? 0;
    final subtotal  = (widget.data['subtotal'] as num?)?.toInt() ?? 0;
    final delivery  = (widget.data['deliveryFee'] as num?)?.toInt() ?? 5000;
    final orderNum  = widget.data['orderNumber'] as String? ?? '';
    final phone     = widget.data['phone'] as String? ?? '';
    final address   = widget.data['address'] as String? ?? '';

    // ── Status config ─────────────────────────────────────────────────────────
    Color sc; String sl; IconData si;
    switch (status) {
      case 'accepted':
        sc = const Color(0xFF4CAF50); sl = 'Баталгаажсан'; si = Icons.check_circle_rounded;
        break;
      case 'delivered':
        sc = const Color(0xFF26C6DA); sl = 'Хүргэгдсэн'; si = Icons.done_all_rounded;
        break;
      case 'removed':
        sc = const Color(0xFFEF5350); sl = 'Цуцлагдсан'; si = Icons.cancel_rounded;
        break;
      default:
        sc = const Color(0xFFFF9800); sl = 'Хүлээгдэж байна'; si = Icons.schedule_rounded;
    }

    // ── Delivery info ─────────────────────────────────────────────────────────
    String deliveryLine;
    Color  deliveryColor;
    String? daysChip;

    if (status == 'delivered') {
      deliveryLine  = 'Амжилттай хүргэгдсэн';
      deliveryColor = const Color(0xFF26C6DA);
    } else if (status == 'removed') {
      deliveryLine  = 'Захиалга цуцлагдсан';
      deliveryColor = const Color(0xFFEF5350);
    } else if (status == 'accepted') {
      deliveryLine  = 'Хүргэлт: ${_fmtDateFull(dl)}';
      deliveryColor = const Color(0xFF4CAF50);
      daysChip      = daysLeft > 0 ? '$daysLeft өдөр' : 'Өнөөдөр';
    } else if (daysLeft < 0) {
      deliveryLine  = 'Хүргэлт: ${_fmtDateFull(dl)}';
      deliveryColor = const Color(0xFFEF5350);
      daysChip      = 'Хоцорсон';
    } else if (daysLeft == 0) {
      deliveryLine  = 'Өнөөдөр хүргэгдэх';
      deliveryColor = const Color(0xFFFF9800);
      daysChip      = 'Өнөөдөр';
    } else {
      deliveryLine  = 'Хүргэлт: ${_fmtDateFull(dl)}';
      deliveryColor = const Color(0xFFFF9800);
      daysChip      = '$daysLeft өдөр';
    }

    final cardBg = Theme.of(context).colorScheme.surface;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final dividerColor = Theme.of(context).dividerColor;
    final itemBg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2A2A)
        : c.card;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sc.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [

          // ── Header ──────────────────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: sc.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(si, color: sc, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(orderNum,
                            style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        Text(_fmtDateFull(createdAt),
                            style: TextStyle(color: textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sc.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sc.withValues(alpha: 0.5)),
                    ),
                    child: Text(sl,
                        style: TextStyle(
                            color: sc,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: textSecondary, size: 20),
                ],
              ),
            ),
          ),

          // ── Delivery banner (always visible) ─────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: deliveryColor.withValues(alpha: 0.08),
              border: Border(
                bottom: BorderSide(color: dividerColor),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  status == 'delivered'
                      ? Icons.check_circle_outline_rounded
                      : Icons.local_shipping_outlined,
                  color: deliveryColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(deliveryLine,
                      style: TextStyle(
                          color: deliveryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ),
                if (daysChip != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: deliveryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(daysChip,
                        style: TextStyle(
                            color: deliveryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

          // ── Collapsible body ─────────────────────────────────────────────
          if (_expanded) ...[

            // Items
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined,
                          color: c.primary, size: 14),
                      const SizedBox(width: 6),
                      Text('${items.length} бараа',
                          style: TextStyle(
                              color: textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...items.map((item) => _buildItemRow(item, itemBg, textPrimary, textSecondary)),
                ],
              ),
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Divider(color: dividerColor, height: 1),
            ),

            // Pricing
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                children: [
                  _priceRow(Icons.checkroom_outlined, 'Бараа нийт',
                      '${widget.fmt(subtotal)}₮', textSecondary),
                  const SizedBox(height: 6),
                  _priceRow(Icons.local_shipping_outlined, 'Хүргэлт',
                      '+${widget.fmt(delivery)}₮', const Color(0xFF388E3C)),
                  SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: c.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Нийт төлсөн',
                            style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        Text('${widget.fmt(total)}₮',
                            style: TextStyle(
                                color: c.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Delivery address
            if (phone.isNotEmpty || address.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: itemBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    if (phone.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.phone_outlined,
                              color: textSecondary, size: 13),
                          const SizedBox(width: 8),
                          Text(phone,
                              style: TextStyle(color: textPrimary, fontSize: 12)),
                        ],
                      ),
                    if (phone.isNotEmpty && address.isNotEmpty)
                      const SizedBox(height: 6),
                    if (address.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_outlined,
                              color: textSecondary, size: 13),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(address,
                                style: TextStyle(color: textPrimary, fontSize: 12),
                                maxLines: 2),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(dynamic item, Color itemBg, Color textPrimary, Color textSecondary) {
    final name      = item['name']      as String? ?? '';
    final cat       = item['category']  as String? ?? '';
    final size      = item['size']      as String? ?? '';
    final imageUrl  = item['imageUrl']  as String? ?? '';
    final productId = item['productId'] as String? ?? '';
    final price     = (item['priceMNT'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: itemBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56, height: 56,
              child: _buildProductImage(imageUrl, productId),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(cat,
                    style: TextStyle(color: textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                if (size.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(size,
                        style: TextStyle(
                            color: c.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${widget.fmt(price)}₮',
              style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // Shows image from stored URL; if missing, fetches from products collection
  Widget _buildProductImage(String imageUrl, String productId) {
    if (imageUrl.isNotEmpty) {
      return _imgWidget(imageUrl);
    }
    if (productId.isNotEmpty) {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Container(
              color: c.card,
              child: Icon(Icons.checkroom_outlined,
                  color: c.primary.withValues(alpha: 0.4), size: 24),
            );
          }
          final url = snap.data?.exists == true
              ? ((snap.data!.data() as Map<String, dynamic>)['imageUrl']
                      as String?) ??
                  ''
              : '';
          return _imgWidget(url);
        },
      );
    }
    return _imgWidget('');
  }

  Widget _imgWidget(String url) {
    final fallback = Container(
      color: c.card,
      child: Icon(Icons.checkroom_outlined, color: c.primary, size: 24),
    );
    if (url.isEmpty) return fallback;
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        width: 56, height: 56, fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      );
    }
    return Image.asset(
      url,
      width: 56, height: 56, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  Widget _priceRow(IconData icon, String label, String value, Color vc) =>
      Row(
        children: [
          Icon(icon, color: c.textSecondary, size: 13),
          SizedBox(width: 6),
          Text(label,
              style: TextStyle(color: c.textSecondary, fontSize: 12)),
          const Spacer(),
          Text(value, style: TextStyle(color: vc, fontSize: 12)),
        ],
      );

  String _fmtDateFull(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}
