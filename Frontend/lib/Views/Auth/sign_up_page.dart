import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Core/Utils/validators.dart';
import 'package:sporta/Views/Auth/login_page.dart';
import 'package:sporta/Widgets/Inputs/app_input_field.dart';
import 'package:sporta/Widgets/Shared/auth_header.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _agreed = false;
  bool _isLoading = false;

  final _storage = const FlutterSecureStorage();

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) c.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_agreed) {
      _showErrorDialog('Please agree to the Terms of Service and Privacy Policy');
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        print('=== REGISTRATION ATTEMPT ===');
        print('Username: ${_name.text.trim()}');
        print('Email: ${_email.text.trim()}');
        print('Phone: ${_phone.text.trim()}');

        final response = await PlayerManagerAuthService.register(
          username: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text.trim(),
          phone: _phone.text.trim(),
        );

        print('Response: $response');

        if (response['id'] != null) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Account created successfully! Please login.'),
              backgroundColor: kGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          
          // Navigate back to login page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        } else {
          setState(() => _isLoading = false);
          _showErrorDialog('Registration failed. Please try again.');
        }
      } catch (error) {
        print('Registration error: $error');
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
          'Registration Failed',
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

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    body: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        children: [
          AuthHeader(
            heightFactor: 0.25,
            subtitle: 'Create your account',
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Join the community 🏆',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Fill in your details to get started',
                    style: TextStyle(fontSize: 14, color: kTextMid),
                  ),
                  const SizedBox(height: 20),

                  // ── Fields ─────────────────────────────────────────────
                  _field(
                    'Full Name',
                    _name,
                    'Mohamed Ali',
                    Icons.person_outline,
                    validator: (v) => (v == null || v.trim().length < 3)
                        ? 'Name must be at least 3 characters'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _field(
                    'Email Address',
                    _email,
                    'your@email.com',
                    Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  _field(
                    'Phone Number',
                    _phone,
                    '+216 XX XXX XXX',
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: Validators.phone,
                  ),
                  const SizedBox(height: 16),
                  _field(
                    'Password',
                    _password,
                    '••••••••',
                    Icons.lock_outline,
                    obscure: _obscure,
                    toggle: () => setState(() => _obscure = !_obscure),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 16),
                  _field(
                    'Confirm Password',
                    _confirm,
                    '••••••••',
                    Icons.lock_outline,
                    obscure: _obscureConfirm,
                    toggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    validator: (v) =>
                        Validators.confirmPassword(v, _password.text),
                  ),
                  const SizedBox(height: 20),

                  // ── Terms ──────────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreed,
                        onChanged: (v) => setState(() => _agreed = v ?? false),
                        activeColor: kPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: BorderSide(color: Colors.grey[400]!, width: 1.5),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    'By creating an account, you agree to our ',
                              ),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: kPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: kPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Create button ──────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : (_agreed ? _register : null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _agreed ? Colors.white : Colors.grey[500],
                                  ),
                                ),
                                if (_agreed) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Login link ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(fontSize: 14, color: kTextMid),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Log in',
                          style: TextStyle(
                            fontSize: 14,
                            color: kPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    VoidCallback? toggle,
    String? Function(String?)? validator,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: _label),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        obscureText: obscure,
        decoration: appInputDecoration(hint, icon).copyWith(
          suffixIcon: toggle == null
              ? null
              : IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: toggle,
                ),
        ),
        validator: validator,
      ),
    ],
  );
}

const _label = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w700,
  color: kTextDark,
);