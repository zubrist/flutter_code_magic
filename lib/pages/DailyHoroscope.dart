import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar2.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart'; // Add this dependency

import 'package:saamay/pages/config.dart';
import 'package:saamay/pages/astrologers.dart';

// Data model for popup
class PopupData {
  final int popupId;
  final String imageUrl;
  final String title;
  final String highlight;
  final String buttonText;
  final String buttonLink;
  final String caption;
  final String page;
  final bool isActive;

  PopupData({
    required this.popupId,
    required this.imageUrl,
    required this.title,
    required this.highlight,
    required this.buttonText,
    required this.buttonLink,
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
      buttonText: json['button_text'] ?? '',
      buttonLink: json['button_link'] ?? '',
      caption: json['caption'] ?? '',
      page: json['page'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }
}

// Data model for horoscope prediction
class HoroscopePrediction {
  final String personal;
  final String health;
  final String profession;
  final String emotions;
  final String travel;
  final List<String> luck;

  HoroscopePrediction({
    required this.personal,
    required this.health,
    required this.profession,
    required this.emotions,
    required this.travel,
    required this.luck,
  });

  factory HoroscopePrediction.fromJson(Map<String, dynamic> json) {
    try {
      return HoroscopePrediction(
        personal: json['personal'] ?? '',
        health: json['health'] ?? '',
        profession: json['profession'] ?? '',
        emotions: json['emotions'] ?? '',
        travel: json['travel'] ?? '',
        luck: List<String>.from(json['luck'] ?? []),
      );
    } catch (e) {
      rethrow;
    }
  }
}

class DailyHoroscope extends StatefulWidget {
  const DailyHoroscope({Key? key}) : super(key: key);

  @override
  State<DailyHoroscope> createState() => _DailyHoroscopeState();
}

class _DailyHoroscopeState extends State<DailyHoroscope>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> zodiacSigns = [
    {'sign': 'Aries', 'image': 'assets/images/zodiac/aries.webp'},
    {'sign': 'Taurus', 'image': 'assets/images/zodiac/taurus.webp'},
    {'sign': 'Gemini', 'image': 'assets/images/zodiac/gemini.webp'},
    {'sign': 'Cancer', 'image': 'assets/images/zodiac/cancer.webp'},
    {'sign': 'Leo', 'image': 'assets/images/zodiac/leon.webp'},
    {'sign': 'Virgo', 'image': 'assets/images/zodiac/virgo.webp'},
    {'sign': 'Libra', 'image': 'assets/images/zodiac/libra.webp'},
    {'sign': 'Scorpio', 'image': 'assets/images/zodiac/scorpio.webp'},
    {'sign': 'Sagittarius', 'image': 'assets/images/zodiac/sagittarius.webp'},
    {'sign': 'Capricorn', 'image': 'assets/images/zodiac/capricorn.webp'},
    {'sign': 'Aquarius', 'image': 'assets/images/zodiac/aquarius.webp'},
    {'sign': 'Pisces', 'image': 'assets/images/zodiac/pisces.webp'},
  ];

  late TabController _tabController;
  Map<String, HoroscopePrediction?> _predictions = {};
  Map<String, bool> _loadingStates = {};
  Map<String, String> _errorMessages = {};
  Timer? _popupTimer;
  PopupData? _popupData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: zodiacSigns.length, vsync: this);

    // Initialize loading states and error messages
    for (var sign in zodiacSigns) {
      _loadingStates[sign['sign']] = false;
      _errorMessages[sign['sign']] = '';
    }

    // Fetch horoscope for the initial tab
    _fetchHoroscope(zodiacSigns[0]['sign']);

