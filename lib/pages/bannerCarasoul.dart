import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'recharge.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({Key? key}) : super(key: key);

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  int _currentCarouselIndex = 0;
  List<dynamic> banners = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchBanners();
  }

  Future<void> fetchBanners() async {
    try {
      final response = await http.get(Uri.parse('$api/banners/mobuiapp'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'Success' && data['data'] != null) {
          ////print(data);
          setState(() {
            banners = data['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'No banner data available';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load banners: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching banners: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }

    if (banners.isEmpty) {
      return const Center(child: Text('No banners available'));
    }

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 200,
            viewportFraction: 1,
            autoPlay: true,
            enlargeCenterPage: true,
            autoPlayInterval: const Duration(seconds: 3),
            onPageChanged: (index, reason) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
          ),
          items: banners.map((banner) {
            return Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    if (banner['routing_link'] != null) {
                      print('Navigating to: ${banner['routing_link']}');

                      if (banner['routing_link'] == '/makepayment') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RechargePage()),
                        );
                      }
                    }

                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(banner['image_banner']),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            banner['banner_text'] ?? 'No Title',
                            style: GoogleFonts.lora(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: banners.asMap().entries.map((entry) {
            return Container(
              width: 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentCarouselIndex == entry.key
                    ? AppColors.primary
                    : Colors.grey.shade300,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
