import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_theme.dart';
import 'orders_screen.dart';
import 'edit_profile_screen.dart';
import 'delivery_address_screen.dart';
import 'notifications_screen.dart';
import 'support_chat_screen.dart';
import 'app_info_screen.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onSignOut;

  const ProfileScreen({super.key, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'Хэрэглэгч';
    final email = user?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: const Text('Профайл')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
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
                    child: Center(
                      child: Text(initial,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(name,
                      style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text(email,
                      style: TextStyle(
                          color: c.textSecondary, fontSize: 13)),
                  SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: c.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text('Anime Store Member',
                        style: TextStyle(
                            color: c.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Menu items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Захиалга', c),
                  _menuItem(
                    c: c,
                    icon: Icons.shopping_bag_outlined,
                    title: 'Миний захиалгууд',
                    subtitle: 'Захиалгын түүх харах',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const OrdersScreen(standalone: true)),
                    ),
                  ),

                  const SizedBox(height: 16),
                  _sectionLabel('Тохиргоо', c),
                  _menuItem(
                    c: c,
                    icon: Icons.person_outline_rounded,
                    title: 'Профайл засах',
                    subtitle: 'Нэр, мэдээлэл өөрчлөх',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const EditProfileScreen())),
                  ),
                  _menuItem(
                    c: c,
                    icon: Icons.location_on_outlined,
                    title: 'Хүргэлтийн хаяг',
                    subtitle: 'Хаяг нэмэх, засах',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const DeliveryAddressScreen())),
                  ),
                  _menuItem(
                    c: c,
                    icon: Icons.notifications_outlined,
                    title: 'Мэдэгдэл',
                    subtitle: 'Мэдэгдлийн тохиргоо',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsScreen())),
                  ),

                  const SizedBox(height: 16),
                  _sectionLabel('Тусламж', c),
                  _menuItem(
                    c: c,
                    icon: Icons.support_agent_outlined,
                    title: 'Тусламж & Дэмжлэг',
                    subtitle: 'Асуулт, санал хүсэлт — Admin-тай чат',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const SupportChatScreen())),
                  ),
                  _menuItem(
                    c: c,
                    icon: Icons.info_outline_rounded,
                    title: 'Апп-ын тухай',
                    subtitle: 'Хувилбар 1.0.0 · Anime Store',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const AppInfoScreen())),
                  ),

                  const SizedBox(height: 24),

                  // Sign out
                  GestureDetector(
                    onTap: () => _confirmSignOut(context, c),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: c.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded,
                              color: c.primary, size: 20),
                          SizedBox(width: 10),
                          Text('Гарах',
                              style: TextStyle(
                                  color: c.primary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AppColors c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Гарах уу?',
            style: TextStyle(
                color: c.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Та акаунтаасаа гарах гэж байна.',
            style: TextStyle(color: c.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Болих',
                style: TextStyle(color: c.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.pop(context);
              onSignOut();
            },
            child: const Text('Гарах',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, AppColors c) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label,
            style: TextStyle(
                color: c.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      );

  Widget _menuItem({
    required AppColors c,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: c.primary, size: 20),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: c.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            if (showArrow)
              Icon(Icons.arrow_forward_ios_rounded,
                  color: c.textSecondary, size: 14),
          ],
        ),
      ),
    );
  }
}
