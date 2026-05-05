import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: const Text('Апп-ын тухай')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Logo + name ─────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: c.primary.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: ClipOval(
                      child: Image.asset('assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                                color: c.primary,
                                child: const Center(
                                  child: Text('AS',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900)),
                                ),
                              )),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Anime Store',
                      style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Text('Монголын аниме фэшн дэлгүүр',
                      style: TextStyle(color: c.textSecondary, fontSize: 13)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text('Хувилбар 1.0.0',
                        style: TextStyle(
                            color: c.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── About ───────────────────────────────────────────────────────
            _section(c, '📖 Апп-ын тухай',
                'Anime Store бол Монголын аниме фэшн дэлгүүр юм. '
                'Дэлхийд алдартай аниме цувралуудын дизайнтай өндөр чанарын '
                'acid wash oversized t-shirt болон hoodie-г захиалж гэртээ хүлгэж авах боломжтой.\n\n'
                'Бид аниме дуртай залуучуудад зориулж урлаг болон фэшныг '
                'хослуулсан эксклюзив цуглуулга бүтээдэг.'),

            const SizedBox(height: 20),

            // ── Stats ───────────────────────────────────────────────────────
            _statsRow(c),

            const SizedBox(height: 20),

            // ── Features ────────────────────────────────────────────────────
            _section(c, '✨ Боломжууд', null, items: [
              _item(c, Icons.checkroom_outlined,
                  'Өндөр чанарын бараа',
                  'Acid wash, oversized cut — T-shirt 39,000₮ · Hoodie 69,000₮'),
              _item(c, Icons.palette_outlined,
                  '11 аниме, 25 дизайн',
                  'Demon Slayer, JJK, AOT, Bleach, Solo Leveling, Chainsaw Man болон бусад'),
              _item(c, Icons.local_shipping_outlined,
                  '3 хоногт хүргэлт',
                  'Улаанбаатар хотод 3 хуанлийн өдрийн дотор хүргэнэ · 5,000₮'),
              _item(c, Icons.inventory_2_outlined,
                  'Бодит цагийн үлдэгдэл',
                  'Бараа бүрийн хэмжээ тус бүрийн үлдэгдэл тоог шууд харна'),
              _item(c, Icons.star_rounded,
                  'Хэрэглэгчийн үнэлгээ',
                  'Аль ч барааны дэлгэрэнгүйд одоор үнэлгээ өгч болно'),
              _item(c, Icons.receipt_long_outlined,
                  'Захиалгын түүх',
                  'Захиалга бүрийн зураг, хэмжээ, хүргэлтийн хугацааг харах'),
              _item(c, Icons.support_agent_outlined,
                  'Шууд чат',
                  'Admin-тай шууд чатаар холбогдох боломжтой'),
              _item(c, Icons.dark_mode_outlined,
                  'Dark / Light горим',
                  'Гэрэлтэй болон харанхуй дизайны хооронд шилжих боломжтой'),
            ]),

            const SizedBox(height: 20),

            // ── Collection ──────────────────────────────────────────────────
            _section(c, '📦 Одоогийн цуглуулга', null, items: [
              _collectionRow(c, 'Demon Slayer',    4, const Color(0xFFB22222)),
              _collectionRow(c, 'Jujutsu Kaisen',  4, const Color(0xFF4A148C)),
              _collectionRow(c, 'Attack on Titan', 3, const Color(0xFF4A5240)),
              _collectionRow(c, 'Solo Leveling',   2, const Color(0xFF0D47A1)),
              _collectionRow(c, 'Chainsaw Man',    2, const Color(0xFFCC2200)),
              _collectionRow(c, 'Bleach',          2, const Color(0xFF1A1A2E)),
              _collectionRow(c, 'Hunter x Hunter', 1, const Color(0xFF1565C0)),
              _collectionRow(c, 'Dr. Stone',       1, const Color(0xFF2E7D32)),
              _collectionRow(c, 'Hoodie',          6, const Color(0xFF5D4037)),
            ]),

            const SizedBox(height: 20),

            // ── Payment ─────────────────────────────────────────────────────
            _section(c, '💳 Төлбөрийн мэдээлэл', null, items: [
              _item(c, Icons.account_balance_outlined,
                  'Хаан Банк',
                  'Данс: 5619401212 · Хүлээн авагч: Гарьд Гантөмөр'),
              _item(c, Icons.info_outline_rounded,
                  'Гүйлгээний утга',
                  'Утасны дугаар болон хаягийг гүйлгээний утганд заавал бичнэ'),
            ]),

            const SizedBox(height: 20),

            // ── Contact ─────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  _contactRow(c, Icons.email_outlined,    'garidga999@gmail.com'),
                  const SizedBox(height: 8),
                  _contactRow(c, Icons.language_outlined, 'Улаанбаатар, Монгол Улс'),
                  const SizedBox(height: 8),
                  _contactRow(c, Icons.chat_outlined,
                      'Апп дотроос Admin-тай чатлах боломжтой'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: Text(
                '© 2026 Anime Store. Бүх эрх хуулиар хамгаалагдсан.',
                style: TextStyle(color: c.textSecondary, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────

  Widget _statsRow(AppColors c) {
    return Row(
      children: [
        _statCard(c, '25', 'Нийт бараа'),
        const SizedBox(width: 10),
        _statCard(c, '11', 'Аниме'),
        const SizedBox(width: 10),
        _statCard(c, '5★', 'Үнэлгээ'),
      ],
    );
  }

  Widget _statCard(AppColors c, String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      color: c.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(color: c.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      );

  // ── Section wrapper ────────────────────────────────────────────────────────

  Widget _section(AppColors c, String title, String? body,
      {List<Widget>? items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: c.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: body != null
              ? Text(body,
                  style: TextStyle(
                      color: c.textSecondary, fontSize: 13, height: 1.7))
              : Column(children: items ?? []),
        ),
      ],
    );
  }

  // ── Feature item ───────────────────────────────────────────────────────────

  Widget _item(AppColors c, IconData icon, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: c.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(sub,
                    style: TextStyle(color: c.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Collection row ─────────────────────────────────────────────────────────

  Widget _collectionRow(AppColors c, String name, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name,
                style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count дизайн',
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Contact row ────────────────────────────────────────────────────────────

  Widget _contactRow(AppColors c, IconData icon, String text) => Row(
        children: [
          Icon(icon, color: c.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(color: c.textPrimary, fontSize: 13)),
          ),
        ],
      );
}
