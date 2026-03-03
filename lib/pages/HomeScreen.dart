import 'package:flutter/material.dart';
import 'package:saamay/pages/DailyHoroscope.dart';
import 'package:saamay/pages/Kundlimatching.dart';
import 'package:saamay/pages/astrologers.dart';
import 'package:saamay/pages/bannerCarasoul.dart';
import 'package:saamay/pages/blogs.dart';
import 'package:saamay/pages/bookPuja.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar.dart';
import 'package:saamay/pages/referralDialog.dart';
import 'package:saamay/pages/saamayMall.dart';
import 'package:saamay/pages/walletTransactions.dart';
import 'package:saamay/pages/recharge.dart';
import 'package:saamay/pages/homepage.dart';
import 'package:saamay/pages/yourKundali.dart';
import 'package:saamay/pages/login.dart';
import 'package:saamay/pages/config.dart';
import 'package:saamay/pages/spinner_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class PopupData {
  final int popupId;
  final String imageUrl;
  final String title;
  final String highlight;
  final String? buttonText;
  final String? buttonLink;
  final String caption;
  final String page;
  final bool isActive;

  PopupData({
    required this.popupId,
    required this.imageUrl,
    required this.title,
    required this.highlight,
    this.buttonText,
    this.buttonLink,
    required this.caption,
    required this.page,
    required this.isActive,
  });

  factory PopupData.fromJson(Map<String, dynamic> json) {
    return PopupData(
      popupId: json['popup_id'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      title: json['title'] ?? '',
      highlight: json['highlight'] ?? '',
      buttonText: json['button_text'],
      buttonLink: json['button_link'],
      caption: json['caption'] ?? '',
      page: json['page'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SpinnerData> _spinnerData = [];
  bool _isSpinnerActive = false;
  bool _hasShownSpinnerOnLoad = false;
  bool _isLoadingSpinner = true;
  bool _canShowSpinner = false;
  PopupData? _popupData;
  bool _hasShownPopup = false;
  bool _shouldNavigate = false;
  Widget? _nextScreen;

  @override
  void initState() {
    super.initState();
    _checkSpinnerStatus();
    // Show popup immediately
    _fetchAndShowPopup();
  }

  void _setNextScreen(Widget screen) {
    if (mounted) {
      setState(() {
        _nextScreen = screen;
        _shouldNavigate = true;
      });
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

  Future<void> _fetchAndShowPopup() async {
    try {
      // Get prefs
      final prefs = await SharedPreferences.getInstance();
      final isFirstTimeUser = prefs.getBool('user_first_time') ?? true;

      // Determine which API endpoint to use based on token and first-time flag
      late final String apiEndpoint;
      if (token.isEmpty) {
        apiEndpoint = '/popups/astrology';
      } else {
        if (isFirstTimeUser) {
          apiEndpoint = '/popups/dashboard_user';
        } else {
          apiEndpoint = '/popups/repeat_user';
        }
      }

      final response = await http.get(
        Uri.parse('$api$apiEndpoint'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Decode with UTF-8 to handle special characters properly
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        _popupData = PopupData.fromJson(jsonData);

        if (_popupData != null && _popupData!.isActive && !_hasShownPopup) {
          _hasShownPopup = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showPopup();
          });
        }
      }
    } catch (e) {
      print('Error fetching popup data: $e');
    }
  }

  void _showPopup() {
    if (_popupData == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // cannot tap outside to close
      builder: (BuildContext dialogContext) {
        int remainingSeconds = 2;
        bool canClose = false;

        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setState) {
            // Start timer once when dialog builds and remainingSeconds == 2
            if (remainingSeconds == 2 && !canClose) {
              Future.delayed(const Duration(seconds: 1), () {
                if (!dialogContext.mounted) return;
                setState(() {
                  remainingSeconds -= 1;
                });

                Future.delayed(const Duration(seconds: 1), () {
                  if (!dialogContext.mounted) return;
                  setState(() {
                    remainingSeconds = 0;
                    canClose = true;
                  });
                });
              });
            }

            return WillPopScope(
              onWillPop: () async => canClose, // block back button until canClose
              child: Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E6D3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top-right: timer first, then close button
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          margin: const EdgeInsets.all(10),
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            //shape: BoxShape.circle,
                          ),
                          child: canClose
                              ? GestureDetector(
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              _checkAndShowSpinnerAfterPopup();
                            },
                            child: const Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 20,
                            ),
                          )
                              : Text(
                            'wait for ${remainingSeconds}s',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Main content
                      Flexible(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Image
                                GestureDetector(
                                  onTap: canClose
                                      ? () {
                                    Navigator.of(dialogContext).pop();
                                    _handlePopupNavigation();
                                  }
                                      : null,
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: AspectRatio(
                                        aspectRatio: 400 / 250,
                                        child: Image.network(
                                          _popupData!.imageUrl,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              width: double.infinity,
                                              color: Colors.grey.shade300,
                                              child: const Center(
                                                child: Icon(Icons.image, size: 50),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Title
                                Text(
                                  _popupData!.title,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.lora(
                                    fontSize: 16,
                                    color: const Color(0xFF666666),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Highlight
                                Text(
                                  _popupData!.highlight,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pink,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Button – disabled until canClose
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:() {
                                      Navigator.of(dialogContext).pop();
                                      _handlePopupNavigation();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFB347),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      _popupData!.buttonText ?? 'Join Us',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Caption
                                Text(
                                  _popupData!.caption,
                                  style: GoogleFonts.poppins(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
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
              ),
            );
          },
        );
      },
    ).then((_) {
      _checkAndShowSpinnerAfterPopup();
    });
  }

  Future<void> _handlePopupNavigation() async {

    final prefs = await SharedPreferences.getInstance();
    final isFirstTimeUser = prefs.getBool('user_first_time') ?? true;
    print("isFirstTimeUser: ${isFirstTimeUser}");

    if (token.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Homepage()),
      );
    } else {
      if (isFirstTimeUser) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AstrologersPage(title: 'All')),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RechargePage()),
        );
      }
    }
/*
    if (token.isEmpty) {
      // Navigate to login page for logged out users
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } else {
      // Navigate to astrologers page for logged in users
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AstrologersPage(title: 'All')),
      );
    }*/
  }

  void _checkAndShowSpinnerAfterPopup() {
    // Only show spinner if user is logged in and conditions are met
    if (token.isNotEmpty && _canShowSpinner && !_hasShownSpinnerOnLoad) {
      _hasShownSpinnerOnLoad = true;
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          _showSpinnerModal();
        }
      });
    }
  }

  // Method to check spinner status
  Future<void> _checkSpinnerStatus() async {
    if (token.isEmpty) {
      setState(() {
        _isLoadingSpinner = false;
        _canShowSpinner = false;
      });
      return;
    }

    try {
      final spinners = await SpinnerService.getSpinnerStatus();
      final isActive = spinners.any((spinner) => spinner.isActive);
      final shouldShow = await _shouldShowSpinnerModal();

      setState(() {
        _spinnerData = spinners;
        _isSpinnerActive = isActive;
        _canShowSpinner = isActive && shouldShow;
        _isLoadingSpinner = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSpinner = false;
        _canShowSpinner = false;
      });
    }
  }

  Future<bool> _shouldShowSpinnerModal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSpinnerUsed = prefs.getString('last_spinner_used');

      // If no previous spinner use recorded, allow showing modal
      if (lastSpinnerUsed == null) {
        return true;
      }

      // Parse the stored timestamp
      final lastUsedTime = DateTime.parse(lastSpinnerUsed);
      final currentTime = DateTime.now();

      // Check if 24 hours have passed
      final difference = currentTime.difference(lastUsedTime);
      return difference.inHours >= 24;
    } catch (e) {
      // If there's an error, default to showing the modal
      return true;
    }
  }

  // Method to handle pull-to-refresh
  Future<void> _onRefresh() async {
    try {
      // Reset flags
      _hasShownSpinnerOnLoad = false;
      // _hasShownPopup = false;

      // Refresh spinner status and popup
      await Future.wait([_checkSpinnerStatus(), _fetchAndShowPopup()]);

      // Add a small delay to make the refresh feel more natural
      await Future.delayed(Duration(milliseconds: 500));
    } catch (e) {
      // Show error message if refresh fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh content'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Method to show spinner modal
  void _showSpinnerModal() async {
    if (_spinnerData.isEmpty || !_isSpinnerActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No active spinner available right now!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Check 24-hour rule before showing modal
    final shouldShow = await _shouldShowSpinnerModal();
    if (!shouldShow) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Spinner can only be used once every 24 hours!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final activeSpinner = _spinnerData.firstWhere(
      (spinner) => spinner.isActive,
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SpinnerModal(
          spinnerData: activeSpinner,
          onSpinComplete: () async {
            // Update the spinner status after spinning
            await _checkSpinnerStatus();
          },
        );
      },
    );
  }

  // Method to check token and navigate accordingly
  void _handleYourKundliTap() {
    if (token.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Homepage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => YourKundali()),
      );
    }
  }

  // Method to handle navigation for trending services
  void _handleTrendingServiceTap(String serviceTitle) {
    switch (serviceTitle) {
      case "SAAMAY MALL":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SaamayMallPage()),
        );
        break;
      case "BOOK PUJA":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookPuja()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Service not available'),
            duration: Duration(seconds: 2),
          ),
        );
    }
  }

  // Method to handle navigation for free services
  void _handleFreeServiceTap(String serviceTitle) {
    switch (serviceTitle) {
      case "YOUR\nKUNDLI":
        _handleYourKundliTap();
        break;
      case "DAILY\nHOROSCOPE":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DailyHoroscope()),
        );
        break;
      case "SAAMAY\nBLOGS":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SaamayBlogsPage()),
        );
        break;
    }
  }

  // Method to build service item for astrology consultation
  Widget _buildServiceItem(Map<String, dynamic> service) {
    return Padding(
      padding: EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AstrologersPage(title: service["name"]),
            ),
          );
        },
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.iconBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(service['image']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              service["name"],
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to build trending service card
  Widget _buildTrendingServiceCard(Map<String, dynamic> service) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleTrendingServiceTap(service["title"]),
        child: Container(
          margin: EdgeInsets.only(right: 8),
          padding: EdgeInsets.all(12),
          height: 135,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    service["title"],
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    service["subtitle"],
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightText,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFBCBB5),
                          Color(0xFFF7EBD6),
                          Color(0xFFFBCBB5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Text(
                        service['action'],
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF460000),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Image.asset(
                  service['image'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to build free service card
  Widget _buildFreeServiceCard(Map<String, dynamic> service) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleFreeServiceTap(service["title"]),
        child: Stack(
          children: [
            Container(
              height: 120,
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      service["title"],
                      style: GoogleFonts.lora(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: 50,
                      height: 50,
                      margin: EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(service["image"]),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 7,
              child: Container(
                height: 30,
                width: 30,
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/free.png"),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to build section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Center(
        child: Text(
          title,
          style: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF460000),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldNavigate && _nextScreen != null) {
      return _nextScreen!;
    }
    final List<Map<String, dynamic>> services = [
      {"name": "All", "image": "assets/images/all.png"},
      {"name": "Vedic", "image": "assets/images/vedic.png"},
      {"name": "Vastu", "image": "assets/images/vastu.png"},
      {"name": "Tarot", "image": "assets/images/tarot.png"},
      {"name": "Numerology", "image": "assets/images/numerology.png"},
      {"name": "Reiki", "image": "assets/images/reikiimage.png"},
    ];

    final List<Map<String, dynamic>> trendingServices = [
      {
        "title": "SAAMAY MALL",
        "subtitle": "ALL ASTRO ITEMS HERE",
        "action": "BUY GEMSTONES & MORE!",
        "image": "assets/images/mall.png",
        "color": Colors.purple,
      },
      {
        "title": "BOOK PUJA",
        "subtitle": "FIND YOUR REMEDIES",
        "action": "FIND REMEDIES",
        "image": "assets/images/puja.png",
        "color": Colors.orange,
      },
    ];

    final List<Map<String, dynamic>> freeServices = [
      {"title": "YOUR\nKUNDLI", "image": "assets/images/kundali.png"},
      {"title": "DAILY\nHOROSCOPE", "image": "assets/images/hororscope.png"},
      {"title": "SAAMAY\nBLOGS", "image": "assets/images/blog.png"},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        onLoginRequired: () {
          // Navigate to login using state-based navigation
          _setNextScreen(const Homepage());
        },
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _onRefresh,
            color: Color(0xFF460000),
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Carousel
                  BannerCarousel(),
                  SizedBox(height: 8),

                  // Astrology Consultation Section
                  _buildSectionHeader("ASTROLOGY CONSULTATION"),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: services
                            .map((service) => _buildServiceItem(service))
                            .toList(),
                      ),
                    ),
                  ),

                  // Trending Services Section
                  _buildSectionHeader("TRENDING SERVICES"),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 8, 0),
                    child: Row(
                      children: trendingServices
                          .map((service) => _buildTrendingServiceCard(service))
                          .toList(),
                    ),
                  ),

                  // Free Services Section
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        ...freeServices
                            .take(2)
                            .map((service) => _buildFreeServiceCard(service))
                            .toList(),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                _handleFreeServiceTap(freeServices[2]["title"]),
                            child: Stack(
                              children: [
                                Container(
                                  height: 120,
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      Align(
                                        alignment: Alignment.topLeft,
                                        child: Text(
                                          freeServices[2]["title"],
                                          style: GoogleFonts.lora(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.text,
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Container(
                                          width: 50,
                                          height: 50,
                                          margin: EdgeInsets.only(top: 10),
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: AssetImage(
                                                freeServices[2]["image"],
                                              ),
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: -1,
                                  child: Container(
                                    height: 30,
                                    width: 30,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage(
                                          "assets/images/free.png",
                                        ),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // New row of three boxes (without free sticker)

                  // Kundli Matching Section
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KundliMatching(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "KUNDLI MATCHING",
                                        style: GoogleFonts.lora(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.text,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFDA4453),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          "NEW",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "FIND YOUR PREMIUM MATCH NOW",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.lightText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12),
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                    "assets/images/kundaliMatching.png",
                                  ),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _handleReferAFriend(context),
                            child: Container(
                              height: 120,
                              margin: EdgeInsets.only(right: 8),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      "REFER A FRIEND",
                                      style: GoogleFonts.lora(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF740000),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      margin: EdgeInsets.only(top: 10),
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage(
                                            "assets/images/referal.png",
                                          ),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const WalletPage(initialTabIndex: 2),
                                ),
                              );
                            },
                            child: Container(
                              height: 120,
                              margin: EdgeInsets.only(right: 8),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      "WRITE\nFEEDBACK",
                                      style: GoogleFonts.lora(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.text,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      margin: EdgeInsets.only(top: 10),
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage(
                                            "assets/images/feedback.png",
                                          ),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              const url =
                                  'https://play.google.com/store/apps/details?id=com.saamay.user';
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(
                                  Uri.parse(url),
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                            child: Container(
                              height: 120,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      "RATE\nSAAMAYRASHI",
                                      style: GoogleFonts.lora(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.text,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      margin: EdgeInsets.only(top: 0),
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage(
                                            "assets/images/rate.png",
                                          ),
                                          fit: BoxFit.contain,
                                        ),
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
                  ),

                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 16,
                  ), // Bottom padding
                ],
              ),
            ),
          ),

          // Spinner Extension Button - Only show if user is logged in
          if (token.isNotEmpty && !_isLoadingSpinner)
            SpinnerExtensionButton(
              isActive: _canShowSpinner,
              onTap: _showSpinnerModal,
            ),
          if (token.isNotEmpty)
            FeedbackExtensionButton(
              onTap: () {
                // Navigate to a feedback page or show a dialog
                // For example:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WalletPage(initialTabIndex: 2),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// Feedback extension button widget
class FeedbackExtensionButton extends StatelessWidget {
  final VoidCallback onTap;

  const FeedbackExtensionButton({Key? key, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: MediaQuery.of(context).size.height * 0.24, // Adjusted top position
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 55,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF460000), Color(0xFF8B0000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              bottomLeft: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(left: 2),
              child: Icon(
                Icons.edit, // Pen icon
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
