// Views/Admin/admin_login_page.dart
// REDESIGNED: Modern enterprise split-screen login — clean, minimal, professional
// Left: dark brand panel with geometric decoration
// Right: pure white form with floating labels and polished inputs
// All backend links preserved exactly.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Services/admin_auth_service.dart';
import 'package:sporta/Views/Admin/admindashboard.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Design Tokens 
const _t900  = Color(0xFF001A1B);
const _t700  = Color(0xFF002B2C);
const _t500  = Color(0xFF006B6C);
const _t400  = Color(0xFF009999);
const _t200  = Color(0xFF4DD9D9);
const _tGlow = Color(0xFF00F0F0);

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _storage      = const FlutterSecureStorage();

  bool _obscure   = true;
  bool _remember  = false;
  bool _isLoading = false;
  String? _errorMsg;

  late AnimationController _anim;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _anim  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut).drive(Tween(begin: 0.0, end: 1.0));
    _slide = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic).drive(Tween(begin: const Offset(0, 0.06), end: Offset.zero));
    _anim.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<void> _handleLogin() async {
    setState(() => _errorMsg = null);
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact(); // vibration sghir ki testarti login
    setState(() => _isLoading = true);

    try {
      final response = await AdminAuthService.login(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      if (response['token'] == null) {
        setState(() { _isLoading = false; _errorMsg = 'No token received'; });
        return;
      }

      if (response['user']['user_role'] != 'admin') {
        setState(() { _isLoading = false; _errorMsg = 'Access denied. Admin privileges required.'; });
        return;
      }

      final token = response['token'] as String;
      await _storage.write(key: 'jwt_token',  value: token);
      await _storage.write(key: 'user_role',  value: response['user']['user_role']);
      await _storage.write(key: 'user_id',    value: response['user']['id'].toString());

      if (_remember) {
        await _storage.write(key: 'remember_email', value: _emailCtrl.text.trim());
      } else {
        await _storage.delete(key: 'remember_email');
      }

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => AdminDashboard(adminToken: token, onLogout: () {}),
        ));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg  = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  // ── Forgot password ───────────────────────────────────────────────────────
  void _showForgotPassword() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _ForgotPasswordSheet(
          ctrl: ctrl,
          onSend: () async {
            if (ctrl.text.trim().isEmpty) return;
            Navigator.pop(context);
            try {
              await AdminAuthService.forgotPassword(email: ctrl.text.trim());
              if (mounted) _showSnack('Reset link sent ✓', isError: false);
            } catch (e) {
              if (mounted) _showSnack(e.toString(), isError: true);
            }
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? Colors.red.shade700 : _t400,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final isWide = size.width > 720;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  // ── WIDE: side-by-side ────────────────────────────────────────────────────
  Widget _buildWideLayout() => Row(children: [
    Expanded(flex: 5, child: _buildBrandPanel()),
    Expanded(flex: 4, child: _buildFormPanel()),
  ]);

  // ── NARROW: full-screen card ──────────────────────────────────────────────
  Widget _buildNarrowLayout() => Stack(children: [
    Positioned.fill(child: _buildBrandBackground()),
    SafeArea(child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: FadeTransition(opacity: _fade, child: SlideTransition(
          position: _slide,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 48, offset: const Offset(0, 16))],
            ),
            padding: const EdgeInsets.all(30),
            child: _buildFormContent(),
          ),
        )),
      ),
    )),
  ]);

  // ── Brand Panel (left) ────────────────────────────────────────────────────
  Widget _buildBrandPanel() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [_t900, _t700, Color(0xFF004D4E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Stack(children: [
      Positioned.fill(child: CustomPaint(painter: _GridPainter())),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo image
            Image.asset(
              'sportalogowhite.png',
              width: 70,
              height: 70,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    'LOGO',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Text(
                'Admin Dashboard',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
              ),
            ),
            const SizedBox(height: 52),
            // Main tagline — centered, large
            const Text(
              'Run your\nsports platform.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.05,
                letterSpacing: -2.0, 
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Manage courts, bookings, players,\nand workers — all from one place.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.55),
                height: 1.7,
              ),
            ),
            const SizedBox(height: 52),
            // Feature list - centered
            Center(
              child: Column(
                children: [
                  _FeatureRow(icon: Icons.speed_rounded, text: 'Real-time booking analytics'),
                  const SizedBox(height: 14),
                  _FeatureRow(icon: Icons.people_outline_rounded, text: 'Full user & role management'),
                  const SizedBox(height: 14),
                  _FeatureRow(icon: Icons.security_rounded, text: 'Enterprise-grade security'),
                ],
              ),
            ),
          ],
        ),
      ),
    ]),
  );

  // ── Brand background for narrow ──────────────────────────────────────────
  Widget _buildBrandBackground() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [_t900, _t700, Color(0xFF004D4E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Stack(children: [
      Positioned.fill(child: CustomPaint(painter: _GridPainter())),
    ]),
  );

  // ── Form Panel (right / card) ─────────────────────────────────────────────
  Widget _buildFormPanel() => Container(
    color: Colors.white,
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 40),
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: _buildFormContent(),
            ),
          ),
        ),
      ),
    ),
  );

  // ── Shared form content ───────────────────────────────────────────────────
  Widget _buildFormContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      // Header
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_t700, _t400], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: _t400.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
      ),
      const SizedBox(height: 20),
      const Text(
        'Welcome back',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0D1117), letterSpacing: -1.0),
      ),
      const SizedBox(height: 6),
      Text('Sign in to your admin account', style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.5)),
      const SizedBox(height: 32),

      // Error banner
      if (_errorMsg != null) ...[
        _ErrorBanner(message: _errorMsg!),
        const SizedBox(height: 20),
      ],

      // Form
      Form(
        key: _formKey,
        child: Column(children: [
          _FormField(
            controller: _emailCtrl,
            label: 'Email address',
            hint: 'admin@sporta.tn',
            icon: Icons.alternate_email_rounded,
            type: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _FormField(
            controller: _passwordCtrl,
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscure,
            suffix: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18,
                color: Colors.grey.shade400,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Must be at least 6 characters';
              return null;
            },
          ),
        ]),
      ),
      const SizedBox(height: 16),

      // Remember + Forgot row
      Row(children: [
        GestureDetector(
          onTap: () => setState(() => _remember = !_remember),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: _remember ? _t400 : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _remember ? _t400 : Colors.grey.shade300, width: 1.5),
              ),
              child: _remember ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
            ),
            const SizedBox(width: 8),
            Text('Remember me', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ]),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _showForgotPassword,
          child: Text('Forgot password?', style: TextStyle(fontSize: 13, color: _t400, fontWeight: FontWeight.w700)),
        ),
      ]),
      const SizedBox(height: 28),

      // Login button
      GestureDetector(
        onTap: _isLoading ? null : _handleLogin,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: _isLoading
                ? LinearGradient(colors: [_t400.withOpacity(0.4), _t400.withOpacity(0.4)])
                : const LinearGradient(colors: [_t700, _t400], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isLoading ? [] : [
              BoxShadow(color: _t400.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6)),
              BoxShadow(color: _t400.withOpacity(0.15), blurRadius: 40, offset: const Offset(0, 12)),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Sign in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.2)),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                  ]),
          ),
        ),
      ),
      const SizedBox(height: 24),

      // Secure note
      Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.lock_outline_rounded, size: 13, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Text('Secure · Encrypted · Admin only', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade400)),
      ])),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: _t400.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: _t200, size: 18),
      ),
      const SizedBox(width: 14),
      Text(text, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14.5, fontWeight: FontWeight.w600)),
    ],
  );
}


