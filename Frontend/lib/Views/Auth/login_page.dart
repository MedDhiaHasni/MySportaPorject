import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sporta/Core/Theme/app_palette.dart';
import 'package:sporta/Core/Theme/app_tokens.dart';
import 'package:sporta/Core/Utils/app_logger.dart';
import 'package:sporta/Core/Utils/validators.dart';
import 'package:sporta/Services/firebase_identity_service.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:sporta/Views/Auth/forgot_password_page.dart';
import 'package:sporta/Views/Auth/sign_up_page.dart';
import 'package:sporta/Views/Manager/manager_navigation.dart';
import 'package:sporta/Views/Player/navigation.dart';
import 'package:sporta/Views/Worker/worker_navigation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _remember = false;
  bool _obscure = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _storage = const FlutterSecureStorage();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      setState(() => _isLoading = true);

      try {
        final response = await PlayerManagerAuthService.login(
          email: _email.text.trim(),
          password: _password.text.trim(),
        );

        if (response['token'] != null) {
          final userRole = response['user']['user_role'];

          final userId = response['user']['id'].toString();
          final token = response['token'];

          await _storage.write(key: 'jwt_token', value: token);
          await _storage.write(key: 'user_role', value: userRole);
          await _storage.write(key: 'user_id', value: userId);
          await FirebaseIdentityService.instance.signInWithStrapiToken(
            token,
            force: true,
          );

          if (_remember) {
            await _storage.write(
              key: 'remember_email',
              value: _email.text.trim(),
            );
          } else {
            await _storage.delete(key: 'remember_email');
          }

          // Navigate based on user role
          if (userRole == 'manager') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ManagerNavigation(managerToken: token),
              ),
            );
          } else if (userRole == 'player') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => Navigation(playerToken: token)),
            );
          } else if (userRole == 'worker') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => WorkerNavigation(workerToken: token),
              ),
            );
          } else {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Invalid user role';
            });
          }
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No token received';
          });
        }
      } catch (error) {
        AppLogger.error('ERROR: $error');
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      // Solid dark background, no gradients or glows.
      backgroundColor: p.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: AutofillGroup(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Top section ────────────────────
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ── Brand wordmark ─────────────
                                Align(
                                  alignment:
                                      AlignmentDirectional.centerStart,
                                  child: Semantics(
                                    label: 'Sporta',
                                    child: ExcludeSemantics(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'SPORTA',
                                            style: textTheme.headlineSmall
                                                ?.copyWith(
                                              color: p.text,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 3,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            width: 10,
                                            height: 10,
                                            margin: const EdgeInsetsDirectional
                                                .only(bottom: 7),
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
                                const SizedBox(height: AppSpacing.xxl),

                                // ── Headline ───────────────────
                                Semantics(
                                  header: true,
                                  child: Text(
                                    'Welcome back',
                                    style: textTheme.headlineLarge
                                        ?.copyWith(
                                      color: p.text,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Log in to find your next game.',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: p.muted,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xl),

                                // ── Form ───────────────────────
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (_errorMessage != null) ...[
                                        _LoginErrorBanner(
                                          message: _errorMessage!,
                                          p: p,
                                          textTheme: textTheme,
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                      ],
                                      TextFormField(
                                        controller: _email,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [
                                          AutofillHints.email
                                        ],
                                        validator: Validators.email,
                                        style: textTheme.bodyLarge
                                            ?.copyWith(color: p.text),
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
                                        controller: _password,
                                        obscureText: _obscure,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.password
                                        ],
                                        onFieldSubmitted: (_) => _submit(),
                                        validator: Validators.password,
                                        style: textTheme.bodyLarge
                                            ?.copyWith(color: p.text),
                                        cursorColor: AppPalette.lime,
                                        decoration: _decoration(
                                          p: p,
                                          label: 'Password',
                                          hint: 'Enter your password',
                                          icon: Icons.lock_outline_rounded,
                                          suffix: IconButton(
                                            tooltip: _obscure
                                                ? 'Show password'
                                                : 'Hide password',
                                            onPressed: () => setState(
                                              () => _obscure = !_obscure,
                                            ),
                                            icon: Icon(
                                              _obscure
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
                                              color: p.muted,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),

                                      // ── Remember me + Forgot ───
                                      Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          InkWell(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            onTap: () => setState(
                                              () => _remember = !_remember,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Checkbox(
                                                  value: _remember,
                                                  onChanged: (value) =>
                                                      setState(
                                                    () => _remember =
                                                        value ?? false,
                                                  ),
                                                  activeColor:
                                                      AppPalette.lime,
                                                  checkColor:
                                                      AppPalette.onLime,
                                                  side: BorderSide(
                                                    color: p.muted,
                                                    width: 1.5,
                                                  ),
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsetsDirectional
                                                          .only(
                                                    end: AppSpacing.xs,
                                                  ),
                                                  child: Text(
                                                    'Remember me',
                                                    style: textTheme.bodyMedium
                                                        ?.copyWith(
                                                      color: p.muted,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const ForgotPasswordPage(),
                                              ),
                                            ),
                                            style: TextButton.styleFrom(
                                              foregroundColor: p.text,
                                              minimumSize:
                                                  const Size(48, 48),
                                              textStyle: textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                            child: const Text(
                                              'Forgot password?',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.md),

                                      // ── Primary action ─────────
                                      SizedBox(
                                        height: 52,
                                        child: FilledButton(
                                          onPressed:
                                              _isLoading ? null : _submit,
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AppPalette.lime,
                                            foregroundColor:
                                                AppPalette.onLime,
                                            disabledBackgroundColor:
                                                AppPalette.lime
                                                    .withValues(alpha: 0.6),
                                            disabledForegroundColor:
                                                AppPalette.onLime
                                                    .withValues(alpha: 0.6),
                                            shape: const StadiumBorder(),
                                            textStyle: textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                            Color>(
                                                      AppPalette.onLime,
                                                    ),
                                                  ),
                                                )
                                              : const Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .center,
                                                  children: [
                                                    Text('Log in'),
                                                    SizedBox(
                                                      width: AppSpacing.xs,
                                                    ),
                                                    Icon(
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      size: 20,
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),

                                      // ── Divider ────────────────
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              height: 1,
                                              color: p.border,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsetsDirectional
                                                .symmetric(
                                              horizontal: AppSpacing.sm,
                                            ),
                                            child: Text(
                                              'OR CONTINUE WITH',
                                              style: textTheme.labelMedium
                                                  ?.copyWith(
                                                color: p.muted,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              height: 1,
                                              color: p.border,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.md),

                                      // ── Google ─────────────────
                                      SizedBox(
                                        height: 52,
                                        child: OutlinedButton.icon(
                                          onPressed: () {},
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: p.text,
                                            backgroundColor: p.surface,
                                            side: BorderSide(
                                              color: p.border,
                                            ),
                                            shape: const StadiumBorder(),
                                            textStyle: textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          icon: Image.asset(
                                            'assets/google.png',
                                            width: 22,
                                            height: 22,
                                            semanticLabel: 'Google',
                                            errorBuilder:
                                                (context, error, stack) =>
                                                    Icon(
                                              Icons.g_mobiledata_rounded,
                                              color: p.text,
                                            ),
                                          ),
                                          label: const Text(
                                            'Continue with Google',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // ── Bottom section ─────────────────
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                top: AppSpacing.xxl,
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account?",
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: p.muted,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SignUpPage(),
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: p.text,
                                      minimumSize: const Size(48, 48),
                                      textStyle:
                                          textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    child: const Text('Sign up'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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

class _LoginErrorBanner extends StatelessWidget {
  const _LoginErrorBanner({
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