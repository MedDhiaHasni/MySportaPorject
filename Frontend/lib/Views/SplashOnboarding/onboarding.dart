import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:sporta/Views/Auth/login_page.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final PageController controlleronboard = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    controlleronboard.addListener(() {
      setState(() {
        _currentPage = controlleronboard.page?.round() ?? 0;
      });
    });
  }

  // 7keyet securite
  @override
  void dispose() {
    controlleronboard.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(
      context,
    ).size; // mochkelt l'ecran mta3 l'emulateur

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // Pages
          PageView(
            controller: controlleronboard,
            children: [
              _buildPage(
                context: context,
                size: size,
                imagePath: 'assets/onb1.png',
                tagline: 'BOOK & PLAY',
                title: 'Book Matches\nInstantly',
                description:
                    'Reserve your slot, organize your game,\nand hit the field — all in seconds.',
                bgColor: const Color(0xFFFFF8F0),
                accentColor: const Color(0xFF005D5E),
                decorColor: const Color(0xFFFFDDB3),
              ),
              _buildPage(
                context: context,
                size: size,
                imagePath: 'assets/onb2.png',
                tagline: 'FIND YOUR TEAM',
                title: 'Connect With\nOther Players',
                description:
                    'Find teammates, join open matches,\nand grow your sports network.',
                bgColor: const Color(0xFFF0F8F8),
                accentColor: const Color(0xFF005D5E),
                decorColor: const Color(0xFFB2DFDB),
              ),
              _buildPage(
                context: context,
                size: size,
                imagePath: 'assets/onb3.png',
                tagline: 'MANAGE & WIN',
                title: 'Run Your\nComplex Smarter',
                description:
                    'Manage bookings, track revenue,\nand grow your sports facility effortlessly.',
                bgColor: const Color(0xFFF5F0FF),
                accentColor: const Color(0xFF005D5E),
                decorColor: const Color(0xFFCFBDFF),
              ),
            ],
          ),

          // Skip button wa7la fih
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: TextButton(
                  onPressed: _goToLogin,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    backgroundColor: Colors.white.withOpacity(
                      0.8,
                    ), // yechbah lel bg li fel figma
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Skip',
                        style: TextStyle(
                          color: Color(0xFF005D5E),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        color: Color(0xFF005D5E),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom bar: indicator + button
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SmoothPageIndicator(
                      controller: controlleronboard,
                      count: 3,
                      effect: const ExpandingDotsEffect(
                        activeDotColor: Color(0xFF005D5E),
                        dotColor: Color(0xFFB2DFDB),
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 3,
                        spacing: 6,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (_currentPage < 2) {
                          controlleronboard.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _goToLogin();
                        }
                      },
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFF005D5E),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF005D5E).withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          _currentPage < 2
                              ? Icons.arrow_forward_rounded
                              : Icons.check_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({
    required BuildContext context,
    required Size size,
    required String imagePath,
    required String tagline,
    required String title,
    required String description,
    required Color bgColor,
    required Color accentColor,
    required Color decorColor,
  }) {
    return Column(
      children: [
        // Top image section — takes ~58% of screen
        Expanded(
          flex: 58,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background blob
              Container(color: bgColor),

              // douwera li mel louta
              Positioned(
                bottom: -60,
                left: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: decorColor.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // douwera li mel foug 3al limin
              Positioned(
                top: 60,
                right: -30,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: decorColor.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // douwera li mel foug 3al lisar
              Positioned(
                top: -20,
                left: 30,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // taswira
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 80,
                    bottom: 24,
                    left: 32,
                    right: 32,
                  ),
                  child: Image.asset(imagePath, fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),

        // Bottom text section — takes ~42% of screen
        Expanded(
          flex: 42,
          child: Container(
            color: const Color(0xFFF5F5F5),
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tagline chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tagline,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Main title
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D0D0D),
                    fontSize: 34,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  description,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
