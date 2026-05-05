import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../utils/notifications_helper.dart';

class AdminProductFormScreen extends StatefulWidget {
  final Product? product;
  const AdminProductFormScreen({super.key, this.product});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _nameCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();

  // Stock controllers per size
  final Map<String, TextEditingController> _stockCtrl = {
    for (final s in ['S', 'M', 'L', 'XL', 'XXL'])
      s: TextEditingController(text: '0'),
  };

  String _category = 'Demon Slayer';
  bool   _isActive = true;
  bool   _saving   = false;

  // Image state — cross-platform
  XFile?     _pickedFile;
  Uint8List? _pickedBytes;
  String?    _currentImageUrl;

  static const List<String> _categories = [
    'Demon Slayer', 'Bleach', 'Chainsaw Man', 'Attack on Titan',
    'Hunter x Hunter', 'Jujutsu Kaisen', 'Solo Leveling',
    'Kaiju 8', 'Dr. Stone', 'Mashle', 'Hoodie',
  ];

  static const List<String> _allSizes = ['S', 'M', 'L', 'XL', 'XXL'];

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _nameCtrl.text   = p.name;
      _priceCtrl.text  = p.price.toStringAsFixed(0);
      _descCtrl.text   = p.description;
      _category        = _categories.contains(p.category) ? p.category : _categories.first;
      _isActive        = p.isActive;
      _currentImageUrl = p.imageUrl;
      for (final s in _allSizes) {
        _stockCtrl[s]?.text = (p.stock[s] ?? 0).toString();
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    for (final c in _stockCtrl.values) c.dispose();
    super.dispose();
  }

  // ─── Image picker ──────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Colors.white),
              title: const Text('Галерей', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Colors.white),
                title: const Text('Камер', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final xFile  = await picker.pickImage(
        source: source, imageQuality: 85, maxWidth: 1080);
    if (xFile == null || !mounted) return;

    final bytes = await xFile.readAsBytes();
    setState(() {
      _pickedFile  = xFile;
      _pickedBytes = bytes;
    });
  }

  // ─── Upload ────────────────────────────────────────────────────────────────

