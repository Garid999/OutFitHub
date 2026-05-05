import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_theme.dart';
import '../utils/notifications_helper.dart';
import 'event_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  CollectionReference get _col => FirebaseFirestore.instance
      .collection('users')
      .doc(_uid)
      .collection('notifications');

  IconData _icon(String type) {
    switch (type) {
      case 'order_update': return Icons.receipt_long_rounded;
      case 'new_product':  return Icons.checkroom_outlined;
      case 'event':        return Icons.local_offer_rounded;
      default:             return Icons.notifications_outlined;
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'order_update': return const Color(0xFF4CAF50);
      case 'new_product':  return const Color(0xFF1565C0);
      case 'event':        return const Color(0xFFE53935);
      default:             return const Color(0xFF9E9E9E);
    }
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1)  return 'Саяхан';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин өмнө';
    if (diff.inHours < 24)   return '${diff.inHours} цаг өмнө';
    if (diff.inDays < 7)     return '${diff.inDays} өдөр өмнө';
    final d = ts.toDate();
    return '${d.month}/${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (_uid.isEmpty) {
      return Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(title: const Text('Мэдэгдэл')),
        body: Center(child: Text('Нэвтэрч орно уу',
            style: TextStyle(color: c.textSecondary))),
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Мэдэгдэл'),
        actions: [
          TextButton(
            onPressed: () => NotifHelper.markAllRead(_uid),
            child: Text('Бүгд уншсан',
                style: TextStyle(color: c.primary, fontSize: 13)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _col.orderBy('createdAt', descending: true).limit(50).snapshots(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: c.primary));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      color: c.textSecondary, size: 64),
                  const SizedBox(height: 12),
                  Text('Мэдэгдэл байхгүй',
                      style: TextStyle(color: c.textSecondary, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('Захиалга, шинэ бараа, event-ийн мэдэгдэл\nэнд харагдана',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.textSecondary, fontSize: 12)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                Divider(color: c.border, height: 1, indent: 70),
            itemBuilder: (_, i) {
              final d      = docs[i].data() as Map<String, dynamic>;
              final type   = d['type']   as String? ?? '';
              final title  = d['title']  as String? ?? '';
              final body   = d['body']   as String? ?? '';
              final isRead = d['isRead'] as bool?   ?? false;
              final ts     = d['createdAt'] as Timestamp?;
              return Material(
                color: isRead
                    ? Colors.transparent
                    : c.primary.withValues(alpha: 0.04),
                child: InkWell(
                  onTap: () {
                    NotifHelper.markRead(_uid, docs[i].id);
                    if (type == 'event') {
                      final eventId =
                          (d['data'] as Map<String, dynamic>?)?['eventId']
                              as String? ?? '';
                      if (eventId.isNotEmpty && context.mounted) {
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) =>
                                EventDetailScreen(eventId: eventId)));
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: _iconColor(type).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_icon(type),
                              color: _iconColor(type), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(title,
                                        style: TextStyle(
                                            color: c.textPrimary,
                                            fontWeight: isRead
                                                ? FontWeight.w500
                                                : FontWeight.w700,
                                            fontSize: 13)),
                                  ),
                                  Text(_timeAgo(ts),
                                      style: TextStyle(
                                          color: c.textSecondary,
                                          fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(body,
                                  style: TextStyle(
                                      color: c.textSecondary,
                                      fontSize: 12, height: 1.4),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        if (!isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: c.primary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
