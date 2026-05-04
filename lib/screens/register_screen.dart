import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  AppColors c = AppColors.light;
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus  = FocusNode();
  bool _obscure    = true;
  bool _isLoading  = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Бүх талбарыг бөглөнө үү')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      await cred.user?.updateDisplayName(_nameCtrl.text.trim());

      try {
        final uid = cred.user!.uid;
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': _emailCtrl.text.trim(),
          'displayName': _nameCtrl.text.trim(),
          'userDisplayId': 'U-${uid.substring(0, 6).toUpperCase()}',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final msg = switch (e.code) {
        'weak-password'       => 'Нууц үг хэтэрхий богино байна (доод тал нь 6 тэмдэгт)',
        'email-already-in-use' => 'Энэ имэйл хаяг бүртгэлтэй байна',
        'invalid-email'       => 'Имэйл хаяг буруу байна',
        _                     => 'Алдаа гарлаа (${e.code})',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: c.primary),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    c = context.c;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Logo
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: c.border, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x20000000),
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white,
                      child: Center(
                        child: Text('AS',
                            style: TextStyle(
                                color: c.primary,
                                fontSize: 40,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),
              Text('AnimeStore-д бүртгүүлэх',
                  style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
              SizedBox(height: 6),
              Text('Шинэ бүртгэл үүсгэх',
                  style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 14,
                      letterSpacing: 0.3)),

              const SizedBox(height: 48),

              // Full Name
              _label('Бүтэн нэр'),
              const SizedBox(height: 8),
              _inputField(
                controller: _nameCtrl,
                hint: 'Таны бүтэн нэр',
                icon: Icons.person_outline_rounded,
                action: TextInputAction.next,
                onSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
              ),

              const SizedBox(height: 20),

              // Email
              _label('Имэйл хаяг'),
              const SizedBox(height: 8),
              _inputField(
                controller: _emailCtrl,
                hint: 'email@example.com',
                icon: Icons.mail_outline_rounded,
                inputType: TextInputType.emailAddress,
                focusNode: _emailFocus,
                action: TextInputAction.next,
                onSubmitted: (_) => FocusScope.of(context).requestFocus(_passFocus),
              ),

              const SizedBox(height: 20),

              // Password
              _label('Нууц үг'),
              SizedBox(height: 8),
              TextField(
                controller: _passCtrl,
                focusNode: _passFocus,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) { if (!_isLoading) _register(); },
                style: TextStyle(color: c.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline_rounded,
                      color: c.primary),
                  hintText: 'Доод тал нь 6 тэмдэгт',
                  hintStyle: TextStyle(color: c.textSecondary, fontSize: 14),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: c.textSecondary, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  filled: true,
                  fillColor: c.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.primary, width: 1.5),
                  ),
                ),
              ),

              SizedBox(height: 32),

              _isLoading
                  ? CircularProgressIndicator(color: c.primary)
                  : ElevatedButton(
                      onPressed: _register,
                      child: const Text('БҮРТГҮҮЛЭХ',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2)),
                    ),

              SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Бүртгэлтэй юу? ',
                      style: TextStyle(color: c.textSecondary, fontSize: 14)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('Нэвтрэх',
                        style: TextStyle(
                            color: c.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: TextStyle(
                color: c.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    FocusNode? focusNode,
    void Function(String)? onSubmitted,
  }) =>
      TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: inputType,
        textInputAction: action,
        onSubmitted: onSubmitted,
        style: TextStyle(color: c.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: c.primary),
          hintText: hint,
          hintStyle: TextStyle(color: c.textSecondary, fontSize: 14),
          filled: true,
          fillColor: c.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.primary, width: 1.5),
          ),
        ),
      );
}
