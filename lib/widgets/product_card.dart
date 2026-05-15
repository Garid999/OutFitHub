import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../utils/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;
  final VoidCallback onTap;
  final double? discountedPrice; // MNT, null = no active event
  final bool isWishlisted;
  final VoidCallback? onWishlistToggle;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.onTap,
    this.discountedPrice,
    this.isWishlisted = false,
    this.onWishlistToggle,
  });

  String _fmt(int v) => v
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final c           = context.c;
    final origMNT     = (product.price * 1000).toInt();
    final hasDiscount = discountedPrice != null;
    final discMNT     = discountedPrice?.toInt() ?? origMNT;
    final savedMNT    = origMNT - discMNT;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: hasDiscount
              ? Border.all(color: c.primary.withValues(alpha: 0.4), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image with badges ─────────────────────────────────────
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      child: _buildImage(product.imageUrl, c),
                    ),
                    // Sold out badge
                    if (product.isSoldOut)
                      Positioned(
                        top: 6, right: 6,
                        child: _badge('Дууссан', Colors.red[700]!),
                      ),
                    // Discount badge
                    if (hasDiscount && !product.isSoldOut)
                      Positioned(
                        top: 6, left: 6,
                        child: _badge('-${_fmt(savedMNT)}₮', c.primary),
                      ),
                    // Heart / wishlist button
                    if (onWishlistToggle != null)
                      Positioned(
                        top: 4, right: 4,
                        child: GestureDetector(
                          onTap: onWishlistToggle,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isWishlisted
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isWishlisted ? Colors.red : Colors.grey,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Info ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(product.category,
                      style:
                          TextStyle(color: c.textSecondary, fontSize: 11)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasDiscount) ...[
                            Text('${_fmt(discMNT)}₮',
                                style: TextStyle(
                                    color: c.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900)),
                            Text('${_fmt(origMNT)}₮',
                                style: TextStyle(
                                    color: c.textSecondary,
                                    fontSize: 10,
                                    decoration: TextDecoration.lineThrough)),
                          ] else
                            Text('${_fmt(origMNT)}₮',
                                style: TextStyle(
                                    color: c.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800)),
                        ],
                      ),
                      // Add button
                      GestureDetector(
                        onTap: product.isSoldOut ? null : onAddToCart,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: product.isSoldOut
                                ? Colors.grey[600]
                                : c.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      );

  Widget _buildImage(String url, AppColors c) {
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        width: double.infinity,
        fit: BoxFit.contain,
        placeholder: (_, __) => Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
        ),
        errorWidget: (_, __, ___) =>
            Center(child: Icon(Icons.checkroom, size: 60, color: c.primary)),
      );
    }
    return Image.asset(url,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Center(child: Icon(Icons.checkroom, size: 60, color: c.primary)));
  }
}
