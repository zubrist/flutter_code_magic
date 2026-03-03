import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/Notification.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar2.dart';
import 'package:saamay/pages/config.dart';
import 'package:saamay/pages/disclaimer.dart';
import 'package:saamay/pages/editProfile.dart';
import 'package:saamay/pages/login.dart';
import 'package:saamay/pages/pricing.dart';
import 'package:saamay/pages/referralDialog.dart';
import 'package:saamay/pages/refund_policy.dart';
import 'package:saamay/pages/walletTransactions.dart';
import 'package:saamay/pages/terms_and_condition.dart';
import 'package:saamay/pages/privacy_policy.dart';
import 'package:saamay/pages/about_saamay.dart';
import 'package:saamay/pages/chatContactsPage.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:saamay/pages/homepage.dart';
import 'package:saamay/pages/changePassword.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io'; // Import your homepage
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Update your ProfileScreen class to use state-based navigation:

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Add state variables for navigation
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

  Future<Map<String, dynamic>> _fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse('$api/user/own'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData.isNotEmpty) {
          return {'user_data': responseData['data']};
        }
      }
      return {'user_data': {}};
    } catch (e) {
      return {'user_data': {}};
    }
  }

  // Method to handle Refer a Friend with token check
  void _handleReferAFriend(BuildContext context) {
    if (token == null || token.isEmpty) {
      // Token is null or empty, redirect to login using state navigation
      _setNextScreen(const LoginPage());
    } else {
      // Token exists, show referral dialog
      ReferralDialog.showReferralDialog(context);
    }
  }

  Future<void> _logout(BuildContext context) async {
    // Show confirmation dialog
    final bool confirm = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Logout',
                    style: TextStyle(color: Color(0xFFDA4453)),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirm) return;

    try {
      // Clear shared preferences first
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');
      await prefs.remove('password');
      await prefs.remove('auth_token');
      await prefs.remove('refresh_token');
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('fcm_token');
      await prefs.remove('access_token');
      await prefs.remove('user_data');
      await prefs.remove('last_spinner_used');

      await FirebaseMessaging.instance.subscribeToTopic('loggedout');
      await FirebaseMessaging.instance.unsubscribeFromTopic('loggedin');
      // Reset global variables
      token = '';
      email = '';
      pass = '';
      responseList = {};
      notificationcount = '';

      // Use state-based navigation to LoginPageWrapper (which prevents back navigation)
      _setNextScreen(const LoginPageWrapper());

      print("User logged out successfully");
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
      print('Logout error: $e');
    }
  }

  // Your existing methods remain the same...
  PreferredSizeWidget _buildGradientAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xFFDA4453), Color(0xFF89216B)],
          ),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.08),
              offset: Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: AppBar(
          centerTitle: true,
          title: const Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required String title,
    required String imagePath,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 2,
        color: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Image.asset(
                imagePath,
                width: 24,
                height: 24,
                color: const Color(0xFFDA4453),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check for navigation first
    if (_shouldNavigate && _nextScreen != null) {
      return _nextScreen!;
    }

    // Your existing build method...
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar2(title: "Profile"),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final Map<String, dynamic> responseData =
              snapshot.data ?? {'user_data': {}};

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 2,
                    color: const Color(0xFFFFFFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage: NetworkImage(
                                  responseData['user_data']
                                          ['user_profile_picture'] ??
                                      'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                                ),
                                backgroundColor: Colors.grey[300],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      responseData['user_data']
                                              ['user_fullname'] ??
                                          'No Name',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '+${responseData['user_data']['user_mob']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      responseData['user_data']['user_email'] ??
                                          'No Email',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          TextButton(
                            onPressed: () {
                              token == ''
                                  ? _setNextScreen(
                                      const LoginPage(),
                                    ) // Use state navigation
                                  : Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditProfile(),
                                      ),
                                    );
                            },
                            child: Row(
                              children: [
                                Text(
                                  'Edit Profile',
                                  style: TextStyle(color: Color(0xFFDA4453)),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFFDA4453),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildProfileCard(
                  title: 'My Wallet',
                  imagePath: 'assets/icons/wallet.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => WalletPage()),
                    );
                  },
                ),
                _buildProfileCard(
                  title: 'Saamay Pack',
                  imagePath: 'assets/icons/pack.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => WalletPage(initialTabIndex: 1)),
                    );
                  },
                ),
                _buildProfileCard(
                  title: 'Order details and feedback',
                  imagePath: 'assets/icons/orderHistory.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const WalletPage(initialTabIndex: 2),
                      ),
                    );
                  },
                ),
                _buildProfileCard(
                  title: 'Chat history',
                  imagePath: 'assets/icons/history.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatContactsPage(),
                      ),
                    );
                  },
                ),
                _buildProfileCard(
                  title: 'Change Password',
                  imagePath: 'assets/icons/password.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChangePassword()),
                    );
                  },
                ),
                _buildProfileCard(
                  title: 'Refer a Friend',
                  imagePath: 'assets/icons/rewards.png',
                  onTap: () => _handleReferAFriend(context),
                ),
                _buildProfileCard(
                  title: 'About Saamay',
                  imagePath: 'assets/icons/aboutUs.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutSaamayPage(),
                      ),
                    );
                  },
                ),
                _buildProfileCard(
                  title: 'Terms and Condition',
                  imagePath: 'assets/icons/terms.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsAndConditionPage(),
                      ),
                    );
                  },
                ),
                _buildProfileCard(
                  title: 'Privacy Policy',
                  imagePath: 'assets/icons/privacy.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PricingPage(),
                      ),
                    );
                  },
                ),
                _buildProfileCard(
                  title: 'Pricing Policy',
                  imagePath: 'assets/icons/rate.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyPage(),
                      ),
                    );
                  },
                ),
                _buildProfileCard(
                  title: 'Refund & Cancellation Policy',
                  imagePath: 'assets/icons/refund.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RefundPolicyPage(),
                      ),
                    );
                  },
                ),
                _buildProfileCard(
                  title: 'Disclaimer',
                  imagePath: 'assets/icons/disclaimer.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DisclaimerPage(),
                      ),
                    );
                  },
                ),
                _buildProfileCard(
                  title: 'Logout',
                  imagePath: 'assets/icons/logout.png',
                  onTap: () => _logout(context),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class LoginPageWrapper extends StatelessWidget {
  const LoginPageWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Simply exit the app when back button is pressed
        exit(0);
      },
      child: LoginPage(),
    );
  }
}
