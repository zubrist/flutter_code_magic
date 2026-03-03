import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar.dart';
import 'package:saamay/pages/config.dart';
import 'package:saamay/pages/smPujaItem.dart';
import 'package:google_fonts/google_fonts.dart';

class PujaItem {
  final int itemId;
  final String itemName;
  final double itemBasePrice;
  final String? itemImageUrl; // Made nullable
  final String itemDescription;

  PujaItem({
    required this.itemId,
    required this.itemName,
    required this.itemBasePrice,
    this.itemImageUrl, // Made optional
    required this.itemDescription,
  });

  factory PujaItem.fromJson(Map<String, dynamic> json) {
    return PujaItem(
      itemId: json['item_id'] ?? 0,
      itemName: json['item_name'] ?? 'Unknown Item',
      itemBasePrice: (json['item_base_price'] ?? 0.0).toDouble(),
      itemImageUrl: json['item_image_url'], // Can be null
      itemDescription: json['item_description'] ?? '',
    );
  }
}

class SaamayMallItems extends StatefulWidget {
  final int categoryId;
  final int subcategoryId;

  const SaamayMallItems({
    Key? key,
    required this.categoryId,
    required this.subcategoryId,
  }) : super(key: key);

  @override
  State<SaamayMallItems> createState() => _SaamayMallItemsState();
}

class _SaamayMallItemsState extends State<SaamayMallItems> {
  List<PujaItem> pujaItems = [];
  bool isLoading = true;
  String categoryName = "";
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchPujaItems();
  }

  Future<void> fetchPujaItems() async {
    try {
      final response = await http.get(
        Uri.parse('$api/items/${widget.categoryId}/${widget.subcategoryId}'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['Status'] == 'Successful') {
          final List<dynamic> dataList = responseData['data'] ?? [];

          setState(() {
            categoryName = responseData['category_name'] ?? "Items";
            pujaItems =
                dataList.map((item) => PujaItem.fromJson(item)).toList();
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = responseData['message'] ?? "Failed to load data";
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
          // Content section
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? _buildErrorState()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = "";
              });
              fetchPujaItems();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              categoryName.toUpperCase(),
              style: GoogleFonts.lora(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF3E0505),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Check if pujaItems is empty
          if (pujaItems.isEmpty)
            _buildEmptyState()
          else
            // Grid of puja items
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: pujaItems.length,
              itemBuilder: (context, index) {
                final item = pujaItems[index];
                return _buildPujaCard(
                  item.itemName,
                  item.itemBasePrice.toStringAsFixed(0),
                  item.itemImageUrl,
                  item.itemId,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No items available',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new items',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPujaCard(
    String title,
    String price,
    String? imageUrl, // Made nullable
    int itemId,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PujaItemDetails(itemId: itemId),
        ),
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Puja Image with null safety
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImage(imageUrl),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Puja Title with fixed height for 2 lines
                    SizedBox(
                      height: 36,
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Price and Book Now - This will now always be at the bottom
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7EBD6),
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Price
                          Text(
                            "₹$price",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF800000),
                              fontSize: 14,
                            ),
                          ),
                          // Book now button
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PujaItemDetails(itemId: itemId),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(4),
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
                                  fontSize: 12,
                                  color: Color(0xFF800000),
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildImage(String? imageUrl) {
    // Handle null or empty image URL
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: 140,
        width: double.infinity,
        color: Colors.grey[200],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No Image',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Valid image URL
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      height: 140,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 140,
          width: double.infinity,
          color: Colors.grey[200],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 40,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'Image Error',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 140,
          width: double.infinity,
          color: Colors.grey[100],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }
}
