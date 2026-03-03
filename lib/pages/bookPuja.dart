// Your imports
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar.dart';
import 'package:saamay/pages/smPujaItem.dart';
import 'package:saamay/pages/config.dart';
import 'package:google_fonts/google_fonts.dart';

// Popup data model
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

// Puja item model
class PujaItem {
  final int itemId;
  final String itemName;
  final double itemBasePrice;
  final String itemImageUrl;
  final String itemDescription;

  PujaItem({
    required this.itemId,
    required this.itemName,
    required this.itemBasePrice,
    required this.itemImageUrl,
    required this.itemDescription,
  });

  factory PujaItem.fromJson(Map<String, dynamic> json) {
    return PujaItem(
      itemId: json['item_id'],
      itemName: json['item_name'],
      itemBasePrice: json['item_base_price'] != null
          ? double.parse(json['item_base_price'].toString())
          : 0.0,
      itemImageUrl: json['item_image_url'],
      itemDescription: json['item_description'],
    );
  }
}

class BookPuja extends StatefulWidget {
  const BookPuja({Key? key}) : super(key: key);

  @override
  State<BookPuja> createState() => _BookPujaState();
}

class _BookPujaState extends State<BookPuja> {
  List<PujaItem> pujaItems = [];
  bool isLoading = true;
  String categoryName = "Puja Services";
  String errorMessage = "";
  Timer? _popupTimer;
  PopupData? _popupData;

  @override
  void initState() {
    super.initState();
    fetchPujaItems();
    _startPopupTimer();
  }

  @override
  void dispose() {
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
        Uri.parse('$api/popups/book-pooja'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
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
              color: const Color(0xFFF5E6D3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                          Text(
                            _popupData!.highlight,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.pink,
                            ),
                          ),
                          const SizedBox(height: 12),
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
        );
      },
    );
  }

  Future<void> fetchPujaItems() async {
    try {
      final response = await http.get(Uri.parse('$api/get_puja_items'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'Success') {
          setState(() {
            if (responseData['data'].isNotEmpty &&
                responseData['data'][0]['category_name'] != null) {
              categoryName = responseData['data'][0]['category_name'];
            }

            pujaItems = (responseData['data'] as List)
                .map((item) => PujaItem.fromJson(item))
                .toList();
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = "Failed to load data";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Server error: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Network error: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(child: Text(errorMessage))
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                categoryName.toUpperCase(),
                                style: GoogleFonts.lora(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: const Color(0xFF3E0505),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
                              ),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: pujaItems.length,
                              itemBuilder: (context, index) {
                                final item = pujaItems[index];
                                return _buildPujaCard(
                                  item.itemName,
                                  item.itemImageUrl,
                                  item.itemId,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPujaCard(String title, String imageUrl, int itemId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PujaItemDetails(itemId: itemId),
          ),
        );
      },
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 40),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 32,
                      child: Center(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        color: const Color(0xFFF7EBD6),
                        child: Center(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PujaItemDetails(itemId: itemId),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF800000),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                "Book now",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: const Color(0xFF800000),
                                ),
                              ),
                            ),
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
    );
  }
}