class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline_rounded, size: 16, color: Colors.red.shade600),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: TextStyle(fontSize: 13, color: Colors.red.shade700, fontWeight: FontWeight.w600, height: 1.4))),
      ],
    ),
  );
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType type;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.type = TextInputType.text,
    this.obscure = false,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF374151), letterSpacing: 0.2)),
      const SizedBox(height: 7),
      TextFormField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        style: const TextStyle(fontSize: 15, color: Color(0xFF0D1117), fontWeight: FontWeight.w500),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14.5),
          prefixIcon: Container(
            margin: const EdgeInsets.all(11),
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: _t400.withOpacity(0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: _t400),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 50, minHeight: 50),
          suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.only(right: 14), child: suffix) : null,
          filled: true,
          fillColor: const Color(0xFFF8FAFB),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _t400, width: 2.0)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.red.shade400, width: 1.4)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.red.shade500, width: 2.0)),
          errorStyle: TextStyle(fontSize: 11.5, color: Colors.red.shade600, fontWeight: FontWeight.w600),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// FORGOT PASSWORD BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _ForgotPasswordSheet extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSend, onCancel;
  const _ForgotPasswordSheet({required this.ctrl, required this.onSend, required this.onCancel});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 32, offset: const Offset(0, -4))],
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_t700, _t400], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 26),
      ),
      const SizedBox(height: 16),
      const Text('Reset your password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0D1117), letterSpacing: -0.5)),
      const SizedBox(height: 8),
      Text("Enter your email and we'll send you a reset link.", style: TextStyle(fontSize: 13.5, color: Colors.grey.shade500, height: 1.5), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      _FormField(
        controller: ctrl,
        label: 'Email address',
        hint: 'admin@sporta.tn',
        icon: Icons.alternate_email_rounded,
        type: TextInputType.emailAddress,
      ),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: GestureDetector(
          onTap: onCancel,
          child: Container(
            height: 50,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade600))),
          ),
        )),
        const SizedBox(width: 12),
        Expanded(child: GestureDetector(
          onTap: onSend,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_t700, _t400], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: _t400.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Center(child: Text('Send link', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14))),
          ),
        )),
      ]),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// GRID PAINTER — subtle dot grid background