    // Add listener to fetch data when tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final selectedSign = zodiacSigns[_tabController.index]['sign'];
        if (_predictions[selectedSign] == null &&
            !_loadingStates[selectedSign]!) {
          _fetchHoroscope(selectedSign);
        }
      }
    });

    // Start timer for popup after 4 seconds
    _startPopupTimer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _popupTimer?.cancel();
    super.dispose();
  }

  void _startPopupTimer() {
    _popupTimer = Timer(const Duration(seconds: 4), () {
      _fetchPopupData();
    });
  }

  Future<void> _fetchPopupData() async {
    try {
      final response = await http.get(
        Uri.parse('$api/popups/zodiac-sign'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Decode with UTF-8 to handle special characters properly
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        _popupData = PopupData.fromJson(jsonData);

        if (_popupData != null && _popupData!.isActive) {
          _showPopup();
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
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height *
                  0.7, // Increased from 0.6 to 0.7
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF5E6D3), // Beige background
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button at the top
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Main content - Wrap in Flexible to allow scrolling if needed
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Main image with proper aspect ratio
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              // Navigate to astrologer page
                              if (_popupData!.buttonLink == 'astrology') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AstrologersPage(title: 'All'),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AspectRatio(
                                  aspectRatio:
                                      400 / 250, // Width / Height = 1.6
                                  child: Image.network(
                                    _popupData!.imageUrl,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
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
                          // Title text - Using Poppins
                          Text(
                            _popupData!.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Color(0xFF666666),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Highlight text - Using Lora for emphasis
                          Text(
                            _popupData!.highlight,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lora(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.pink,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Chat/Call button
                          Container(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                // Navigate to astrologer page
                                if (_popupData!.buttonLink == 'astrology') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AstrologersPage(title: 'All'),
                                    ),
                                  );
                                }
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
                                _popupData!.buttonText,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Caption text - Using Poppins
                          Text(
                            _popupData!.caption,
                            style: GoogleFonts.poppins(
                              color: Colors.red,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w700,
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
      },
    );
  }

  Future<void> _fetchHoroscope(String sign) async {
    setState(() {
      _loadingStates[sign] = true;
      _errorMessages[sign] = '';
    });

    try {
      final requestBody = {
        'sign': sign,
        'day': DateTime.now().day,
        'month': DateTime.now().month,
        'year': DateTime.now().year,
        'tzone': 5.5,
        'lan': 'en',
      };

      final response = await http.put(
        Uri.parse('$api/indian-api/daily-horoscope/daily-horoscope'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        ;
        if (jsonData['success'] == 1) {
          setState(() {
            _predictions[sign] = HoroscopePrediction.fromJson(
              jsonData['data']['prediction'],
            );
          });
        } else {
          setState(() {
            _errorMessages[sign] =
                jsonData['message'] ?? 'Unknown error occurred';
          });
        }
      } else {
        setState(() {
          _errorMessages[sign] =
              'Error: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessages[sign] = 'Error: $e';
      });
    } finally {
      setState(() => _loadingStates[sign] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar2(title: "Daily Horoscope"),
      body: Column(
        children: [
          // TabBar in the body
          Container(
            height: 100,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 0),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.accent,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              padding: EdgeInsets.zero,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: zodiacSigns
                  .map(
                    (sign) => Tab(
                      height: 100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            sign['image'],
                            height: 70,
                            width: 70,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.error,
                                color: Colors.white,
                                size: 70,
                              );
                            },
                          ),
                          Text(
                            sign['sign'],
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: zodiacSigns.map((sign) {
                final signName = sign['sign'];
                final isLoading = _loadingStates[signName] ?? false;
                final errorMessage = _errorMessages[signName] ?? '';
                final prediction = _predictions[signName];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage.isNotEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    errorMessage,
                                    style: GoogleFonts.poppins(
                                        color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => _fetchHoroscope(signName),
                                    child: Text(
                                      'Retry',
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : prediction == null
                              ? Center(
                                  child: ElevatedButton(
                                    onPressed: () => _fetchHoroscope(signName),
                                    child: Text(
                                      'Load Horoscope',
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        sign['image'],
                                        height: 100,
                                        width: 100,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.error,
                                            color: Colors.white,
                                            size: 100,
                                          );
                                        },
                                      ),
                                      Text(
                                        signName,
                                        style: GoogleFonts.lora(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.text,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildPredictionContent(prediction),
                                    ],
                                  ),
                                ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionContent(HoroscopePrediction prediction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Personal', prediction.personal),
          _buildSection('Health', prediction.health),
          _buildSection('Profession', prediction.profession),
          _buildSection('Emotions', prediction.emotions),
          _buildSection('Travel', prediction.travel),
          const SizedBox(height: 16),
          Text(
            'Lucky Aspects',
            style: GoogleFonts.lora(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          ...prediction.luck.map(
            (luck) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(luck, style: GoogleFonts.poppins()),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lora(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(content, style: GoogleFonts.poppins()),
        ],
      ),
    );
  }
}
