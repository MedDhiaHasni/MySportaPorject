import 'package:flutter/material.dart';
import 'package:myapp/screens/LoginPage.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final PageController controlleronboard = PageController();

  @override
  void dispose() {
    controlleronboard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: controlleronboard,
            children: [
              // Page loula
              Container(
                color: const Color(0xFFF5F5F5),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        SizedBox(height: 60),

                        // Titre
                        Text(
                          'Book Matches\nInstantly',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF005D5E),
                            fontSize: 32,
                            height: 1.2,
                          ),
                        ),

                        SizedBox(height: 40),

                        // taswira mta3 l'onboarding loula
                        Container(
                          width: 320,
                          height: 280,
                          decoration: BoxDecoration(
                            color: Color(0xFFF5F0E8),
                            borderRadius: BorderRadius.circular(160),
                          ),
                          child: Image(
                            image: AssetImage("assets/onboarding-1.png"),
                            fit: BoxFit.contain,
                          ),
                        ),

                        SizedBox(height: 50),

                        // Description
                        Text(
                          'Reserve slots and organize\ngames in seconds',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF232624),
                            fontSize: 18,
                            height: 1.4,
                          ),
                        ),

                        Spacer(),
                        SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),

              // page thenia
              Container(
                color: const Color(0xFFF5F5F5),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 60),

                        // Titre
                        Text(
                          'Connect With\nOther Players',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF005D5E),
                            fontSize: 32,
                            height: 1.2,
                          ),
                        ),

                        SizedBox(height: 40),

                        // hak el dwewr
                        SizedBox(
                          width: double.infinity,
                          height: 280,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              // circle li 3al limin
                              Positioned(
                                right: -70,
                                top: 200,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFE8B4A0),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              // taswira mta3 el background
                              Positioned(
                                top: -10,
                                child: Container(
                                  width: 260,
                                  height: 260,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF5F0E8),
                                    borderRadius: BorderRadius.circular(140),
                                  ),
                                ),
                              ),
                              Image(
                                image: AssetImage("assets/onboarding-2.png"),
                                fit: BoxFit.contain,
                              ),

                              // circle l5adhra
                              Positioned(
                                left: -100,
                                top: 90,
                                child: Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF005D5E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 50),

                        // Description
                        Text(
                          'Find teammates, join matches,\nand build your sports network',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF232624),
                            fontSize: 18,
                            height: 1.4,
                          ),
                        ),

                        Spacer(),
                        SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),

              // el page theltha mazelt ma5demthech
              Container(
                color: Color.fromARGB(255, 209, 196, 192),
                child: Center(
                  child: Text(
                    "onboarding 3 tw narj3elha 7atta hiya ",
                    style: TextStyle(fontSize: 30),
                  ),
                ),
              ),
            ],
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => LoginPage()),
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
            ),
          ),

          Container(
            alignment: Alignment(0, 0.89),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 3),
                SmoothPageIndicator(
                  controller: controlleronboard,
                  count: 3,
                  effect: WormEffect(
                    activeDotColor: Color(0xFF005D5E),
                    dotHeight: 13,
                    dotWidth: 13,
                  ),
                ),
                const SizedBox(width: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
