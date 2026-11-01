import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sporta/Core/Theme/app_tokens.dart';
import 'package:sporta/Views/Auth/login_page.dart';

// Graphite + Lime palette (temporary: move into app_tokens.dart).
const Color _kBackground = Color(0xFF0B0E0D);
const Color _kPlaceholder = Color(0xFF151A18);
const Color _kText = Color(0xFFF4F6F5);
const Color _kMuted = Color(0xFF9AA5A1);
const Color _kLime = Color(0xFFC6F432);
const Color _kOnLime = Color(0xFF0E1412);

// Share of the screen height used by the photo. Try 0.55 to 0.70.
const double _kImageHeightFactor = 0.62;

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final PageController controlleronboard = PageController();
  int _currentPage = 0;

  static const _pages = [
    (
      image: 'assets/onb1.png',
      headline: 'Book matches instantly',
      benefit: 'Find an open slot and get your game on.',
    ),
    (
      image: 'assets/onb2.png',
      headline: 'Find your team',
      benefit: 'Meet players and join games near you.',
    ),
    (
      image: 'assets/onb3.png',
      headline: 'Your game, made easier',
      benefit: 'Get help with bookings whenever you need it.',
    ),
  ];

  @override
  void dispose() {
    controlleronboard.dispose();
    super.dispose();
  }

  void _goToLogin() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      HapticFeedback.selectionClick();
      controlleronboard.nextPage(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    } else {
      _goToLogin();
    }
  }

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final fade =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 220);
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: _kBackground,
      body: Stack(
        children: [
          // ── Layer 1: photos at full width, fading into the background ──
          Positioned.fill(
            child: PageView.builder(
              controller: controlleronboard,
              itemCount: _pages.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final item = _pages[index];
                final imageHeight =
                    MediaQuery.sizeOf(context).height * _kImageHeightFactor;

                return Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: imageHeight,
                      child: ClipRect(
                        child: Image.asset(
                          item.image,
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topCenter,
                          excludeFromSemantics: true,
                          errorBuilder: (context, error, stackTrace) =>
                              const ColoredBox(color: _kPlaceholder),
                        ),
                      ),
                    ),
                    // Fade: light scrim at the top, then into the background.
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: imageHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.12, 0.55, 1.0],
                            colors: [
                              _kBackground.withValues(alpha: 0.55),
                              _kBackground.withValues(alpha: 0.0),
                              _kBackground.withValues(alpha: 0.0),
                              _kBackground,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Layer 2: top bar, text, dots and button ────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Column(
                children: [
                  // Top bar: Skip (end side)
                  Row(
                    children: [
                      const Spacer(),
                      AnimatedOpacity(
                        duration: fade,
                        opacity: _isLastPage ? 0 : 1,
                        child: IgnorePointer(
                          ignoring: _isLastPage,
                          child: TextButton(
                            onPressed: _goToLogin,
                            style: TextButton.styleFrom(
                              foregroundColor: _kText,
                              backgroundColor:
                                  _kBackground.withValues(alpha: 0.55),
                              minimumSize: const Size(48, 48),
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              shape: const StadiumBorder(),
                              textStyle: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Skip'),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Text block (does not block swipes on the photo)
                  Expanded(
                    child: IgnorePointer(
                      child: Align(
                        alignment: AlignmentDirectional.bottomStart,
                        child: SingleChildScrollView(
                          reverse: true,
                          physics: const NeverScrollableScrollPhysics(),
                          child: AnimatedSwitcher(
                            duration: fade,
                            layoutBuilder: (current, previous) => Stack(
                              alignment: AlignmentDirectional.bottomStart,
                              children: [
                                ...previous,
                                if (current != null) current,
                              ],
                            ),
                            child: Column(
                              key: ValueKey<int>(_currentPage),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(_currentPage + 1).toString().padLeft(2, '0')} / '
                                  '${_pages.length.toString().padLeft(2, '0')}',
                                  style: textTheme.labelLarge?.copyWith(
                                    color: _kMuted,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  page.headline,
                                  style: textTheme.headlineLarge?.copyWith(
                                    color: _kText,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  page.benefit,
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: _kMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  _StepDots(count: _pages.length, current: _currentPage),

                  const SizedBox(height: AppSpacing.lg),

                  // Primary action: lime fill, dark text
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _nextPage,
                      style: FilledButton.styleFrom(
                        backgroundColor: _kLime,
                        foregroundColor: _kOnLime,
                        shape: const StadiumBorder(),
                        textStyle: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      icon: Icon(
                        _isLastPage
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      iconAlignment: IconAlignment.end,
                      label: Text(_isLastPage ? 'Get started' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Active = wide lime pill, inactive = translucent white dot.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label: 'Page ${current + 1} of $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(count, (i) {
            final active = i == current;
            return AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
              height: 8,
              width: active ? 28 : 8,
              decoration: BoxDecoration(
                color: active ? _kLime : _kText.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            );
          }),
        ),
      ),
    );
  }
}