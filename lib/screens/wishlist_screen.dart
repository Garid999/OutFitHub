import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../utils/app_theme.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  final Set<String> wishlistIds;
  final double? Function(Product) getDiscountedPrice;
  final void Function(Product, String) onAddToCart;
  final void Function(String) onToggleWishlist;

  const WishlistScreen({
    super.key,
    required this.wishlistIds,
    required this.getDiscountedPrice,
    required this.onAddToCart,
    required this.onToggleWishlist,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    if (wishlistIds.isEmpty) {
      return _buildEmpty(c);
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('products')
          .where(FieldPath.documentId, whereIn: wishlistIds.toList())
          .get(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: c.primary));
        }

        final products = (snap.data?.docs ?? [])
            .map((d) => Product.fromFirestore(d))
            .where((p) => p.isActive)
            .toList();

        if (products.isEmpty) return _buildEmpty(c);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.favorite_rounded, color: c.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('${products.length} бараа хадгалагдсан',
                      style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (ctx, i) {
                  final p = products[i];
                  return ProductCard(
                    product: p,
                    discountedPrice: getDiscountedPrice(p),
                    isWishlisted: wishlistIds.contains(p.id),
                    onWishlistToggle: () => onToggleWishlist(p.id),
                    onAddToCart: () => onAddToCart(p, 'M'),
                    onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(
                          product: p,
                          onAddToCart: (size) => onAddToCart(p, size),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmpty(AppColors c) {
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
            child: Icon(Icons.favorite_border_rounded,
                color: c.primary, size: 48),
          ),
          const SizedBox(height: 20),
          Text('Хүслийн жагсаалт хоосон',
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Бараан дээрх ♡ дарж хадгалаарай',
              style: TextStyle(color: c.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
