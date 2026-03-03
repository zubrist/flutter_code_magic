import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:saamay/pages/HomeScreen.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/login.dart';
import 'package:google_fonts/google_fonts.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  bool _shouldNavigate = false;
  Widget? _nextScreen;

  // Set the next screen to navigate to
  void _setNextScreen(Widget screen) {
    if (mounted) {
      setState(() {
        _nextScreen = screen;
        _shouldNavigate = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we should navigate and have determined the next screen, show it
    if (_shouldNavigate && _nextScreen != null) {
      return _nextScreen!;
    }

    // Otherwise, show the homepage
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(color: AppColors.iconBackground),
          ),
          Positioned.fill(
            child: Image.asset(
              'assets/images/getstartedBG.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(height: 100),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 277,
                    width: 270,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/images/getstartedLogo.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: EdgeInsets.only(bottom: 30, left: 16, right: 16),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF89216B), Color(0xFFDA4453)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              _setNextScreen(const LoginPage());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              minimumSize: const Size(382, 52),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get Started',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF2E6E6),
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: Color(0xFFF2E6E6),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color.fromARGB(255, 137, 33, 107),
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigate to HomeScreen using state-based navigation
                              _setNextScreen(HomeScreen());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              minimumSize: const Size(382, 52),
                            ),
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF89216B), Color(0xFFDA4453)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Text(
                                'Continue as Guest',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors
                                      .white, // This will be ignored due to ShaderMask
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).padding.bottom),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
