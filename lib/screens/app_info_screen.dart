import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Апп-ын тухай')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo + name
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: ClipOval(
                      child: Image.asset('assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                                color: AppTheme.primary,
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
                  const Text('Anime Store',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: const Text('Хувилбар 1.0.0',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            _section('📖 Апп-ын тухай', '''Anime Store бол Монголын анхны аниме фэшн дэлгүүр юм. Дэлхийд хамгийн их үзэгчтэй аниме цувралуудын дизайнтай өндөр чанарын acid wash oversized t-shirt-үүдийг таны гэрт хүргэдэг.

Бид аниме дуртай залуучуудад зориулж, урлаг болон фэшныг хослуулсан цуглуулга бүтээдэг.'''),

            const SizedBox(height: 20),

            _section('✨ Давуу талууд', null,
                items: [
                  _item(Icons.checkroom_outlined,
                      'Өндөр чанарын бараа',
                      'Acid wash, oversized cut, premium cotton материал'),
                  _item(Icons.palette_outlined,
                      'Эксклюзив дизайн',
                      'Demon Slayer, JJK, AOT, Bleach болон бусад 10+ аниме'),
                  _item(Icons.local_shipping_outlined,
                      'Хурдан хүргэлт',
                      'Улаанбаатар хотод 3 хоногт хүргэнэ'),
                  _item(Icons.security_outlined,
                      'Найдвартай захиалга',
                      'Захиалгын баталгаажуулалт, хүргэлтийн мэдэгдэл'),
                  _item(Icons.support_agent_outlined,
                      '24/7 Дэмжлэг',
                      'Chat дамжуулан шууд холбогдох боломжтой'),
                  _item(Icons.payment_outlined,
                      'Хялбар төлбөр',
                      'Олон төрлийн төлбөрийн аргаар хийх боломжтой'),
                ]),

            const SizedBox(height: 20),

            _section('🎯 Зорилт', '''• Монгол залуучуудад дэлхийн аниме фэшныг хүртээмжтэй болгох
• Жилд 100+ шинэ дизайн гаргаж, цуглуулгаа байнга шинэчлэх
• Монголын аниме community-г дэмжих, хөгжүүлэх
• Бүс нутгийн хамгийн том аниме фэшн платформ болох'''),

            const SizedBox(height: 20),

            _section('📦 Одоогийн цуглуулга', '''Нийт 17 эксклюзив дизайн:
• Demon Slayer — 4 дизайн
• Jujutsu Kaisen — 4 дизайн
• Attack on Titan — 2 дизайн
• Bleach — 2 дизайн
• Solo Leveling — 2 дизайн
• Chainsaw Man, Hunter x Hunter, Dr. Stone — 1 тус бүр

Үнэ: 39,000₮ | Хүргэлт: 5,000₮'''),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.email_outlined,
                          color: AppTheme.primary, size: 16),
                      SizedBox(width: 8),
                      Text('garidga999@gmail.com',
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.language_outlined,
                          color: AppTheme.primary, size: 16),
                      SizedBox(width: 8),
                      Text('Улаанбаатар, Монгол',
                          style: TextStyle(
                              color: AppTheme.textPrimary, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: Text('© 2026 Anime Store. Бүх эрх хуулиар хамгаалагдсан.',
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String? body, {List<Widget>? items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (body != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(body,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.7)),
          ),
        if (items != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(children: items),
          ),
      ],
    );
  }

  Widget _item(IconData icon, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(sub,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
