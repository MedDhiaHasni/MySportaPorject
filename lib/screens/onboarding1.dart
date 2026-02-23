import 'package:flutter/material.dart';
import 'package:myapp/screens/onboarding2.dart';

class Onboarding1 extends StatefulWidget {
  const Onboarding1({super.key});

  @override
  State<Onboarding1> createState() => _Onboarding1State();
}

class _Onboarding1State extends State<Onboarding1> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          _buildPage1(),

          Onboarding2Content(currentPage: _currentPage),
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {},
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
                'Book Matches\nInstantly',
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
                width: 320,
                height: 280,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0E8),
                  borderRadius: BorderRadius.circular(160),
                ),
                child: const Image(
                  image: AssetImage("assets/onboarding-1.png"),
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 50),

              const Text(
                'Reserve slots and organize\ngames in seconds',
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
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = _currentPage == index;
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
