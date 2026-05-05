import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  bool _isLoading = false;

  XFile?     _pickedFile;
  Uint8List? _pickedBytes;
  String?    _photoUrl;
  double?    _uploadProgress; // 0.0 – 1.0

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameCtrl.text = user?.displayName ?? '';
    _photoUrl      = user?.photoURL;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ─── Photo picker ─────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: context.c.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: context.c.primary),
              title: Text('Галерей', style: TextStyle(color: context.c.textPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (!kIsWeb)
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: context.c.primary),
                title: Text('Камер', style: TextStyle(color: context.c.textPrimary)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (source == null) return;

    final xFile = await ImagePicker()
        .pickImage(source: source, imageQuality: 60, maxWidth: 300);
    if (xFile == null || !mounted) return;

    final bytes = await xFile.readAsBytes();
    setState(() { _pickedFile = xFile; _pickedBytes = bytes; });
  }

  Future<String?> _uploadPhoto(String uid) async {
    if (_pickedFile == null) return null;
    final ref = FirebaseStorage.instance.ref('users/$uid/profile.jpg');

    late UploadTask task;
    if (kIsWeb) {
      task = ref.putData(_pickedBytes!,
          SettableMetadata(contentType: 'image/jpeg'));
    } else {
      task = ref.putFile(File(_pickedFile!.path));
    }

    // Track progress
    task.snapshotEvents.listen((snap) {
      if (!mounted) return;
      setState(() => _uploadProgress =
          snap.bytesTransferred / (snap.totalBytes == 0 ? 1 : snap.totalBytes));
    });

    await task;
    if (mounted) setState(() => _uploadProgress = null);
    return await ref.getDownloadURL();
  }

  // ─── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { _snack('Нэрээ оруулна уу'); return; }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;

      // Upload photo first (small, compressed)
      String? newPhotoUrl = _photoUrl;
      if (_pickedFile != null) {
        newPhotoUrl = await _uploadPhoto(user.uid);
      }

      await user.updateDisplayName(name);
      if (newPhotoUrl != null) await user.updatePhotoURL(newPhotoUrl);
      await user.reload(); // refresh cached user object

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'displayName': name,
        if (newPhotoUrl != null) 'photoURL': newPhotoUrl,
      }, SetOptions(merge: true));

      if (!mounted) return;
      _snack('Амжилттай хадгалагдлаа');
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _snack('Firebase алдаа: ${e.message ?? e.code}');
    } catch (e) {
      if (!mounted) return;
      _snack('Алдаа: $e');
    } finally {
      if (mounted) setState(() {
        _isLoading = false;
        _uploadProgress = null;
      });
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.primary));

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c    = context.c;
    final user = FirebaseAuth.instance.currentUser;
    final initial = ((user?.displayName?.isNotEmpty == true
                ? user!.displayName![0]
                : user?.email?[0]) ?? 'U')
        .toUpperCase();

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: const Text('Профайл засах')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ── Avatar ──────────────────────────────────────────────────────
            GestureDetector(
              onTap: _pickPhoto,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  // Photo circle
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.primary,
                      boxShadow: [
                        BoxShadow(
                            color: c.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: ClipOval(child: _buildAvatar(initial, c)),
                  ),

                  // Camera icon badge with progress
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.primary,
                      border: Border.all(color: c.background, width: 2),
                    ),
                    child: _uploadProgress != null
                        ? Padding(
                            padding: const EdgeInsets.all(4),
                            child: CircularProgressIndicator(
                                value: _uploadProgress,
                                color: Colors.white,
                                strokeWidth: 2.5))
                        : const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Text(user?.email ?? '',
                style: TextStyle(color: c.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            Text('Зураг солихын тулд дарна уу',
                style: TextStyle(color: c.textSecondary, fontSize: 11)),

            const SizedBox(height: 32),

            // ── Name field ───────────────────────────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Хэрэглэгчийн нэр',
                  style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              style: TextStyle(color: c.textPrimary, fontSize: 15),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.person_outline_rounded, color: c.primary),
                hintText: 'Жишээ: Батболд Дорж',
                hintStyle: TextStyle(color: c.textSecondary),
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
              ),
            ),

            const SizedBox(height: 32),

            _isLoading
                ? CircularProgressIndicator(color: c.primary)
                : ElevatedButton(
                    onPressed: _save,
                    child: const Text('Хадгалах',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String initial, AppColors c) {
    // New picked image (bytes)
    if (_pickedBytes != null) {
      return Image.memory(_pickedBytes!,
          width: 100, height: 100, fit: BoxFit.cover);
    }
    // Existing network photo
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return CachedNetworkImage(
          imageUrl: _photoUrl!,
          width: 100, height: 100, fit: BoxFit.cover,
          placeholder: (_, __) => Center(
              child: Text(initial,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800))),
          errorWidget: (_, __, ___) => Center(
              child: Text(initial,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800))));
    }
    // Initials fallback
    return Center(
        child: Text(initial,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800)));
  }
}
