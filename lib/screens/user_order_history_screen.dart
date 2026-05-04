import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserOrderHistoryScreen extends StatelessWidget {
  final String userId;
  final String? userName; // shown in app bar subtitle

  const UserOrderHistoryScreen({
    super.key,
    required this.userId,
    this.userName,
  });

  DateTime _deadline(DateTime from) {
    final d = from.add(const Duration(days: 3));
    return DateTime(d.year, d.month, d.day);
  }

  String _fmtDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  String _fmt(int v) => v
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Захиалгын түүх',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            if (userName != null && userName!.isNotEmpty)
              Text(userName!,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
      body: userId.isEmpty
          ? const Center(
              child: Text('Нэвтрээгүй байна',
                  style: TextStyle(color: Colors.grey, fontSize: 16)))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red[400], size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Алдаа гарлаа:\n${snap.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.red[300], fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFE53935)));
          }

          final docs = (snap.data?.docs ?? [])
            ..sort((a, b) {
              final at = ((a.data() as Map)['createdAt'] as Timestamp?);
              final bt = ((b.data() as Map)['createdAt'] as Timestamp?);
              if (at == null && bt == null) return 0;
              if (at == null) return 1;
              if (bt == null) return -1;
              return bt.compareTo(at);
            });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      color: Colors.grey[700], size: 64),
                  const SizedBox(height: 16),
                  const Text('Захиалга байхгүй',
                      style: TextStyle(
                          color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          // Summary stats
          int totalSpent = 0;
          int acceptedCount = 0;
          for (final d in docs) {
            final data = d.data() as Map<String, dynamic>;
            if (data['status'] == 'accepted' ||
                data['status'] == 'delivered') {
              totalSpent +=
                  (data['totalAmount'] as num?)?.toInt() ?? 0;
              acceptedCount++;
            }
          }

          return Column(
            children: [
              // ── Stats bar ─────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF2A2A2A)),
                ),
                child: Row(
                  children: [
                    _statChip(Icons.receipt_long_outlined,
                        '${docs.length}', 'Нийт захиалга',
                        Colors.white),
                    const SizedBox(width: 12),
                    _statChip(Icons.check_circle_outline_rounded,
                        '$acceptedCount', 'Баталгаажсан',
                        Colors.green),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Нийт зарцуулсан',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 11)),
                        Text('${_fmt(totalSpent)}₮',
                            style: const TextStyle(
                                color: Color(0xFFE53935),
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Orders list ────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data =
                        docs[i].data() as Map<String, dynamic>;
                    return _buildCard(data);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statChip(
      IconData icon, String value, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Text(label,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> d) {
    final status = d['status'] as String? ?? 'pending';
    final createdAt =
        (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final deadline = _deadline(createdAt);
    final items = (d['items'] as List<dynamic>?) ?? [];
    final totalAmount = (d['totalAmount'] as num?)?.toInt() ?? 0;
    final subtotal = (d['subtotal'] as num?)?.toInt() ?? 0;
    final deliveryFee =
        (d['deliveryFee'] as num?)?.toInt() ?? 5000;
    final orderNumber = d['orderNumber'] as String? ?? '';
    final phone = d['phone'] as String? ?? '';
    final address = d['address'] as String? ?? '';

    Color sc;
    String sl;
    IconData si;
    switch (status) {
      case 'accepted':
        sc = Colors.green;
        sl = 'Баталгаажсан';
        si = Icons.check_circle_outline_rounded;
        break;
      case 'delivered':
        sc = Colors.teal;
        sl = 'Хүргэгдсэн';
        si = Icons.done_all_rounded;
        break;
      case 'removed':
        sc = Colors.red;
        sl = 'Цуцлагдсан';
        si = Icons.cancel_outlined;
        break;
      default:
        sc = Colors.orange;
        sl = 'Хүлээгдэж байна';
        si = Icons.hourglass_empty_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: sc.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(si, color: sc, size: 16),
                const SizedBox(width: 8),
                Text(orderNumber,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: sc.withValues(alpha: 0.4)),
                  ),
                  child: Text(sl,
                      style: TextStyle(
                          color: sc,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date + deadline
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        color: Colors.grey[600], size: 13),
                    const SizedBox(width: 5),
                    Text(_fmtDate(createdAt),
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 12)),
                    const SizedBox(width: 12),
                    Icon(Icons.local_shipping_outlined,
                        color: Colors.grey[600], size: 13),
                    const SizedBox(width: 5),
                    Text('Хүргэлт: ${_fmtDate(deadline)}',
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Color(0xFF2A2A2A)),
                const SizedBox(height: 6),

                // Items
                ...items.map((item) {
                  final name = item['name'] as String? ?? '';
                  final price =
                      (item['priceMNT'] as num?)?.toInt() ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.checkroom_outlined,
                            color: Color(0xFFE53935), size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(name,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13),
                                overflow: TextOverflow.ellipsis)),
                        Text('${_fmt(price)}₮',
                            style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12)),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 6),
                const Divider(color: Color(0xFF2A2A2A)),
                const SizedBox(height: 6),

                // Price + contact
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Бараа: ${_fmt(subtotal)}₮',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11)),
                        Text(
                            'Хүргэлт: +${_fmt(deliveryFee)}₮',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                    Text('${_fmt(totalAmount)}₮',
                        style: const TextStyle(
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ],
                ),
                if (phone.isNotEmpty || address.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined,
                          color: Colors.grey[600], size: 13),
                      const SizedBox(width: 4),
                      Text(phone,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11)),
                      const SizedBox(width: 10),
                      Icon(Icons.location_on_outlined,
                          color: Colors.grey[600], size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(address,
                              style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11),
                              overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