// ─────────────────────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;

    const spacing = 36.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}



















/*// Views/Admin/admin_login_page.dart
// Design: split-screen layout — left side background illustration,
// right side white login card — matching the dashboard login screenshot.
// All backend links are preserved exactly.

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Services/admin_auth_service.dart';
import 'package:sporta/Views/Admin/admindashboard.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey        = GlobalKey<FormState>();
  final _emailCtrl      = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  final _storage        = const FlutterSecureStorage();

  bool _obscure    = true;
  bool _remember   = false;
  bool _isLoading  = false;
  String? _errorMsg;

  late AnimationController _anim;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _slide = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic)
        .drive(Tween(begin: const Offset(0, 0.08), end: Offset.zero));
    _anim.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<void> _handleLogin() async {
    setState(() => _errorMsg = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await AdminAuthService.login(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      if (response['token'] == null) {
        setState(() { _isLoading = false; _errorMsg = 'No token received'; });
        return;
      }

      if (response['user']['user_role'] != 'admin') {
        setState(() { _isLoading = false; _errorMsg = 'Access denied. Admin privileges required.'; });
        return;
      }

      final token = response['token'] as String;
      await _storage.write(key: 'jwt_token',  value: token);
      await _storage.write(key: 'user_role',  value: response['user']['user_role']);
      await _storage.write(key: 'user_id',    value: response['user']['id'].toString());

      if (_remember) {
        await _storage.write(key: 'remember_email', value: _emailCtrl.text.trim());
      } else {
        await _storage.delete(key: 'remember_email');
      }

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => AdminDashboard(adminToken: token, onLogout: () {}),
        ));
      }
    } catch (e) {
      setState(() { _isLoading = false; _errorMsg = e.toString().replaceAll('Exception:', '').trim(); });
    }
  }

  // ── Forgot password ───────────────────────────────────────────────────────
  void _showForgotPassword() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Enter your email and we\'ll send a reset link.', style: TextStyle(color: kTextMid, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'admin@sporta.tn',
              prefixIcon: const Icon(Icons.email_outlined, size: 18, color: kPrimary),
              filled: true, fillColor: kBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: kTextMid))),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              try {
                await AdminAuthService.forgotPassword(ctrl.text.trim());
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Reset link sent ✓'), backgroundColor: kGreen, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16)));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString()), backgroundColor: kRed, behavior: SnackBarBehavior.floating));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 720;

    return Scaffold(
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  // ── WIDE layout (tablet / web): side-by-side ──────────────────────────────
  Widget _buildWideLayout() {
    return Row(children: [
      Expanded(flex: 5, child: _buildLeftPanel()),
      Expanded(flex: 4, child: _buildRightPanel()),
    ]);
  }

  // ── NARROW layout (phone): full-screen card over background ───────────────
  Widget _buildNarrowLayout() {
    return Stack(children: [
      // Background — gradient + illustration placeholder
      Positioned.fill(child: _buildBackground()),
      // Scrollable card overlay
      SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: FadeTransition(opacity: _fade, child: SlideTransition(position: _slide, child: _buildCard())),
          ),
        ),
      ),
    ]);
  }

  // ── Left panel (illustration side) ───────────────────────────────────────
  Widget _buildLeftPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF002526), Color(0xFF005D5E), Color(0xFF009B97)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(children: [
        // ── Decorative circles ──────────────────────────────────────────────
        Positioned(top: -60, left: -60,
          child: Container(width: 260, height: 260,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)))),
        Positioned(bottom: -80, right: -50,
          child: Container(width: 320, height: 320,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)))),
        Positioned(top: 80, right: 30,
          child: Container(width: 100, height: 100,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),

        // ── Content ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(48),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Logo
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
              child: const Center(child: Text('⚽', style: TextStyle(fontSize: 26))),
            ),
            const SizedBox(height: 12),
            const Text('Sporta', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const Spacer(),
            // ── Illustration ─────────────────────────────────────────────────
            // Image is directly in assets folder
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/admin_illustration.jpg',  // ← Correct path
                height: 280,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image not found
                  return Container(
                    height: 280,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.dashboard_rounded,
                          size: 80,
                          color: Colors.white.withOpacity(0.35),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Admin Illustration',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Spacer(),
            // Bottom tagline
            const Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('Manage courts, bookings & users from one place.', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, height: 1.5)),
            const SizedBox(height: 40),
          ]),
        ),
      ]),
    );
  }

  // ── Right panel (form side for wide layout) ───────────────────────────────
  Widget _buildRightPanel() {
    return Container(
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
          child: FadeTransition(opacity: _fade, child: SlideTransition(position: _slide,
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 380), child: _buildFormContent()))),
        ),
      ),
    );
  }

  // ── Background for narrow layout ─────────────────────────────────────────
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF002526), Color(0xFF005D5E), Color(0xFF009B97)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(children: [
        Positioned(top: -40, left: -40,
          child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)))),
        Positioned(bottom: -60, right: -30,
          child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)))),
        // Add illustration to narrow layout as well
        Center(
          child: Opacity(
            opacity: 0.3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/admin_illustration.jpg',  // ← Correct path
                height: 200,
                width: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Card (for narrow layout) ──────────────────────────────────────────────
  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 40, offset: const Offset(0, 16))],
      ),
      padding: const EdgeInsets.all(28),
      child: _buildFormContent(),
    );
  }

  // ── Shared form content ───────────────────────────────────────────────────
  Widget _buildFormContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      // ── Title ──────────────────────────────────────────────────────────────
      Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.admin_panel_settings_rounded, color: kPrimary, size: 22),
        ),
        const SizedBox(width: 12),
        const Text('Dashboard Login', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kTextDark, letterSpacing: -0.4)),
      ]),
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.only(left: 56),
        child: Text('Sign in to manage your platform', style: TextStyle(fontSize: 12, color: kTextMid)),
      ),
      const SizedBox(height: 28),

      // ── Error banner ───────────────────────────────────────────────────────
      if (_errorMsg != null) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: kRed.withOpacity(0.07), borderRadius: BorderRadius.circular(10), border: Border.all(color: kRed.withOpacity(0.25))),
          child: Row(children: [
            Icon(Icons.error_outline_rounded, size: 16, color: kRed),
            const SizedBox(width: 8),
            Expanded(child: Text(_errorMsg!, style: const TextStyle(fontSize: 12, color: kRed, fontWeight: FontWeight.w600))),
          ]),
        ),
        const SizedBox(height: 16),
      ],

      // ── Form ───────────────────────────────────────────────────────────────
      Form(key: _formKey, child: Column(children: [
        // Username / Email field
        _buildField(
          ctrl:       _emailCtrl,
          label:      'Username',
          hint:       'admin@sporta.tn',
          icon:       Icons.person_outline_rounded,
          type:       TextInputType.emailAddress,
          validator:  (v) {
            if (v == null || v.isEmpty) return '* username field cannot be empty';
            if (!v.contains('@')) return '* enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Password field
        _buildField(
          ctrl:        _passwordCtrl,
          label:       'Password',
          hint:        '••••••••',
          icon:        Icons.lock_outline_rounded,
          obscure:     _obscure,
          suffix:      IconButton(
            icon:      Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: kTextLight),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return '* password field cannot be empty';
            if (v.length < 6)          return '* password must be at least 6 characters';
            return null;
          },
        ),
      ])),
      const SizedBox(height: 14),

      // ── Remember + Forgot ────────────────────────────────────────────────
      Row(children: [
        SizedBox(width: 18, height: 18, child: Checkbox(
          value: _remember, activeColor: kPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          side: BorderSide(color: kTextLight.withOpacity(0.5)),
          onChanged: (v) => setState(() => _remember = v ?? false),
        )),
        const SizedBox(width: 8),
        const Text('Remember me', style: TextStyle(fontSize: 12, color: kTextMid)),
        const Spacer(),
        GestureDetector(
          onTap: _showForgotPassword,
          child: const Text('Forgot Password?', style: TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w700)),
        ),
      ]),
      const SizedBox(height: 28),

      // ── Login button ─────────────────────────────────────────────────────
      SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, foregroundColor: Colors.white,
            elevation: 6, shadowColor: kPrimary.withOpacity(0.35),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.login_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Login to My Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                ]),
        ),
      ),
      const SizedBox(height: 20),

      // ── Secure note ───────────────────────────────────────────────────────
      Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.shield_outlined, size: 14, color: kTextLight),
        const SizedBox(width: 6),
        Text('Secure admin access only', style: TextStyle(fontSize: 11, color: kTextLight)),
      ])),
    ]);
  }

  // ── Reusable field ────────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextMid)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        keyboardType: type,
        obscureText: obscure,
        style: const TextStyle(fontSize: 14, color: kTextDark, fontWeight: FontWeight.w500),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: kTextLight.withOpacity(0.8), fontSize: 14),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            width: 30, height: 30,
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: kPrimary),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 46),
          suffixIcon: suffix,
          filled: true,
          fillColor: const Color(0xFFF6F8FB),
          border:         OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none),
          enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: const Color(0xFFE8EAF0))),
          focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: kPrimary, width: 1.8)),
          errorBorder:    OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: kRed, width: 1.4)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: kRed, width: 1.8)),
          errorStyle: const TextStyle(fontSize: 11, color: kRed, fontWeight: FontWeight.w600),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        ),
      ),
    ]);
  }
}


***************************************************


import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Services/admin_auth_service.dart';
import 'package:sporta/Views/Admin/admindashboard.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await AdminAuthService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (response['token'] != null) {
          final token = response['token'];
          
          // Check if user is admin
          if (response['user']['user_role'] != 'admin') {
            setState(() => _isLoading = false);
            _showErrorDialog('Access denied. Admin privileges required.');
            return;
          }

          // Save token and user info
          await _storage.write(key: 'jwt_token', value: token);
          await _storage.write(key: 'user_role', value: response['user']['user_role']);
          await _storage.write(key: 'user_id', value: response['user']['id'].toString());
          
          if (_rememberMe) {
            await _storage.write(key: 'remember_email', value: _emailController.text.trim());
          } else {
            await _storage.delete(key: 'remember_email');
          }

          // FIXED: Navigate to admin dashboard with token
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminDashboard(
                adminToken: token,  // Pass the token here
                onLogout: () {
                  // Optional: Handle logout
                },
              ),
            ),
          );
        }
      } catch (error) {
        setState(() => _isLoading = false);
        _showErrorDialog(error.toString());
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Login Failed',
          style: TextStyle(color: kRed, fontWeight: FontWeight.w800),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Reset Password',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: kTextDark,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your email address and we\'ll send you instructions to reset your password.',
              style: TextStyle(color: kTextMid, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 14, color: kTextDark),
                decoration: InputDecoration(
                  hintText: 'admin@sporta.tn',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: kTextLight.withOpacity(0.7),
                  ),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    size: 18,
                    color: kPrimary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: kBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: kTextMid, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter your email'),
                    backgroundColor: kRed,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              try {
                await AdminAuthService.forgotPassword(emailController.text.trim());
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Password reset link sent to your email'),
                    backgroundColor: kGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error.toString()),
                    backgroundColor: kRed,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } finally {
                setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
            ),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kPrimary,
              kPrimary.withOpacity(0.8),
              const Color(0xFF007B7D),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: _buildLoginCard(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: kPrimary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _LoginCardBackgroundPainter()),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 24),
                  _buildWelcomeText(),
                  const SizedBox(height: 32),
                  _buildLoginForm(),
                  const SizedBox(height: 20),
                  _buildRememberForgot(),
                  const SizedBox(height: 32),
                  _buildLoginButton(),
                  const SizedBox(height: 20),
                  _buildSecurityNote(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimary, kPrimary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.asset(
          'assets/test1.png',
          height: 80,
          width: 80,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                'Sporta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        const Text(
          'Welcome Back, Admin',
          style: TextStyle(
            color: kTextDark,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to manage your platform',
          style: TextStyle(color: kTextMid, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 15, color: kTextDark),
              decoration: InputDecoration(
                labelText: 'Email Address',
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kTextMid,
                ),
                floatingLabelStyle: TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.w600,
                ),
                hintText: 'Enter your email',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: kTextLight.withOpacity(0.7),
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  child: Icon(Icons.email_outlined, size: 20, color: kPrimary),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: kPrimary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: kRed, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: kRed, width: 2),
                ),
                filled: true,
                fillColor: kBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              style: const TextStyle(fontSize: 15, color: kTextDark),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kTextMid,
                ),
                floatingLabelStyle: TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.w600,
                ),
                hintText: 'Enter your password',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: kTextLight.withOpacity(0.7),
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: kPrimary,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: kTextLight,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: kPrimary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: kRed, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: kRed, width: 2),
                ),
                filled: true,
                fillColor: kBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRememberForgot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                activeColor: kPrimary,
                side: BorderSide(
                  color: kTextLight.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Remember me',
              style: TextStyle(
                color: kTextMid,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            _showForgotPasswordDialog();
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Forgot Password?',
            style: TextStyle(
              color: kPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: kPrimary.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign In to Dashboard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: kPrimary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 16, color: kPrimary),
          const SizedBox(width: 8),
          Text(
            'Secure admin access only',
            style: TextStyle(
              color: kTextMid,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for decorative card background
class _LoginCardBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kPrimary.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 50, paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.9), 30, paint);

    final dotPaint = Paint()
      ..color = kPrimary.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    for (double x = 20; x < size.width; x += 30) {
      for (double y = 20; y < size.height; y += 30) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}*/