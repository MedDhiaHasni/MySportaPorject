import 'package:flutter/material.dart';
import 'package:myapp/screens/LoginPage.dart';

class Onboarding2Content extends StatelessWidget {
  final int currentPage;

  const Onboarding2Content({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              left: -80,
              top: MediaQuery.of(context).size.height * 0.4,
              child: Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  color: Color(0xFF005D5E),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: -40,
              top: MediaQuery.of(context).size.height * 0.5,
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8B4A0),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'skip',
                            style: TextStyle(
                              color: Color(0xFF005D5E),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Color(0xFF005D5E),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  const Text(
                    'Connect With\nOther Players',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF005D5E),
                      fontSize: 32,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 40),

                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0E8),
                      borderRadius: BorderRadius.circular(140),
                    ),
                    child: const Image(
                      image: AssetImage("assets/onboarding-2.png"),
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 50),

                  const Text(
                    'Find teammates, join matches,\nand build your sports network',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF232624),
                      fontSize: 18,
                      height: 1.4,
                    ),
                  ),

                  const Spacer(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDot(0),
                      const SizedBox(width: 8),

                      _buildDot(1),
                      const SizedBox(width: 8),

                      _buildDot(2),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = currentPage == index;
    return Container(
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF005D5E) : Colors.transparent,
        border: Border.all(
          color: isActive ? const Color(0xFF005D5E) : const Color(0xFFCCCCCC),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class Onboarding2 extends StatelessWidget {
  const Onboarding2({super.key});

  @override
  Widget build(BuildContext context) {
    return const Onboarding2Content(currentPage: 1);
  }
}
