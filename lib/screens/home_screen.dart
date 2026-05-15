import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/product_seed.dart';
import '../models/product.dart';
import '../utils/app_theme.dart';
import '../widgets/product_card.dart';
import 'login_screen.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppColors c = AppColors.light;
  int _selectedIndex = 0;
  final List<Product> _cartItems = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<Product> _products = [];
  StreamSubscription<QuerySnapshot>? _productSub;
  bool _cartLoaded = false;
  List<Map<String, dynamic>> _activeEvents = [];
  Set<String> _wishlistIds = {};

  StreamSubscription<QuerySnapshot>? _eventSub;
  StreamSubscription<QuerySnapshot>? _wishlistSub;

  @override
  void initState() {
    super.initState();
    _seedAndListen();
    _listenEvents();
    _listenWishlist();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcomeIfNeeded());
  }

  Future<void> _showWelcomeIfNeeded() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('welcome_$uid') ?? false;
    if (shown || !mounted) return;
    await prefs.setBool('welcome_$uid', true);

    final name = FirebaseAuth.instance.currentUser?.displayName ?? '';
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primary.withValues(alpha: 0.1),
              ),
              child: ClipOval(
                child: Image.asset('assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.storefront_rounded,
                            color: c.primary, size: 40)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name.isNotEmpty ? 'Сайн байна уу,\n$name!' : 'Сайн байна уу!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.3),
            ),
            const SizedBox(height: 8),
            Text(
              'Аниме фэшн дэлгүүрт тавтай морил 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Бараа үзэх',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _productSub?.cancel();
    _eventSub?.cancel();
    _wishlistSub?.cancel();
    super.dispose();
  }

  void _listenWishlist() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    _wishlistSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .snapshots()
        .listen((s) {
      if (!mounted) return;
      setState(() => _wishlistIds = s.docs.map((d) => d.id).toSet());
    });
  }

  Future<void> _toggleWishlist(String productId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .doc(productId);
    if (_wishlistIds.contains(productId)) {
      setState(() => _wishlistIds.remove(productId));
      await ref.delete();
    } else {
      setState(() => _wishlistIds.add(productId));
      await ref.set({'addedAt': FieldValue.serverTimestamp()});
    }
  }

  void _listenEvents() {
    // Single where clause only — filter endDate locally to avoid composite index
    _eventSub = FirebaseFirestore.instance
        .collection('events')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((s) {
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        _activeEvents = s.docs
            .map((d) => {'id': d.id, ...d.data()})
            .where((e) {
              final end = (e['endDate'] as Timestamp?)?.toDate();
              return end == null || end.isAfter(now);
            })
            .toList();
        // Re-apply (or clear) discounts on existing cart items when events change
        for (int i = 0; i < _cartItems.length; i++) {
          _cartItems[i] = _cartItems[i].withDiscount(_discountedPrice(_cartItems[i]));
        }
      });
    });
  }

  double? _discountedPrice(Product p) {
    for (final e in _activeEvents) {
      final ids      = (e['productIds'] as List?)?.cast<String>() ?? [];
      final category = e['category'] as String? ?? 'Бүгд';
      final matches  = ids.contains(p.id) ||
          (ids.isEmpty && (category == 'Бүгд' || category == p.category));
      if (!matches) continue;
      final type    = e['discountType']  as String? ?? 'fixed';
      final val     = (e['discountValue'] as num?)?.toDouble() ?? 0;
      final origMNT = p.price * 1000;
      if (type == 'percent') return origMNT * (1 - val / 100);
      return (origMNT - val).clamp(0, double.infinity);
    }
    return null;
  }

  Future<void> _seedAndListen() async {
    final col = FirebaseFirestore.instance.collection('products');
    final snap = await col.limit(1).get();
    if (snap.docs.isEmpty) {
      await seedAllProducts();
    } else {
      final d = snap.docs.first.data();
      if (!d.containsKey('stock')) await _migrateStock(col);
    }
    _productSub = col.snapshots().listen((s) {
      if (!mounted) return;
      final all = s.docs.map((d) => Product.fromFirestore(d)).toList()
        ..sort((a, b) =>
            (int.tryParse(a.id) ?? 9999)
                .compareTo(int.tryParse(b.id) ?? 9999));
      setState(() => _products = all.where((p) => p.isActive).toList());
      if (!_cartLoaded && _products.isNotEmpty) {
        _cartLoaded = true;
        _loadCart();
      }
    });
  }

  // ─── Cart persistence ────────────────────────────────────────────────────

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final data = _cartItems
        .map((p) => '${p.id}|${p.selectedSize ?? 'M'}')
        .toList();
    await prefs.setStringList('cart_$uid', data);
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final data = prefs.getStringList('cart_$uid') ?? [];
    if (data.isEmpty) return;
    final items = <Product>[];
    for (final entry in data) {
      final idx = entry.indexOf('|');
      if (idx < 0) continue;
      final id   = entry.substring(0, idx);
      final size = entry.substring(idx + 1);
      try {
        final product = _products.firstWhere((p) => p.id == id);
        final discMNT = _discountedPrice(product);
        items.add(discMNT != null
            ? product.withSize(size).withDiscount(discMNT)
            : product.withSize(size));
      } catch (_) {}
    }
    if (items.isNotEmpty && mounted) {
      setState(() => _cartItems.addAll(items));
    }
  }

  static const _tStock = {'S': 8, 'M': 14, 'L': 12, 'XL': 10, 'XXL': 6};
  static const _hStock = {'S': 5, 'M': 10, 'L': 8,  'XL': 7,  'XXL': 4};

  Future<void> _migrateStock(CollectionReference col) async {
    final snap  = await col.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      if (!d.containsKey('stock')) {
        final price = (d['price'] as num?)?.toDouble() ?? 0;
        final stock = price >= 69.0 ? _hStock : _tStock;
        batch.update(doc.reference, {
          'stock':          stock,
          'availableSizes': stock.keys.toList(),
          'isActive':       d['isActive'] ?? true,
        });
      }
    }
    await batch.commit();
  }

  final List<String> _categories = [
    'All', 'Demon Slayer', 'Bleach', 'Chainsaw Man', 'Attack on Titan',
    'Hunter x Hunter', 'Jujutsu Kaisen', 'Solo Leveling',
    'Kaiju 8', 'Dr. Stone', 'Mashle', 'Hoodie',
  ];

  static const Map<String, Color> _categoryColors = {
    'All':            Color(0xFF990011),
    'Demon Slayer':   Color(0xFFB22222),
    'Bleach':         Color(0xFF1A1A2E),
    'Chainsaw Man':   Color(0xFFCC2200),
    'Attack on Titan':Color(0xFF4A5240),
    'Hunter x Hunter':Color(0xFF1565C0),
    'Jujutsu Kaisen': Color(0xFF4A148C),
    'Solo Leveling':  Color(0xFF0D47A1),
    'Kaiju 8':        Color(0xFF006064),
    'Dr. Stone':      Color(0xFF2E7D32),
    'Mashle':         Color(0xFF37474F),
    'Hoodie':         Color(0xFF5D4037),
  };

  static const Map<String, String> _categoryImages = {
    'All':            'assets/images/logo.png',
    'Demon Slayer':   'assets/images/cat_demon_slayer.png',
    'Bleach':         'assets/images/cat_bleach.png',
    'Chainsaw Man':   'assets/images/cat_chainsaw_man.png',
    'Attack on Titan':'assets/images/cat_attack_on_titan.png',
    'Hunter x Hunter':'assets/images/cat_hunter_x_hunter.png',
    'Jujutsu Kaisen': 'assets/images/cat_jujutsu_kaisen.png',
    'Solo Leveling':  'assets/images/cat_solo_leveling.png',
    'Kaiju 8':        'assets/images/cat_kaiju_8.png',
    'Dr. Stone':      'assets/images/cat_dr_stone.png',
    'Mashle':         'assets/images/cat_mashle.png',
    'Hoodie':         'assets/images/cat_hoodie.png',
  };


  List<Product> get _filteredProducts {
    return _products.where((p) {
      final matchCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
  }

  void _addToCart(Product product, String size) {
    final discMNT = _discountedPrice(product);
    final cartProduct = discMNT != null
        ? product.withSize(size).withDiscount(discMNT)
        : product.withSize(size);
    setState(() => _cartItems.add(cartProduct));
    _saveCart();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} ($size) сагсанд нэмлээ'),
        backgroundColor: c.primary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeFromCart(int index) {
    setState(() => _cartItems.removeAt(index));
    _saveCart();
  }

  void _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    await prefs.remove('cart_$uid');
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Widget _buildHome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: TextField(
                  style: TextStyle(color: c.textPrimary),
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Бараа хайх...',
                    hintStyle: TextStyle(color: c.textSecondary),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: c.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(right: 16),
                  itemCount: _categories.length,
                  itemBuilder: (_, i) => _buildCategoryCircle(_categories[i]),
                ),
              ),
            ],
          ),
        ),
        _filteredProducts.isEmpty
          ? Expanded(
              child: Center(
                child: Text('Бараа олдсонгүй', style: TextStyle(color: c.textSecondary, fontSize: 16)),
              ),
            )
          : Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, childAspectRatio: 0.72,
                  crossAxisSpacing: 12, mainAxisSpacing: 12,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (ctx, i) => ProductCard(
                  product: _filteredProducts[i],
                  discountedPrice: _discountedPrice(_filteredProducts[i]),
                  isWishlisted: _wishlistIds.contains(_filteredProducts[i].id),
                  onWishlistToggle: () => _toggleWishlist(_filteredProducts[i].id),
                  onAddToCart: () => _addToCart(_filteredProducts[i], 'M'),
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ProductDetailScreen(
                      product: _filteredProducts[i],
                      isWishlisted: _wishlistIds.contains(_filteredProducts[i].id),
                      onWishlistToggle: () => _toggleWishlist(_filteredProducts[i].id),
                      onAddToCart: (size) => _addToCart(_filteredProducts[i], size),
                    ))),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildCategoryCircle(String cat) {
    final isSelected = _selectedCategory == cat;
    final color = _categoryColors[cat] ?? c.primary;
    final label = cat == 'All' ? 'Бүгд' : cat;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = cat),
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cat == 'All' ? Colors.white : color,
                border: isSelected
                    ? Border.all(color: c.primary, width: 3)
                    : Border.all(color: Colors.transparent, width: 3),
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))]
                    : [const BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: _categoryImages.containsKey(cat)
                  ? ClipOval(
                      child: Container(
                        width: 64,
                        height: 64,
                        color: Colors.white,
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          _categoryImages[cat]!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              cat == 'All' ? '✦' : cat.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                  color: c.primary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        cat == 'All' ? '✦' : cat.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
            ),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? c.primary : c.textSecondary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ангилал',
                  style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(right: 16),
                  itemCount: _categories.length,
                  itemBuilder: (_, i) => _buildCategoryCircle(_categories[i]),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Expanded(
          child: _filteredProducts.isEmpty
              ? Center(
                  child: Text('Энэ ангилалд бараа байхгүй',
                      style: TextStyle(color: c.textSecondary, fontSize: 15)))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (ctx, i) => ProductCard(
                    product: _filteredProducts[i],
                    discountedPrice: _discountedPrice(_filteredProducts[i]),
                    isWishlisted: _wishlistIds.contains(_filteredProducts[i].id),
                    onWishlistToggle: () => _toggleWishlist(_filteredProducts[i].id),
                    onAddToCart: () => _addToCart(_filteredProducts[i], 'M'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                                  product: _filteredProducts[i],
                                  isWishlisted: _wishlistIds.contains(_filteredProducts[i].id),
                                  onWishlistToggle: () => _toggleWishlist(_filteredProducts[i].id),
                                  onAddToCart: (size) =>
                                      _addToCart(_filteredProducts[i], size),
                                ))),
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    c = context.c;
    void clearCart() {
      setState(() => _cartItems.clear());
      _saveCart();
    }

    final List<Widget> screens = [
      _buildHome(),
      _buildCategory(),
      WishlistScreen(
        wishlistIds: _wishlistIds,
        getDiscountedPrice: _discountedPrice,
        onAddToCart: _addToCart,
        onToggleWishlist: _toggleWishlist,
      ),
      CartScreen(
        cartItems: _cartItems,
        onRemove: _removeFromCart,
        onPaymentSuccess: clearCart,
      ),
      const OrdersScreen(),
      ProfileScreen(onSignOut: _signOut),
    ];

    final themeNotifier = context.watch<ThemeNotifier>();
    final isDark = themeNotifier.isDark;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            tooltip: isDark ? 'Light mode' : 'Dark mode',
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey(isDark),
                color: isDark ? Colors.amber : c.textPrimary,
                size: 22,
              ),
            ),
            onPressed: () => context.read<ThemeNotifier>().toggle(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: Image.asset('assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            ),
            const SizedBox(width: 8),
            Text('Anime Store'),
          ],
        ),
        actions: [
          // Notification bell
          _NotificationBell(c: c, onAddToCart: _addToCart),
          // Cart
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_bag_outlined, color: c.textPrimary),
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                    CartScreen(
                      cartItems: _cartItems,
                      onRemove: _removeFromCart,
                      onPaymentSuccess: clearCart,
                    ))),
              ),
              if (_cartItems.isNotEmpty)
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: c.primary, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${_cartItems.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        backgroundColor: c.surface,
        selectedItemColor: c.primary,
        unselectedItemColor: c.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.category_outlined), label: 'Category'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border_rounded), label: 'Хүсэл'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Захиалга'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification Bell widget with unread badge
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  final AppColors c;
  final Function(Product, String) onAddToCart;
  const _NotificationBell({required this.c, required this.onAddToCart});

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (_, snap) {
        final unread = snap.data?.docs.length ?? 0;
        return Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: c.textPrimary),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => NotificationsScreen(onAddToCart: onAddToCart)),
              ),
            ),
            if (unread > 0)
              Positioned(
                right: 8, top: 8,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                      color: c.primary, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}