  Future<String?> _uploadImage(String docId) async {
    if (_pickedFile == null) return null;
    final ref = FirebaseStorage.instance
        .ref()
        .child('products/$docId/main.jpg');
    if (kIsWeb) {
      await ref.putData(
          _pickedBytes!, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      await ref.putFile(File(_pickedFile!.path));
    }
    return await ref.getDownloadURL();
  }

  // ─── Save ──────────────────────────────────────────────────────────────────

  Map<String, int> get _stockMap => {
        for (final s in _allSizes)
          s: int.tryParse(_stockCtrl[s]?.text.trim() ?? '0') ?? 0,
      };

  List<String> get _availableSizes =>
      _allSizes.where((s) => (_stockMap[s] ?? 0) > 0).toList();

  Future<void> _save() async {
    final name  = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    final desc  = _descCtrl.text.trim();

    if (name.isEmpty) { _snack('Барааны нэр оруулна уу'); return; }
    if (price == null || price <= 0) { _snack('Зөв үнэ оруулна уу'); return; }
    // Convert full MNT to thousands (39000₮ → 39.0 stored)
    final storedPrice = price >= 1000 ? price / 1000 : price;

    setState(() => _saving = true);
    try {
      final col      = FirebaseFirestore.instance.collection('products');
      final stockMap = _stockMap;
      final sizes    = _availableSizes;

      // 1. Upload image first (with 45s timeout) — before saving to Firestore
      String imageUrl = _currentImageUrl ?? '';
      String? tempDocId;

      if (_pickedFile != null) {
        // For new products: generate doc ID early so we can use it for Storage path
        if (!_isEdit) tempDocId = col.doc().id;
        final uploadId = _isEdit ? widget.product!.id : tempDocId!;
        try {
          imageUrl = await _uploadImage(uploadId)
              .timeout(const Duration(seconds: 45)) ?? imageUrl;
        } on Exception catch (e) {
          // Upload failed → save without image and warn
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Зураг upload болсонгүй: $e\nБараа хадгалагдаж байна...'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ));
          }
        }
      }

      // 2. Save to Firestore
      if (_isEdit) {
        final docId = widget.product!.id;
        await col.doc(docId).update({
          'name': name, 'category': _category, 'price': storedPrice,
          'description': desc, 'availableSizes': sizes,
          'stock': stockMap, 'isActive': _isActive,
          'imageUrl': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final docId = tempDocId ?? col.doc().id;
        await col.doc(docId).set({
          'name': name, 'category': _category, 'price': storedPrice,
          'description': desc, 'rating': 5.0,
          'availableSizes': sizes, 'stock': stockMap,
          'isActive': true,
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
        // 3. Notify all users about new product
        NotifHelper.broadcast(
          type: 'new_product',
          title: '🆕 Шинэ бараа нэмэгдлээ!',
          body: '$name — $_category · ${(storedPrice * 1000).toInt()}₮',
          data: {'productId': docId},
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Бараа хадгалагдлаа!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _snack('Алдаа: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[700]));

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(_isEdit ? 'Бараа засах' : 'Шинэ бараа нэмэх',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: Color(0xFFE53935), strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Хадгалах',
                  style: TextStyle(
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePicker(),
            const SizedBox(height: 20),
            _buildSection('Барааны мэдээлэл', [
              _buildField(_nameCtrl, 'Нэр', 'Жишээ: Muichiro Tokito',
                  Icons.label_outline),
              const SizedBox(height: 12),
              _buildField(_priceCtrl, 'Үнэ (₮)', 'Жишээ: 39000',
                  Icons.payments_outlined, type: TextInputType.number),
              const SizedBox(height: 12),
              _buildCategoryDropdown(),
              const SizedBox(height: 12),
              _buildField(_descCtrl, 'Тайлбар', 'Барааны дэлгэрэнгүй...',
                  Icons.description_outlined, maxLines: 3),
            ]),
            const SizedBox(height: 20),
            _buildSection('Хэмжээ ба үлдэгдэл тоо', [_buildStockInputs()]),
            const SizedBox(height: 20),
            if (_isEdit)
              _buildSection('Тохиргоо', [_buildActiveToggle()]),
            if (_isEdit) const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _save,
                child: Text(
                  _saving
                      ? 'Хадгалж байна...'
                      : (_isEdit ? 'Өөрчлөлт хадгалах' : 'Бараа нэмэх'),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Image picker widget ───────────────────────────────────────────────────

  Widget _buildImagePicker() {
    Widget imageWidget;

    if (_pickedBytes != null) {
      imageWidget = Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(_pickedBytes!,
              width: double.infinity, height: 220, fit: BoxFit.contain),
        ),
        _editBtn(),
      ]);
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      imageWidget = Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: _currentImageUrl!.startsWith('http')
              ? CachedNetworkImage(
                  imageUrl: _currentImageUrl!,
                  width: double.infinity, height: 220, fit: BoxFit.contain)
              : Image.asset(_currentImageUrl!,
                  width: double.infinity, height: 220, fit: BoxFit.contain),
        ),
        _editBtn(),
      ]);
    } else {
      imageWidget = GestureDetector(
        onTap: _pickImage,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: Colors.grey[500], size: 52),
            const SizedBox(height: 10),
            Text('Зураг нэмэх',
                style: TextStyle(color: Colors.grey[400], fontSize: 14)),
            const SizedBox(height: 4),
            Text('Галерейгаас сонгоно уу',
                style: TextStyle(color: Colors.grey[700], fontSize: 11)),
          ],
        ),
      );
    }

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFE53935).withValues(alpha: 0.4), width: 1.5),
      ),
      child: imageWidget,
    );
  }

  Widget _editBtn() => Positioned(
        top: 8, right: 8,
        child: GestureDetector(
          onTap: _pickImage,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Color(0xFFE53935)),
            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
          ),
        ),
      );

  // ─── Stock inputs per size ─────────────────────────────────────────────────

  Widget _buildStockInputs() {
    return Column(
      children: _allSizes.map((size) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF3A3A3A)),
                ),
                child: Center(
                  child: Text(size,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _stockCtrl[size],
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: const TextStyle(color: Color(0xFF555555)),
                    suffixText: 'ширхэг',
                    suffixStyle: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFFE53935), width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Shared form widgets ───────────────────────────────────────────────────

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, String hint,
      IconData icon, {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF555555)),
            prefixIcon: Icon(icon, color: Colors.grey, size: 18),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: Color(0xFFE53935), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ангилал',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _category,
              dropdownColor: const Color(0xFF2A2A2A),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Идэвхтэй',
                style: TextStyle(color: Colors.white, fontSize: 14)),
            Text('Идэвхгүй бол нүүр хуудсанд харагдахгүй',
                style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        Switch(
          value: _isActive,
          activeThumbColor: const Color(0xFFE53935),
          onChanged: (v) => setState(() => _isActive = v),
        ),
      ],
    );
  }
}
