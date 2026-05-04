import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../utils/app_theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final Function(String size) onAddToCart;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  AppColors c = AppColors.light;
  String _selectedSize = 'M';
  int _imageIndex = 0;

  List<String> get _images => widget.product.allImages;

  void _nextImage() {
    if (_imageIndex < _images.length - 1) {
      setState(() => _imageIndex++);
    }
  }

  void _prevImage() {
    if (_imageIndex > 0) {
      setState(() => _imageIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    c = context.c;
    final priceStr = (widget.product.price * 1000)
        .toInt()
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    final hasMultiple = _images.length > 1;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(widget.product.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with navigation
            Container(
              height: 380,
              width: double.infinity,
              color: Colors.white,
              child: Stack(
                children: [
                  // Image
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Image.asset(
                      _images[_imageIndex],
                      key: ValueKey(_imageIndex),
                      width: double.infinity,
                      height: 380,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(Icons.checkroom, size: 100, color: c.primary),
                      ),
                    ),
                  ),

                  // Left arrow
                  if (hasMultiple && _imageIndex > 0)
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _prevImage,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chevron_left_rounded,
                                color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ),

                  // Right arrow
                  if (hasMultiple && _imageIndex < _images.length - 1)
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _nextImage,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chevron_right_rounded,
                                color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ),

                  // Dot indicators
                  if (hasMultiple)
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_images.length, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _imageIndex == i ? 20 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _imageIndex == i
                                ? c.primary
                                : Colors.grey.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.product.category,
                      style: TextStyle(
                          color: c.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name + Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.2),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '$priceStr₮',
                        style: TextStyle(
                            color: c.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Dynamic rating
                  _RatingSection(productId: widget.product.id, c: c),

                  SizedBox(height: 20),
                  Divider(color: c.border),
                  SizedBox(height: 16),

                  // Description
                  Text('Тайлбар',
                      style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: TextStyle(
                        color: c.textSecondary, fontSize: 14, height: 1.6),
                  ),

                  SizedBox(height: 20),
                  Divider(color: c.border),
                  const SizedBox(height: 16),

                  // Size selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Хэмжээ сонгох',
                          style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      if (widget.product.isSoldOut)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[700],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Дууссан',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: widget.product.availableSizes.map((size) {
                      final selected  = _selectedSize == size;
                      final stockQty  = widget.product.stockForSize(size);
                      final available = stockQty > 0;
                      return GestureDetector(
                        onTap: available
                            ? () => setState(() => _selectedSize = size)
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: !available
                                ? c.surface.withValues(alpha: 0.4)
                                : selected
                                    ? c.primary
                                    : c.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !available
                                  ? c.border.withValues(alpha: 0.4)
                                  : selected
                                      ? c.primary
                                      : c.border,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(size,
                                  style: TextStyle(
                                      color: !available
                                          ? c.textSecondary.withValues(alpha: 0.4)
                                          : selected
                                              ? Colors.white
                                              : c.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              if (widget.product.stock.isNotEmpty)
                                Text(
                                  available ? '$stockQty' : '0',
                                  style: TextStyle(
                                      color: !available
                                          ? Colors.red.withValues(alpha: 0.6)
                                          : selected
                                              ? Colors.white70
                                              : c.textSecondary,
                                      fontSize: 10),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton.icon(
                    onPressed: widget.product.isSoldOut ||
                            !widget.product.sizeAvailable(_selectedSize)
                        ? null
                        : () {
                            onAddToCart();
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor: Colors.grey[700],
                    ),
                    icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                    label: Text(
                      widget.product.isSoldOut ? 'Дууссан' : 'Сагсанд нэмэх',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onAddToCart() => widget.onAddToCart(_selectedSize);
}

// ─────────────────────────────────────────────────────────────────────────────
// Rating section — reads/writes ratings subcollection
// ─────────────────────────────────────────────────────────────────────────────

class _RatingSection extends StatefulWidget {
  final String productId;
  final AppColors c;
  const _RatingSection({required this.productId, required this.c});

  @override
  State<_RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends State<_RatingSection> {
  bool _saving = false;

  CollectionReference get _col => FirebaseFirestore.instance
      .collection('products')
      .doc(widget.productId)
      .collection('ratings');

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _rate(int stars) async {
    if (_uid.isEmpty) {
      _snack('Нэвтэрч орсоны дараа үнэлгээ өгнө үү');
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    try {
      // Save this user's rating
      await _col.doc(_uid).set({
        'value': stars,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Average is calculated live from subcollection in the StreamBuilder
    } on FirebaseException catch (e) {
      if (mounted) _snack('Алдаа: ${e.message ?? e.code}');
    } catch (e) {
      if (mounted) _snack('Алдаа: $e');
    }
    if (mounted) setState(() => _saving = false);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red[700]));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return StreamBuilder<QuerySnapshot>(
      stream: _col.snapshots(),
      builder: (_, snap) {
        final docs = snap.data?.docs ?? [];
        final total = docs.length;

        // Average
        double avg = 0;
        if (total > 0) {
          final sum = docs.fold<int>(
              0,
              (a, d) =>
                  a +
                  ((d.data() as Map<String, dynamic>)['value'] as int? ?? 0));
          avg = sum / total;
        }

        // Current user's rating
        int myRating = 0;
        if (_uid.isNotEmpty) {
          final mine = docs.where((d) => d.id == _uid).toList();
          if (mine.isNotEmpty) {
            myRating = (mine.first.data() as Map<String, dynamic>)['value']
                    as int? ??
                0;
          }
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: const Color(0xFFFFB300).withValues(alpha: 0.35),
                width: 1.5),
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFB300).withValues(alpha: c.isDark ? 0.07 : 0.05),
                const Color(0xFFFFB300).withValues(alpha: 0.0),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Average display ──────────────────────────────────────
            Row(
              children: [
                Text(
                  total > 0 ? avg.toStringAsFixed(1) : '—',
                  style: const TextStyle(
                      color: Color(0xFFFFB300),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (i) {
                        final filled = i < avg.floor();
                        final half   = !filled && i < avg;
                        return Icon(
                          filled
                              ? Icons.star_rounded
                              : half
                                  ? Icons.star_half_rounded
                                  : Icons.star_outline_rounded,
                          color: const Color(0xFFFFB300),
                          size: 16,
                        );
                      }),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      total > 0 ? '$total үнэлгээ' : 'Үнэлгээ байхгүй',
                      style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),

            if (_uid.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.2),
                    height: 1),
              ),

              // ── User rating ────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    myRating > 0 ? 'Таны үнэлгээ' : 'Үнэлгээ өгөх',
                    style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                  if (_saving)
                    const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFFFFB300))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) {
                  final star = i + 1;
                  final active = star <= myRating;
                  return GestureDetector(
                    onTap: _saving ? null : () => _rate(star),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 6),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFFFFB300).withValues(alpha: 0.15)
                            : c.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: active
                              ? const Color(0xFFFFB300)
                              : c.border,
                          width: active ? 1.5 : 1,
                        ),
                      ),
                      child: Icon(
                        active ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: active
                            ? const Color(0xFFFFB300)
                            : c.textSecondary,
                        size: 18,
                      ),
                    ),
                  );
                })
                  ..add(
                    _saving
                        ? const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFFFB300))),
                          )
                        : myRating > 0
                            ? Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  '$myRating ⭐',
                                  style: TextStyle(
                                      color: c.textSecondary, fontSize: 12),
                                ),
                              )
                            : const SizedBox.shrink(),
                  ),
              ),
            ],
          ],
        ),
      );
      },
    );
  }
}
