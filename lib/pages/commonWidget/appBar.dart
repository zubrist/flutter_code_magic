import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/Notification.dart';
import 'package:saamay/pages/config.dart';
import 'package:saamay/pages/profile.dart';
import 'package:saamay/pages/recharge.dart';
import 'package:saamay/pages/login.dart';
import 'package:google_fonts/google_fonts.dart';

import '../HomeScreen.dart';

class UserProfileData {
  final String? profilePicture;
  final String? fullName;
  final double? walletBalance;

  UserProfileData({this.profilePicture, this.fullName, this.walletBalance});

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      profilePicture: json['user_profile_picture'],
      fullName: json['user_fullname'],
      walletBalance:
          json['user_wallet'] != null ? json['user_wallet'].toDouble() : null,
    );
  }

  String? get firstName {
    if (fullName == null || fullName!.isEmpty) return null;
    return fullName!.split(' ').first;
  }
}

class WalletBalanceData {
  final String status;
  final int userId;
  final double walletBalance;

  WalletBalanceData({
    required this.status,
    required this.userId,
    required this.walletBalance,
  });

  factory WalletBalanceData.fromJson(Map<String, dynamic> json) {
    return WalletBalanceData(
      status: json['status'] ?? '',
      userId: json['user_id'] ?? 0,
      walletBalance: json['wallet_balance']?.toDouble() ?? 0.0,
    );
  }
}

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Function()? onWalletPressed;
  final Function()? onNotificationPressed;
  final Function()? onProfilePressed;
  final Function()? onLoginRequired;

  const CustomAppBar({
    Key? key,
    this.onWalletPressed,
    this.onNotificationPressed,
    this.onProfilePressed,
    this.onLoginRequired,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 45);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  UserProfileData? userData;
  WalletBalanceData? walletData;
  bool isLoading = false; // Changed to false by default
  bool isWalletLoading = false; // Changed to false by default
  bool hasError = false;
  Timer? _notificationTimer;
  Timer? _walletRefreshTimer;
  int currentNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    // Only fetch data if token is valid
    if (_isTokenValid()) {
      isLoading = true;
      isWalletLoading = true;
      fetchUserData();
      fetchWalletBalance();
      fetchNotificationCount();
      _startNotificationRefresh();
      _startWalletRefresh();
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _walletRefreshTimer?.cancel();
    super.dispose();
  }

  // Helper method to check if token is valid
  bool _isTokenValid() {
    return token != null && token.isNotEmpty;
  }

  void _startNotificationRefresh() {
    _notificationTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (mounted && _isTokenValid()) {
        fetchNotificationCount();
      }
    });
  }

  void _startWalletRefresh() {
    _walletRefreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted && _isTokenValid()) {
        fetchWalletBalance();
      }
    });
  }

  Future<void> fetchUserData() async {
    // Check token before making API call
    if (!_isTokenValid()) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$api/user/own'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.isNotEmpty && mounted) {
          setState(() {
            userData = UserProfileData.fromJson(data['data']);
            isLoading = false;
            hasError = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
            hasError = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }

  Future<void> fetchWalletBalance() async {
    // Check token before making API call
    if (!_isTokenValid()) {
      if (mounted) {
        setState(() {
          isWalletLoading = false;
        });
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$api/user_wallet_balance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (mounted && data['status'] == 'Success') {
          setState(() {
            walletData = WalletBalanceData.fromJson(data);
            isWalletLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isWalletLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isWalletLoading = false;
        });
      }
    }
  }

  Future<void> fetchNotificationCount() async {
    // Check token before making API call
    if (!_isTokenValid()) {
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$api/send_notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted && data['data'] != null) {
          setState(() {
            currentNotificationCount = (data['data'] as List).length;
            notificationcount = currentNotificationCount.toString();
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> refreshUserData() async {
    // Check token before refreshing
    if (!_isTokenValid()) {
      return;
    }

    if (!isLoading) {
      setState(() {
        isLoading = true;
        isWalletLoading = true;
      });
      await Future.wait([fetchUserData(), fetchWalletBalance()]);
    }
  }

  Future<void> refreshNotificationCount() async {
    if (_isTokenValid()) {
      await fetchNotificationCount();
    }
  }

  Future<void> refreshWalletBalance() async {
    if (_isTokenValid()) {
      await fetchWalletBalance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/BG.png'),
          fit: BoxFit.cover,
        ),
        gradient: LinearGradient(
          colors: [Color(0xFF89216B), Color(0xFFDA4453)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Container(
                  width: 100,
                  height: 40,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/saamayTitle.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              _buildWalletWithBalance(),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: Image.asset(
                      'assets/icons/notification_home.png',
                      color: Colors.white,
                      width: 24,
                      height: 24,
                    ),
                    onPressed: widget.onNotificationPressed ??
                        () {
                          // Check token before navigation
                          if (!_isTokenValid()) {
                            _showLoginRequiredDialog();
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotificationPage(),
                            ),
                          ).then((_) {
                            if (_isTokenValid()) {
                              fetchNotificationCount();
                            }
                          });
                        },
                  ),
                  if (currentNotificationCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            currentNotificationCount.toString(),
                            style: GoogleFonts.lora(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              _buildProfileIcon(),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8, right: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                          (Route<dynamic> route) => false,
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.home,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildWelcomeMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    // Don't show loading if token is invalid
    if (!_isTokenValid()) {
      return Text(
        'Welcome Guest',
        style: GoogleFonts.lora(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              offset: Offset(0, 1),
              blurRadius: 2,
              color: Colors.black.withOpacity(0.3),
            ),
          ],
        ),
      );
    }

    if (isLoading) {
      return Container(
        width: 120,
        height: 16,
        child: LinearProgressIndicator(
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          minHeight: 2,
        ),
      );
    }

    String welcomeText =
        userData?.firstName != null && userData!.firstName!.isNotEmpty
            ? 'Welcome ${userData!.firstName!}'
            : 'Welcome Guest';

    return Text(
      welcomeText,
      style: GoogleFonts.lora(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w900,
        shadows: [
          Shadow(
            offset: Offset(0, 1),
            blurRadius: 2,
            color: Colors.black.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletWithBalance() {
    return InkWell(
      onTap: widget.onWalletPressed ??
          () {
            // Check token before navigation
            if (!_isTokenValid()) {
              _showLoginRequiredDialog();
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RechargePage()),
            ).then((_) {
              if (_isTokenValid()) {
                fetchWalletBalance();
              }
            });
          },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/wallet_home.png',
              color: const Color.fromRGBO(255, 255, 255, 1),
              width: 20,
              height: 20,
            ),
            SizedBox(height: 2),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isWalletLoading && _isTokenValid()
                  ? SizedBox(
                      width: 30,
                      height: 10,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white70,
                        ),
                        minHeight: 1,
                      ),
                    )
                  : Text(
                      walletData?.walletBalance != null
                          ? '₹${walletData!.walletBalance.toStringAsFixed(0)}'
                          : '₹0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: isLoading && _isTokenValid()
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : _getProfileImage(),
          onPressed: widget.onProfilePressed ??
              () {
                if (!_isTokenValid()) {
                  if (widget.onLoginRequired != null) {
                    widget.onLoginRequired!();
                  } else {
                    _showLoginRequiredDialog();
                  }
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  ).then((_) {
                    if (_isTokenValid()) {
                      fetchUserData();
                    }
                  });
                }
              },
        ),
        if (!isLoading || !_isTokenValid())
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 6, height: 0.8, color: Colors.black87),
                    SizedBox(height: 0.8),
                    Container(width: 6, height: 0.8, color: Colors.black87),
                    SizedBox(height: 0.8),
                    Container(width: 6, height: 0.8, color: Colors.black87),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Login Required'),
          content: Text('Please login to access this feature.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToLogin();
              },
              child: Text('Login'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToLogin() {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  Widget _getProfileImage() {
    if (_isTokenValid() &&
        userData?.profilePicture != null &&
        userData!.profilePicture!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          userData!.profilePicture!,
          width: 24,
          height: 24,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/icons/profile_home.png',
              color: Colors.white,
              width: 24,
              height: 24,
            );
          },
        ),
      );
    } else {
      return Image.asset(
        'assets/icons/profile_home.png',
        color: Colors.white,
        width: 24,
        height: 24,
      );
    }
  }
}
