import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../utils/app_theme.dart';
import 'product_detail_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;
  final Function(Product, String)? onAddToCart;
  const EventDetailScreen({super.key, required this.eventId, this.onAddToCart});

  String _fmt(int v) => v.toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _fmtDate(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  double _discountedPrice(double originalMNT, String type, double val) {
    if (type == 'percent') return originalMNT * (1 - val / 100);
    return (originalMNT - val).clamp(0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: const Text('Арга хэмжээ')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('events').doc(eventId).get(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: c.primary));
          }
          if (!snap.hasData || !snap.data!.exists) {
            return Center(child: Text('Event олдсонгүй',
                style: TextStyle(color: c.textSecondary)));
          }

          final e          = snap.data!.data() as Map<String, dynamic>;
          final title      = e['title']        as String? ?? '';
          final desc       = e['description']  as String? ?? '';
          final discType   = e['discountType'] as String? ?? 'fixed';
          final discVal    = (e['discountValue'] as num?)?.toDouble() ?? 0;
          final category   = e['category']     as String? ?? 'Бүгд';
          final productIds = (e['productIds']  as List?)?.cast<String>() ?? [];
          final startTs    = e['startDate']    as Timestamp?;
          final endTs      = e['endDate']      as Timestamp?;

          final discLabel = discType == 'percent'
              ? '${discVal.toInt()}% хямдрал'
              : '${_fmt(discVal.toInt())}₮ хямдрал';

          late Query productsQuery;
          if (productIds.isNotEmpty) {
            productsQuery = FirebaseFirestore.instance
                .collection('products')
                .where(FieldPath.documentId, whereIn: productIds);
          } else if (category != 'Бүгд') {
            productsQuery = FirebaseFirestore.instance
                .collection('products')
                .where('category', isEqualTo: category)
                .where('isActive', isEqualTo: true);
          } else {
            productsQuery = FirebaseFirestore.instance
                .collection('products')
                .where('isActive', isEqualTo: true);
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Event header ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        c.primary.withValues(alpha: 0.12),
                        c.primary.withValues(alpha: 0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border(
                        bottom: BorderSide(color: c.primary.withValues(alpha: 0.2))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: c.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(discLabel,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ),
                      const SizedBox(height: 12),
                      Text(title,
                          style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(desc,
                            style: TextStyle(
                                color: c.textSecondary,
                                fontSize: 14,
                                height: 1.5)),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                color: c.primary, size: 14),
                            const SizedBox(width: 8),
                            Text(
                              '${_fmtDate(startTs)} – ${_fmtDate(endTs)}',
                              style: TextStyle(
                                  color: c.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Products list ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    children: [
                      Text('Хямдарсан бараанууд',
                          style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      if (onAddToCart != null)
                        Text('· дарж дэлгэрэнгүй үзнэ',
                            style: TextStyle(
                                color: c.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),

                FutureBuilder<QuerySnapshot>(
                  future: productsQuery.get(),
                  builder: (_, pSnap) {
                    if (pSnap.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                            child: CircularProgressIndicator(color: c.primary)),
                      );
                    }
                    final products = pSnap.data?.docs ?? [];
                    if (products.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text('Бараа олдсонгүй',
                              style: TextStyle(color: c.textSecondary)),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      itemCount: products.length,
                      itemBuilder: (_, i) {
                        final d       = products[i].data() as Map<String, dynamic>;
                        final name    = d['name']     as String? ?? '';
                        final cat     = d['category'] as String? ?? '';
                        final img     = d['imageUrl'] as String? ?? '';
                        final price   = (d['price'] as num?)?.toDouble() ?? 0;
                        final origMNT = price * 1000;
                        final discMNT = _discountedPrice(origMNT, discType, discVal);
                        final saved   = origMNT - discMNT;

                        final product = Product.fromFirestore(products[i])
                            .withDiscount(discMNT);

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: onAddToCart == null
                                ? null
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailScreen(
                                          product: product,
                                          onAddToCart: (size) =>
                                              onAddToCart!(product, size),
                                        ),
                                      ),
                                    ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: c.border),
                              ),
                              child: Row(
                                children: [
                                  // Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 64, height: 64,
                                      child: img.startsWith('http')
                                          ? CachedNetworkImage(
                                              imageUrl: img, fit: BoxFit.cover)
                                          : img.isNotEmpty
                                              ? Image.asset(img,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(
                                                          color: c.card,
                                                          child: Icon(
                                                              Icons.checkroom_outlined,
                                                              color: c.primary,
                                                              size: 28)))
                                              : Container(
                                                  color: c.card,
                                                  child: Icon(
                                                      Icons.checkroom_outlined,
                                                      color: c.primary,
                                                      size: 28)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(name,
                                            style: TextStyle(
                                                color: c.textPrimary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 2),
                                        Text(cat,
                                            style: TextStyle(
                                                color: c.textSecondary,
                                                fontSize: 11)),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text('${_fmt(discMNT.toInt())}₮',
                                                style: TextStyle(
                                                    color: c.primary,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 16)),
                                            const SizedBox(width: 8),
                                            Text('${_fmt(origMNT.toInt())}₮',
                                                style: TextStyle(
                                                    color: c.textSecondary,
                                                    fontSize: 12,
                                                    decoration:
                                                        TextDecoration.lineThrough)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Right side: savings + arrow
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text('-${_fmt(saved.toInt())}₮',
                                            style: const TextStyle(
                                                color: Colors.green,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      if (onAddToCart != null) ...[
                                        const SizedBox(height: 6),
                                        Icon(Icons.arrow_forward_ios_rounded,
                                            color: c.textSecondary, size: 14),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
