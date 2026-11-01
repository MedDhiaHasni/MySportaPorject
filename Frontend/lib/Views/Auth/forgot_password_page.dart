import 'package:flutter/material.dart';
import 'package:sporta/Core/Theme/app_tokens.dart';
import 'package:sporta/Core/Utils/app_logger.dart';
import 'package:sporta/Core/Utils/validators.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Graphite + Lime palette (temporary: move into app_tokens.dart).
// Lime is only ever a FILL with dark text. Never lime text on light surfaces.
// ─────────────────────────────────────────────────────────────────────────────
class _Palette {
  const _Palette({
    required this.background,
    required this.surface,
    required this.border,
    required this.focus,
    required this.text,
    required this.muted,
    required this.error,
  });

  final Color background;
  final Color surface;
  final Color border;
  final Color focus;
  final Color text;
  final Color muted;
  final Color error;

  static const Color lime = Color(0xFFC6F432);
  static const Color onLime = Color(0xFF0E1412);

  static const _Palette dark = _Palette(
    background: Color(0xFF0B0E0D),
    surface: Color(0xFF151A18),
    border: Color(0xFF2A322F),
    focus: Color(0xFFC6F432),
    text: Color(0xFFF4F6F5),
    muted: Color(0xFF9AA5A1),
    error: Color(0xFFFF8A80),
  );

  static const _Palette light = _Palette(
    background: Color(0xFFF5F6F4),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE3E7E4),
    focus: Color(0xFF0E1412),
    text: Color(0xFF0E1412),
    muted: Color(0xFF5B6661),
    error: Color(0xFFE5484D),
  );

  static _Palette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

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
  String? _errorMessage;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await PlayerManagerAuthService.forgotPassword(_email.text.trim());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSent = true;
      });
    } catch (error) {
      AppLogger.error('Error sending reset link: $error');
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: [
          // Soft lime glow at the top (dark mode only).
          if (isDark)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 360,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -1.1),
                      radius: 0.9,
                      colors: [
                        _Palette.lime.withValues(alpha: 0.12),
                        _Palette.lime.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Back button ──────────────────────────────────
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
                          icon: Icon(Icons.arrow_back_rounded, color: p.text),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ── Step content ─────────────────────────────────
                      AnimatedSwitcher(
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        child: _isSent
                            ? _confirmationStep(context, p)
                            : _requestStep(context, p),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestStep(BuildContext context, _Palette p) {
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('forgot-password-request'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IconBadge(icon: Icons.lock_reset_rounded, palette: p),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            header: true,
            child: Text(
              'Reset your password',
              style: textTheme.headlineLarge?.copyWith(
                color: p.text,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Enter your email and we’ll send instructions if an account is associated with it.',
            style: textTheme.bodyLarge?.copyWith(color: p.muted),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_errorMessage != null) ...[
            _ForgotPasswordErrorBanner(message: _errorMessage!, palette: p),
            const SizedBox(height: AppSpacing.md),
          ],
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => _sendResetLink(),
            validator: Validators.email,
            style: textTheme.bodyLarge?.copyWith(color: p.text),
            cursorColor: p.text,
            decoration: _decoration(
              p,
              label: 'Email address',
              hint: 'your@email.com',
              icon: Icons.email_outlined,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _isLoading ? null : _sendResetLink,
              style: FilledButton.styleFrom(
                backgroundColor: _Palette.lime,
                foregroundColor: _Palette.onLime,
                disabledBackgroundColor: _Palette.lime,
                disabledForegroundColor: _Palette.onLime,
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _Palette.onLime,
                        ),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Send reset instructions'),
                        SizedBox(width: AppSpacing.xs),
                        Icon(Icons.send_rounded, size: 20),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmationStep(BuildContext context, _Palette p) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      key: const ValueKey('forgot-password-confirmation'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _IconBadge(
          icon: Icons.mark_email_read_outlined,
          palette: p,
          filled: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            'Check your inbox',
            style: textTheme.headlineLarge?.copyWith(
              color: p.text,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'If an account exists for this email address, password reset instructions will arrive shortly.',
          style: textTheme.bodyLarge?.copyWith(color: p.muted),
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: _Palette.lime,
              foregroundColor: _Palette.onLime,
              shape: const StadiumBorder(),
              textStyle: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back_rounded, size: 20),
                SizedBox(width: AppSpacing.xs),
                Text('Back to login'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration(
    _Palette p, {
    required String label,
    required String hint,
    required IconData icon,
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

// Rounded badge holding the step icon. Lime fill + dark icon when [filled],
// otherwise a neutral surface with a border.
class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.palette,
    this.filled = false,
  });

  final IconData icon;
  final _Palette palette;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ExcludeSemantics(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: filled ? _Palette.lime : palette.surface,
            borderRadius: BorderRadius.circular(24),
            border: filled ? null : Border.all(color: palette.border),
          ),
          child: Icon(
            icon,
            size: 34,
            color: filled ? _Palette.onLime : palette.text,
          ),
        ),
      ),
    );
  }
}

class _ForgotPasswordErrorBanner extends StatelessWidget {
  const _ForgotPasswordErrorBanner({
    required this.message,
    required this.palette,
  });

  final String message;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: palette.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.error.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: palette.error),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: textTheme.bodyMedium?.copyWith(color: palette.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}