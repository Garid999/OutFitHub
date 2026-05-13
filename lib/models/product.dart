import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String imageUrl;
  final List<String>? images;
  final double rating;
  final String description;
  final String? selectedSize;
  final List<String> availableSizes;
  final Map<String, int> stock;
  final bool isActive;
  final double? discountedPriceMNT;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    this.images,
    required this.rating,
    required this.description,
    this.selectedSize,
    this.availableSizes = const ['S', 'M', 'L', 'XL', 'XXL'],
    this.stock = const {},
    this.isActive = true,
    this.discountedPriceMNT,
  });

  bool get isNetworkImage => imageUrl.startsWith('http');
  List<String> get allImages => images ?? [imageUrl];

  bool get isSoldOut =>
      stock.isEmpty || stock.values.every((v) => v <= 0);

  int stockForSize(String size) => stock[size] ?? 0;

  bool sizeAvailable(String size) =>
      availableSizes.contains(size) && (stock[size] ?? 0) > 0;

  Product withSize(String size) => Product(
        id: id, name: name, category: category, price: price,
        imageUrl: imageUrl, images: images, rating: rating,
        description: description, selectedSize: size,
        availableSizes: availableSizes, stock: stock, isActive: isActive,
        discountedPriceMNT: discountedPriceMNT,
      );

  Product withDiscount(double? discMNT) => Product(
        id: id, name: name, category: category, price: price,
        imageUrl: imageUrl, images: images, rating: rating,
        description: description, selectedSize: selectedSize,
        availableSizes: availableSizes, stock: stock, isActive: isActive,
        discountedPriceMNT: discMNT,
      );

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawStock = d['stock'] as Map<String, dynamic>?;
    final stockMap = rawStock?.map(
          (k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)) ??
        {};
    final sizes = (d['availableSizes'] as List?)?.cast<String>() ??
        const ['S', 'M', 'L', 'XL', 'XXL'];
    return Product(
      id: doc.id,
      name: d['name'] as String? ?? '',
      category: d['category'] as String? ?? '',
      price: (d['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: d['imageUrl'] as String? ?? '',
      images: (d['images'] as List?)?.cast<String>(),
      rating: (d['rating'] as num?)?.toDouble() ?? 5.0,
      description: d['description'] as String? ?? '',
      availableSizes: sizes,
      stock: stockMap,
      isActive: d['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'category': category,
        'price': price,
        'imageUrl': imageUrl,
        if (images != null && images!.isNotEmpty) 'images': images,
        'rating': rating,
        'description': description,
        'availableSizes': availableSizes,
        'stock': stock,
        'isActive': isActive,
      };
}
