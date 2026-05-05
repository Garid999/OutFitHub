import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/notifications_helper.dart';

class AdminEventFormScreen extends StatefulWidget {
  const AdminEventFormScreen({super.key});
  @override
  State<AdminEventFormScreen> createState() => _AdminEventFormScreenState();
}

class _AdminEventFormScreenState extends State<AdminEventFormScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _valueCtrl = TextEditingController();

  String _discountType    = 'percent';
  String _category        = 'Бүгд';
  DateTime _startDate     = DateTime.now();
  DateTime _endDate       = DateTime.now().add(const Duration(days: 7));
  bool _saving            = false;
  List<String> _selectedProductIds = []; // empty = all in category

  static const List<String> _categories = [
    'Бүгд', 'Demon Slayer', 'Bleach', 'Chainsaw Man', 'Attack on Titan',
    'Hunter x Hunter', 'Jujutsu Kaisen', 'Solo Leveling',
    'Kaiju 8', 'Dr. Stone', 'Mashle', 'Hoodie',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFFE53935)),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) { _startDate = picked; }
      else         { _endDate   = picked; }
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final desc  = _descCtrl.text.trim();
    final val   = double.tryParse(_valueCtrl.text.trim());

    if (title.isEmpty) { _snack('Гарчиг оруулна уу'); return; }
    if (val == null || val <= 0) { _snack('Хямдралын утга оруулна уу'); return; }

    setState(() => _saving = true);
    try {
      // Save event to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('events')
          .add({
        'title':        title,
        'description':  desc,
        'discountType': _discountType,
        'discountValue': val,
        'category':    _category,
        'productIds':  _selectedProductIds, // empty = all in category
        'startDate':   Timestamp.fromDate(_startDate),
        'endDate':     Timestamp.fromDate(_endDate),
        'isActive':    true,
        'createdAt':   FieldValue.serverTimestamp(),
      });

      // Broadcast notification to all users
      final discountText = _discountType == 'percent'
          ? '${val.toInt()}% хямдрал'
          : '${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}₮ хямдрал';

      final catText = _category == 'Бүгд' ? 'бүх бараанд' : '$_category ангилалд';

      await NotifHelper.broadcast(
        type: 'event',
        title: '🎉 $title',
        body: '$catText $discountText! ${_fmtDate(_startDate)} – ${_fmtDate(_endDate)}',
        data: {'eventId': docRef.id},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Event нийтлэгдэж, бүх хэрэглэгчид мэдэгдсэн!'),
          backgroundColor: Colors.green,
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

  String _fmtDate(DateTime d) =>
      '${d.month}/${d.day}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Шинэ арга хэмжээ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: Color(0xFFE53935), strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Нийтлэх',
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
            _card([
              _field(_titleCtrl, 'Гарчиг', 'Жишээ: Зуны хямдрал 🎉',
                  Icons.title_rounded),
              const SizedBox(height: 12),
              _field(_descCtrl, 'Тайлбар', 'Дэлгэрэнгүй мэдээлэл...',
                  Icons.description_outlined, maxLines: 3),
            ], 'Мэдэгдлийн мэдээлэл'),

            const SizedBox(height: 16),

            _card([
              // Discount type
              Row(
                children: [
                  _typeBtn('percent', '%'),
                  const SizedBox(width: 10),
                  _typeBtn('fixed', '₮'),
                ],
              ),
              const SizedBox(height: 12),
              _field(_valueCtrl, 'Хямдралын утга',
                  _discountType == 'percent' ? 'Жишээ: 20' : 'Жишээ: 5000',
                  Icons.local_offer_rounded,
                  type: TextInputType.number),
            ], 'Хямдрал'),

            const SizedBox(height: 16),

            _card([
              _label('Ангилал'),
              const SizedBox(height: 8),
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
            ], 'Хамрах хүрээ'),

            const SizedBox(height: 16),

            // Product selector
            _card([
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where('isActive', isEqualTo: true)
                    .snapshots(),
                builder: (_, snap) {
                  final docs = snap.data?.docs ?? [];
                  final filtered = _category == 'Бүгд'
                      ? docs
                      : docs.where((d) =>
                          (d.data() as Map)['category'] == _category).toList();

                  if (filtered.isEmpty) {
                    return Text('Энэ ангилалд бараа байхгүй',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12));
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _selectedProductIds.isEmpty
                                ? 'Бүгд (${filtered.length} бараа)'
                                : '${_selectedProductIds.length} сонгогдсон',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() =>
                                _selectedProductIds = _selectedProductIds.length == filtered.length
                                    ? []
                                    : filtered.map((d) => d.id).toList()),
                            child: Text(
                              _selectedProductIds.length == filtered.length
                                  ? 'Бүгдийг цуцлах'
                                  : 'Бүгдийг сонгох',
                              style: const TextStyle(
                                  color: Color(0xFFE53935),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...filtered.map((doc) {
                        final d     = doc.data() as Map<String, dynamic>;
                        final name  = d['name']  as String? ?? '';
                        final price = (d['price'] as num?)?.toInt() ?? 0;
                        final sel   = _selectedProductIds.contains(doc.id);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (sel) {
                              _selectedProductIds.remove(doc.id);
                            } else {
                              _selectedProductIds.add(doc.id);
                            }
                          }),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFFE53935).withValues(alpha: 0.1)
                                  : const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: sel
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFF3A3A3A),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  sel
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
                                  color: sel
                                      ? const Color(0xFFE53935)
                                      : Colors.grey,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(name,
                                      style: TextStyle(
                                          color: sel
                                              ? const Color(0xFFE53935)
                                              : Colors.white70,
                                          fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                Text('${price * 1000}₮',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ], 'Бараа сонгох (хоосон = ангилал бүгд)'),

            const SizedBox(height: 16),

            _card([
              Row(
                children: [
                  Expanded(child: _datePicker('Эхлэх огноо', _startDate, () => _pickDate(true))),
                  const SizedBox(width: 10),
                  Expanded(child: _datePicker('Дуусах огноо', _endDate, () => _pickDate(false))),
                ],
              ),
            ], 'Хугацаа'),

            const SizedBox(height: 24),

            // Info box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFE53935).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.notifications_active_rounded,
                      color: Color(0xFFE53935), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '"Нийтлэх" дарахад бүх хэрэглэгчид мэдэгдэл илгээгдэнэ.',
                      style: TextStyle(
                          color: Color(0xFFE53935),
                          fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

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
                  _saving ? 'Нийтэлж байна...' : '📣 Нийтлэж мэдэгдэл явуулах',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15,
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

  Widget _card(List<Widget> children, String title) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    ],
  );

  Widget _field(TextEditingController ctrl, String label, String hint,
      IconData icon, {TextInputType type = TextInputType.text, int maxLines = 1}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      );

  Widget _label(String t) => Text(t,
      style: const TextStyle(color: Colors.grey, fontSize: 12));

  Widget _typeBtn(String type, String label) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _discountType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        decoration: BoxDecoration(
          color: _discountType == type
              ? const Color(0xFFE53935).withValues(alpha: 0.15)
              : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _discountType == type
                ? const Color(0xFFE53935)
                : const Color(0xFF3A3A3A),
            width: _discountType == type ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            type == 'percent' ? 'Хувиар (%)' : 'Мөнгөөр (₮)',
            style: TextStyle(
              color: _discountType == type
                  ? const Color(0xFFE53935)
                  : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _datePicker(String label, DateTime date, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: Color(0xFFE53935), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
