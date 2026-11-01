import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sporta/Core/Theme/app_palette.dart';
import 'package:sporta/Core/Theme/app_tokens.dart';
import 'package:sporta/Core/Utils/app_logger.dart';
import 'package:sporta/Core/Utils/validators.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:sporta/Views/Auth/login_page.dart';

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
  String? _errorMessage;

  final _storage = const FlutterSecureStorage();

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_agreed) {
      setState(
        () => _errorMessage =
            'Please agree to the Terms of Service and Privacy Policy',
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final response = await PlayerManagerAuthService.register(
          username: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text.trim(),
          phone: _phone.text.trim(),
        );

        if (response['id'] != null) {
          if (!mounted) return;
          final p = AppPalette.of(context);
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppPalette.lime,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Account created successfully! Please login.',
                      style: TextStyle(color: p.text),
                    ),
                  ),
                ],
              ),
              backgroundColor: p.elevated,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
          setState(() {
            _isLoading = false;
            _errorMessage = 'Registration failed. Please try again.';
          });
        }
      } catch (error) {
        AppLogger.error('Registration error: $error');
        final message = error.toString().replaceFirst('Exception: ', '');
        final normalizedMessage = message.toLowerCase();
        setState(() {
          _isLoading = false;
          _errorMessage =
              normalizedMessage.contains('429') ||
                  normalizedMessage.contains('too many') ||
                  normalizedMessage.contains('rate limit')
              ? 'Too many attempts, try again later'
              : message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // Solid dark background, no gradients or glows.
      backgroundColor: p.background,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Back button ────────────────────────────────
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          backgroundColor: p.surface,
                          side: BorderSide(color: p.border),
                        ),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: p.text,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Brand wordmark ─────────────────────────────
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Semantics(
                        label: 'Sporta',
                        child: ExcludeSemantics(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'SPORTA',
                                style: textTheme.headlineSmall?.copyWith(
                                  color: p.text,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsetsDirectional.only(
                                  bottom: 7,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppPalette.lime,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Headline ───────────────────────────────────
                    Semantics(
                      header: true,
                      child: Text(
                        'Join the community',
                        style: textTheme.headlineLarge?.copyWith(
                          color: p.text,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Create your account and get ready to play.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: p.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Form ───────────────────────────────────────
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_errorMessage != null) ...[
                            _SignUpErrorBanner(
                              message: _errorMessage!,
                              p: p,
                              textTheme: textTheme,
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          TextFormField(
                            controller: _name,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            validator: (value) =>
                                (value == null || value.trim().length < 3)
                                ? 'Name must be at least 3 characters'
                                : null,
                            style: textTheme.bodyLarge?.copyWith(
                              color: p.text,
                            ),
                            cursorColor: AppPalette.lime,
                            decoration: _decoration(
                              p: p,
                              label: 'Full name',
                              hint: 'Your name',
                              icon: Icons.person_outline_rounded,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            validator: Validators.email,
                            style: textTheme.bodyLarge?.copyWith(
                              color: p.text,
                            ),
                            cursorColor: AppPalette.lime,
                            decoration: _decoration(
                              p: p,
                              label: 'Email address',
                              hint: 'your@email.com',
                              icon: Icons.email_outlined,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            validator: Validators.phone,
                            style: textTheme.bodyLarge?.copyWith(
                              color: p.text,
                            ),
                            cursorColor: AppPalette.lime,
                            decoration: _decoration(
                              p: p,
                              label: 'Phone number',
                              hint: '+216',
                              icon: Icons.phone_outlined,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.newPassword,
                            ],
                            validator: Validators.password,
                            style: textTheme.bodyLarge?.copyWith(
                              color: p.text,
                            ),
                            cursorColor: AppPalette.lime,
                            decoration: _decoration(
                              p: p,
                              label: 'Password',
                              hint: 'At least 6 characters',
                              icon: Icons.lock_outline_rounded,
                              suffix: IconButton(
                                tooltip: _obscure
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: p.muted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _confirm,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [
                              AutofillHints.newPassword,
                            ],
                            onFieldSubmitted: (_) => _register(),
                            validator: (value) =>
                                Validators.confirmPassword(
                                  value,
                                  _password.text,
                                ),
                            style: textTheme.bodyLarge?.copyWith(
                              color: p.text,
                            ),
                            cursorColor: AppPalette.lime,
                            decoration: _decoration(
                              p: p,
                              label: 'Confirm password',
                              hint: 'Re-enter your password',
                              icon: Icons.lock_outline_rounded,
                              suffix: IconButton(
                                tooltip: _obscureConfirm
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: p.muted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // ── Terms agreement ────────────────────────
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() {
                              _agreed = !_agreed;
                              _errorMessage = null;
                            }),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: _agreed,
                                  onChanged: (value) => setState(() {
                                    _agreed = value ?? false;
                                    _errorMessage = null;
                                  }),
                                  activeColor: AppPalette.lime,
                                  checkColor: AppPalette.onLime,
                                  side: BorderSide(
                                    color: p.muted,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional
                                        .symmetric(
                                      vertical: AppSpacing.xs,
                                    ),
                                    child: Text(
                                      'I agree to the Terms of Service and Privacy Policy.',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: p.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // ── Primary action ─────────────────────────
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed:
                                  _isLoading || !_agreed ? null : _register,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppPalette.lime,
                                foregroundColor: AppPalette.onLime,
                                disabledBackgroundColor:
                                    _isLoading
                                        ? AppPalette.lime.withValues(alpha: 0.6)
                                        : p.border,
                                disabledForegroundColor:
                                    _isLoading
                                        ? AppPalette.onLime.withValues(alpha: 0.6)
                                        : p.muted,
                                shape: const StadiumBorder(),
                                textStyle: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          AppPalette.onLime,
                                        ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('Create account'),
                                        SizedBox(width: AppSpacing.xs),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Back to login ──────────────────────────────
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: textTheme.bodyMedium?.copyWith(
                            color: p.muted,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: p.text,
                            minimumSize: const Size(48, 48),
                            textStyle: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          child: const Text('Log in'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration({
    required AppPalette p,
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: p.muted),
      floatingLabelStyle: TextStyle(color: p.text),
      hintStyle: TextStyle(color: p.muted.withValues(alpha: 0.7)),
      errorStyle: TextStyle(color: p.error),
      prefixIcon: Icon(icon, color: p.muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: p.surface,
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      enabledBorder: border(p.border),
      focusedBorder: border(p.focus, 2),
      errorBorder: border(p.error),
      focusedErrorBorder: border(p.error, 2),
    );
  }
}

class _SignUpErrorBanner extends StatelessWidget {
  const _SignUpErrorBanner({
    required this.message,
    required this.p,
    required this.textTheme,
  });

  final String message;
  final AppPalette p;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: p.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.error.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: p.error),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: textTheme.bodyMedium?.copyWith(color: p.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}