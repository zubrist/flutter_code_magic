import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/Homepage.dart';
import 'package:saamay/pages/config.dart';
import 'package:saamay/pages/HomeScreen.dart';
import 'package:url_launcher/url_launcher.dart';

const String yourLocalAppVersion = '1.0.10';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _shouldNavigate = false;
  Widget? _nextScreen;

  @override
  void initState() {
    super.initState();
    _checkAppVersionAndProceed();
  }

  Future<void> _checkAppVersionAndProceed() async {
    try {
      final url = Uri.parse("$api/app_version");
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        if (responseData['status'] == 'Success') {
          var dataList = responseData['data'];
          var saamayRashi = dataList.firstWhere(
            (item) => item['app_name'] == 'SaamayRashi_V',
            orElse: () => null,
          );
          if (saamayRashi != null) {
            String latestVersion = saamayRashi['app_version'];
            if (_isVersionLower(yourLocalAppVersion, latestVersion)) {
              _showUpdateDialog(latestVersion);
              return; // Prevent further navigation
            }
          }
        }
      }
    } catch (e) {
      // Handle error, can show a snackbar or log it
    }
    await _determineNextScreen();
  }

  bool _isVersionLower(String localVersion, String remoteVersion) {
    // Simple comparison: splits by '.', compares each part as integer
    List<int> local = localVersion.split('.').map(int.parse).toList();
    List<int> remote = remoteVersion.split('.').map(int.parse).toList();
    for (int i = 0; i < local.length && i < remote.length; i++) {
      if (local[i] < remote[i]) return true;
      if (local[i] > remote[i]) return false;
    }
    // If versions are like 1.0.6 vs 1.0.6.1 etc.
    return local.length < remote.length;
  }

  void _showUpdateDialog(String version) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.all(24),
            title: Column(
              children: [
                Text(
                  'Update Required',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'A newer version ($version) of SaamayRashi is available.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please update the app from the Play Store to continue.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF89216B), Color(0xFFDA4453)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF89216B).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      const playStoreUrl =
                          'https://play.google.com/store/apps/details?id=com.saamay.user';
                      if (await canLaunch(playStoreUrl)) {
                        await launch(playStoreUrl);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Go to Play Store',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _determineNextScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final String? authToken = prefs.getString('auth_token');
    final String? refreshToken = prefs.getString('refresh_token');

    if (!mounted) return;

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _attemptAutoLogin(refreshToken);
    } else if (isLoggedIn && authToken != null && authToken.isNotEmpty) {
      token = authToken;
      _setNextScreen(const HomeScreen());
    } else {
      _setNextScreen(const Homepage());
    }
  }

  Future<void> _attemptAutoLogin(String refreshToken) async {
    try {
      final url = Uri.parse("$api/refresh_token");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh_token": refreshToken}),
      );
      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          String newAccessToken = responseData['access_token'];
          String newRefreshToken = responseData['user_data']['refresh_token'];
          bool userFirstTime = responseData['user_data']['user_first_time'];
          token = newAccessToken;
          responseList = responseData;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', newAccessToken);
          await prefs.setString('refresh_token', newRefreshToken);
          await prefs.setBool('is_logged_in', true);
          await prefs.setBool('user_first_time', userFirstTime);

          if (mounted) {
            _setNextScreen(const HomeScreen());
          }
        } else {
          await _clearLoginData();
          _setNextScreen(const Homepage());
        }
      } else {
        await _clearLoginData();
        _setNextScreen(const Homepage());
      }
    } catch (e) {
      await _clearLoginData();
      _setNextScreen(const Homepage());
    }
  }

  Future<void> _clearLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.setBool('is_logged_in', false);
    token = '';
    responseList = {};
  }

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
    if (_shouldNavigate && _nextScreen != null) {
      return _nextScreen!;
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/saamaywelcome.png', height: 200),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF89216B)),
              strokeWidth: 3.0,
            ),
            const SizedBox(height: 20),
            Text(
              'Loading...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please wait while we prepare your experience',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
