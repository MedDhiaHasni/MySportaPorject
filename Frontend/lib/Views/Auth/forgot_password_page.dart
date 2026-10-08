import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Core/Utils/validators.dart';
import 'package:sporta/Widgets/Inputs/app_input_field.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        print('=== SENDING RESET LINK ===');
        print('Email: ${_email.text.trim()}');

        await PlayerManagerAuthService.forgotPassword(_email.text.trim());

        print('Reset link sent successfully');

        setState(() {
          _isLoading = false;
          _isSent = true;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password reset link sent to your email!'),
            backgroundColor: kGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        // Auto navigate back after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } catch (error) {
        print('Error sending reset link: $error');
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: kRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(
      backgroundColor: kBg,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextDark, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // ── Icon ──────────────────────────────────────────────────
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Image.asset(
                  'assets/envelope1.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.email_outlined,
                      size: 48,
                      color: kPrimary.withOpacity(0.6),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 28),

            const Text(
              'Forgot Password?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: kTextDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "No worries! Enter the email associated with your Sporta account and we'll send you a reset link.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: kTextMid, height: 1.6),
            ),
            const SizedBox(height: 36),

            // ── Email ──────────────────────────────────────────────────
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Email Address',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextDark),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: appInputDecoration('your@email.com', Icons.email_outlined),
              validator: Validators.email,
            ),
            const SizedBox(height: 28),

            // ── Send button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendResetLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Send Reset Link',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Back to login link ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Remember your password? ',
                  style: TextStyle(fontSize: 14, color: kTextMid),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Back to Login',
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
  );
}