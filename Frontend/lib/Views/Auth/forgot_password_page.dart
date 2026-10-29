import 'package:flutter/material.dart';
import 'package:sporta/Core/Theme/app_tokens.dart';
import 'package:sporta/Core/Utils/app_logger.dart';
import 'package:sporta/Core/Utils/validators.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:sporta/Widgets/Buttons/app_buttons.dart';
import 'package:sporta/Widgets/Cards/app_card.dart';
import 'package:sporta/Widgets/Inputs/app_text_field.dart';

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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _isSent
                    ? _confirmationStep(context)
                    : _requestStep(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _requestStep(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      key: const ValueKey('forgot-password-request'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.lock_reset_rounded,
              size: AppSpacing.xxl,
              color: scheme.secondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Reset your password',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Enter your email and we’ll send instructions if an account is associated with it.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_errorMessage != null) ...[
              _ForgotPasswordErrorBanner(message: _errorMessage!),
              const SizedBox(height: AppSpacing.md),
            ],
            AppTextField(
              controller: _email,
              label: 'Email address',
              hint: 'your@email.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _sendResetLink(),
              validator: Validators.email,
            ),
            const SizedBox(height: AppSpacing.md),
            AppPrimaryButton(
              label: 'Send reset instructions',
              icon: Icons.send_rounded,
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _sendResetLink,
            ),
          ],
        ),
      ),
    );
  }

  Widget _confirmationStep(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      key: const ValueKey('forgot-password-confirmation'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            size: AppSpacing.xxl,
            color: scheme.secondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Check your inbox',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'If an account exists for this email address, password reset instructions will arrive shortly.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: 'Back to login',
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _ForgotPasswordErrorBanner extends StatelessWidget {
  const _ForgotPasswordErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
