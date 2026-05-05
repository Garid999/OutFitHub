import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_theme.dart';

class DeliveryAddressScreen extends StatefulWidget {
  const DeliveryAddressScreen({super.key});

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  AppColors c = AppColors.light;

  final _cityCtrl     = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _khorooCtrl   = TextEditingController();
  final _streetCtrl   = TextEditingController();
  final _floorCtrl    = TextEditingController();
  final _doorCtrl     = TextEditingController();
  bool _isLoading  = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _khorooCtrl.dispose();
    _streetCtrl.dispose();
    _floorCtrl.dispose();
    _doorCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAddress() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(uid).get();
      final addr = snap.data()?['address'] as Map<String, dynamic>?;
      if (addr != null && mounted) {
        setState(() {
          _cityCtrl.text     = addr['city']     ?? '';
          _districtCtrl.text = addr['district'] ?? '';
          _khorooCtrl.text   = addr['khoroo']   ?? '';
          _streetCtrl.text   = addr['street']   ?? '';
          _floorCtrl.text    = addr['floor']    ?? '';
          _doorCtrl.text     = addr['door']     ?? '';
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isFetching = false);
  }

  Future<void> _save() async {
    if (_cityCtrl.text.trim().isEmpty || _districtCtrl.text.trim().isEmpty) {
      _snack('Хот/Аймаг болон Дүүрэгээ оруулна уу');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'address': {
          'city':     _cityCtrl.text.trim(),
          'district': _districtCtrl.text.trim(),
          'khoroo':   _khorooCtrl.text.trim(),
          'street':   _streetCtrl.text.trim(),
          'floor':    _floorCtrl.text.trim(),
          'door':     _doorCtrl.text.trim(),
        }
      }, SetOptions(merge: true));
      if (!mounted) return;
      _snack('Хаяг амжилттай хадгалагдлаа');
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      _snack('Алдаа гарлаа');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: c.primary));

  @override
  Widget build(BuildContext context) {
    c = context.c;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: const Text('Хүргэлтийн хаяг')),
      body: _isFetching
          ? Center(child: CircularProgressIndicator(color: c.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            color: c.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Захиалга хийхэд энэ хаяг ашиглагдана',
                            style: TextStyle(
                                color: c.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(child: _field('Хот / Аймаг', _cityCtrl,
                          Icons.location_city_outlined, hint: 'Улаанбаатар')),
                      const SizedBox(width: 12),
                      Expanded(child: _field('Дүүрэг / Сум', _districtCtrl,
                          Icons.map_outlined, hint: 'Сүхбаатар')),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(child: _field('Хороо', _khorooCtrl,
                          Icons.grid_view_outlined,
                          hint: '1-р хороо', keyType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('Байр / Гудамж', _streetCtrl,
                          Icons.home_outlined, hint: 'Найрамдал байр')),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(child: _field('Давхар', _floorCtrl,
                          Icons.layers_outlined,
                          hint: '3', keyType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('Тоот', _doorCtrl,
                          Icons.door_front_door_outlined,
                          hint: '42', keyType: TextInputType.number)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Preview
                  if (_cityCtrl.text.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.preview_outlined,
                                  color: c.primary, size: 16),
                              const SizedBox(width: 6),
                              Text('Хаягийн дэлгэрэнгүй',
                                  style: TextStyle(
                                      color: c.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_buildPreview(),
                              style: TextStyle(
                                  color: c.textPrimary,
                                  fontSize: 13,
                                  height: 1.6)),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  _isLoading
                      ? Center(child: CircularProgressIndicator(color: c.primary))
                      : ElevatedButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save_outlined,
                              color: Colors.white, size: 18),
                          label: const Text('Хаяг хадгалах',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                        ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  String _buildPreview() {
    final parts = <String>[];
    if (_cityCtrl.text.isNotEmpty) parts.add(_cityCtrl.text.trim());
    if (_districtCtrl.text.isNotEmpty) parts.add(_districtCtrl.text.trim());
    if (_khorooCtrl.text.isNotEmpty) parts.add('${_khorooCtrl.text.trim()}-р хороо');
    if (_streetCtrl.text.isNotEmpty) parts.add(_streetCtrl.text.trim());
    if (_floorCtrl.text.isNotEmpty) parts.add('${_floorCtrl.text.trim()}-р давхар');
    if (_doorCtrl.text.isNotEmpty) parts.add('${_doorCtrl.text.trim()}-р тоот');
    return parts.join(', ');
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {String hint = '', TextInputType keyType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: c.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyType,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: c.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: c.primary, size: 18),
            hintText: hint,
            hintStyle: TextStyle(color: c.textSecondary, fontSize: 13),
            filled: true,
            fillColor: c.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: c.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: c.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: c.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
