import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar2.dart';
import 'package:saamay/pages/config.dart';
import 'package:saamay/pages/smpayment.dart';
import 'package:saamay/pages/login.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class PujaItemModel {
  final String itemName;
  final String itemDescription;
  final String itemImageUrl;
  final String? vendorImageUrl;
  final double itemBasePrice;
  final String categoryName;
  final int vendorId;
  final String vendorName;
  final String vendorDescription;
  final String vendorFees;
  final String? itemPromotionCode;
  final String? itemPromotionDdescription;
  final double? itemPromotionValue;
  final int? promotionId;

  PujaItemModel({
    required this.itemName,
    required this.itemDescription,
    required this.itemImageUrl,
    this.vendorImageUrl,
    required this.itemBasePrice,
    required this.categoryName,
    required this.vendorId,
    required this.vendorName,
    required this.vendorDescription,
    required this.vendorFees,
    this.itemPromotionCode,
    this.itemPromotionDdescription,
    this.itemPromotionValue,
    this.promotionId,
  });

  factory PujaItemModel.fromJson(Map<String, dynamic> json) {
    return PujaItemModel(
      itemName: json['item_name'] ?? '',
      itemDescription: json['item_description'] ?? '',
      itemImageUrl: json['item_image_url'] ?? '',
      vendorImageUrl: json['vendor_image_url'] as String?,
      itemBasePrice: (json['item_base_price'] ?? 0.0).toDouble(),
      categoryName: json['category_name'] ?? '',
      vendorId: json['vendor_id'] ?? 0,
      vendorName: json['vendor_name'] ?? '',
      vendorDescription: json['vendor_description'] ?? '',
      vendorFees: json['vendor_fees'] ?? '0',
      itemPromotionCode: json['item_promotion_code'] as String?,
      itemPromotionDdescription: json['item_promotion_description'] as String?,
      itemPromotionValue: json['item_promotion_value']?.toDouble(),
      promotionId: json['promotion_id'] as int?,
    );
  }
}

class ConsultantModel {
  final int id;
  final String name;
  final String displayName;
  final String areaOfSpecialization;
  final int yearOfExperience;
  final String? imageLink;

  ConsultantModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.areaOfSpecialization,
    required this.yearOfExperience,
    this.imageLink,
  });

  factory ConsultantModel.fromJson(Map<String, dynamic> json) {
    return ConsultantModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? '',
      areaOfSpecialization: json['area_of_specialization'] ?? '',
      yearOfExperience: json['year_of_experience'] ?? 0,
      imageLink: json['image_link'] as String?,
    );
  }
}

class NetworkImageWithFallback extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const NetworkImageWithFallback({
    Key? key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallbackWidget();
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildLoadingWidget(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
      filterQuality: FilterQuality.high,
      httpHeaders: {'User-Agent': 'Mozilla/5.0 (compatible; Flutter app)'},
      cacheKey: imageUrl,
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
      ),
    );
  }

  Widget _buildFallbackWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.person, size: 40, color: Colors.grey),
      ),
    );
  }
}

class PujaItemDetails extends StatefulWidget {
  final int itemId;

  const PujaItemDetails({Key? key, required this.itemId}) : super(key: key);

  @override
  _PujaItemDetailsState createState() => _PujaItemDetailsState();
}

class _PujaItemDetailsState extends State<PujaItemDetails> {
  bool isLoading = true;
  String errorMessage = '';
  List<PujaItemModel> vendors = [];
  String categoryName = '';
  int selectedVendorIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchPujaItemDetails();
  }

  Future<void> fetchPujaItemDetails() async {
    try {
      final response = await http.get(
        Uri.parse('$api/get_vendors_items/${widget.itemId}'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; Flutter app)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        if (jsonData['status'] == 'Success') {
          final List<dynamic> data = jsonData['data'];
          setState(() {
            vendors = data.map((item) => PujaItemModel.fromJson(item)).toList();
            categoryName = jsonData['category_name'] ?? '';
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'Failed to load data';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _navigateToSelectAstrologer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SelectAstrologerPage(vendors: vendors, itemId: widget.itemId),
      ),
    );

    if (result != null && result is int) {
      setState(() {
        selectedVendorIndex = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('Error', style: GoogleFonts.lora())),
        body: Center(child: Text(errorMessage, style: GoogleFonts.poppins())),
      );
    }

    if (vendors.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('No Data', style: GoogleFonts.lora())),
        body: Center(
          child: Text(
            'No vendors available for this item',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }

    final selectedVendor = vendors[selectedVendorIndex];
    final totalPrice =
        selectedVendor.itemBasePrice + double.parse(selectedVendor.vendorFees);

    return Scaffold(
      backgroundColor: AppColors.background, // Added this line
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Stack(
                children: [
                  NetworkImageWithFallback(
                    imageUrl: selectedVendor.itemImageUrl,
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.4,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.image_not_supported,
                              size: 60,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Image not available',
                              style: GoogleFonts.poppins(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  transform: Matrix4.translationValues(0, -40, 0),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 80,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              selectedVendor.itemName,
                              style: GoogleFonts.lora(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const SizedBox(height: 24),
                          _buildSectionCard(
                            Html(
                              data: selectedVendor.itemDescription,
                              style: {
                                "body": Style(
                                  fontSize: FontSize(14),
                                  color: Colors.black87,
                                  lineHeight: LineHeight(1.5),
                                  margin: Margins.zero,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                ),
                                "h1": Style(
                                  fontSize: FontSize(24),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  margin: Margins.only(top: 16, bottom: 8),
                                  fontFamily: GoogleFonts.lora().fontFamily,
                                ),
                                "h2": Style(
                                  fontSize: FontSize(20),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  margin: Margins.only(top: 16, bottom: 8),
                                  fontFamily: GoogleFonts.lora().fontFamily,
                                ),
                                "h3": Style(
                                  fontSize: FontSize(18),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  margin: Margins.only(top: 16, bottom: 8),
                                  fontFamily: GoogleFonts.lora().fontFamily,
                                ),
                                "h4": Style(
                                  fontSize: FontSize(16),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  margin: Margins.only(top: 16, bottom: 8),
                                  fontFamily: GoogleFonts.lora().fontFamily,
                                ),
                                "h5": Style(
                                  fontSize: FontSize(14),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  margin: Margins.only(top: 16, bottom: 8),
                                  fontFamily: GoogleFonts.lora().fontFamily,
                                ),
                                "h6": Style(
                                  fontSize: FontSize(12),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  margin: Margins.only(top: 16, bottom: 8),
                                  fontFamily: GoogleFonts.lora().fontFamily,
                                ),
                                "ul": Style(
                                  margin: Margins.only(
                                    left: 16,
                                    top: 8,
                                    bottom: 8,
                                  ),
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                ),
                                "li": Style(
                                  fontSize: FontSize(14),
                                  color: Colors.black87,
                                  margin: Margins.only(bottom: 4),
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                ),
                                "p": Style(
                                  fontSize: FontSize(14),
                                  color: Colors.black87,
                                  lineHeight: LineHeight(1.5),
                                  margin: Margins.only(bottom: 8),
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                ),
                                "strong": Style(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                ),
                                "b": Style(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                ),
                                "em": Style(
                                  fontStyle: FontStyle.italic,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                ),
                                "i": Style(
                                  fontStyle: FontStyle.italic,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                ),
                                "span": Style(
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                ),
                                "div": Style(
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                ),
                                "a": Style(
                                  color: Colors.blue,
                                  textDecoration: TextDecoration.underline,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                ),
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _navigateToSelectAstrologer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: AppColors.button,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 50),
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 16,
                        bottom: 16,
                        left: 20,
                        right: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Book Now',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(Widget content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [content],
      ),
    );
  }
}

class SelectAstrologerPage extends StatefulWidget {
  final List<PujaItemModel>? vendors;
  final List<ConsultantModel>? consultants;
  final double? itemBasePrice;
  final int? itemId;

  const SelectAstrologerPage({
    Key? key,
    this.vendors,
    this.consultants,
    this.itemBasePrice,
    this.itemId,
  })  : assert(
          vendors != null || consultants != null,
          'Either vendors or consultants must be provided',
        ),
        super(key: key);

  @override
  _SelectAstrologerPageState createState() => _SelectAstrologerPageState();
}

class _SelectAstrologerPageState extends State<SelectAstrologerPage> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final isVendorMode = widget.vendors != null;
    final items = isVendorMode ? widget.vendors! : widget.consultants!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar2(title: "Select Specialist"),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Text(
              isVendorMode ? 'BEST IN FIELD' : 'CHOOSE YOUR OWN',
              style: GoogleFonts.lora(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio:
                    0.8, // Increased aspect ratio to provide more height
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildCard(context, items[index], index, isVendorMode);
              },
            ),
          ),
          if (isVendorMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final response = await http.get(
                      Uri.parse('$api/all_consultants/Astrology'),
                      headers: {
                        'User-Agent': 'Mozilla/5.0 (compatible; Flutter app)',
                        'Accept': 'application/json',
                      },
                    ).timeout(const Duration(seconds: 10));

                    if (response.statusCode == 200) {
                      final jsonData = json.decode(
                        utf8.decode(response.bodyBytes),
                      );
                      if (jsonData['status'] == 'Success') {
                        final List<dynamic> data = jsonData['data'];
                        final List<ConsultantModel> consultants = data
                            .map((item) => ConsultantModel.fromJson(item))
                            .toList();

                        final double itemBasePrice =
                            widget.vendors != null && widget.vendors!.isNotEmpty
                                ? widget.vendors![0].itemBasePrice
                                : 0.0;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SelectAstrologerPage(
                              consultants: consultants,
                              itemBasePrice: itemBasePrice,
                              itemId: widget.itemId,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to load consultants',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Server error: ${response.statusCode}',
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error: ${e.toString()}',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.primary, width: 1),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    alignment: Alignment.center,
                    child: Text(
                      'Choose on your own →',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: selectedIndex != null
                  ? () {
                      if (token == null || token.isEmpty) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                        return;
                      }

                      if (isVendorMode) {
                        final vendor = widget.vendors![selectedIndex!];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AstrologerPaymentScreen(
                              vendorData: {
                                'vendor_fees': vendor.vendorFees,
                                'vendor_name': vendor.vendorName,
                                'vendor_description': vendor.vendorDescription,
                                'category_name': vendor.categoryName,
                                'item_name': vendor.itemName,
                                'item_description': vendor.itemDescription,
                                'item_base_price':
                                    vendor.itemBasePrice.toString(),
                                'promotion_id': vendor.promotionId,
                                'item_promotion_code': vendor.itemPromotionCode,
                                'item_promotion_description':
                                    vendor.itemPromotionDdescription,
                                'item_promotion_value':
                                    vendor.itemPromotionValue,
                                'vendor_id': vendor.vendorId,
                                'item_id': widget.itemId,
                              },
                              mode: 'vendor',
                            ),
                          ),
                        );
                      } else {
                        final consultant = widget.consultants![selectedIndex!];
                        final double basePrice = widget.itemBasePrice ?? 0.0;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AstrologerPaymentScreen(
                              vendorData: {
                                'vendor_fees': basePrice.toInt().toString(),
                                'vendor_name': consultant.displayName,
                                'vendor_description':
                                    consultant.areaOfSpecialization,
                                'item_name': 'Astrology Consultation',
                                'item_description':
                                    'Consultation with ${consultant.displayName}',
                                'item_base_price': basePrice.toString(),
                                'consultant_id': consultant.id,
                                'item_id': widget.itemId,
                              },
                              mode: 'consultant',
                            ),
                          ),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: selectedIndex != null ? AppColors.button : null,
                  color: selectedIndex == null ? Colors.transparent : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  alignment: Alignment.center,
                  child: Text(
                    'Confirm',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          selectedIndex != null ? Colors.white : Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    dynamic item,
    int index,
    bool isVendorMode,
  ) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),
        child: Container(
          height: 200, // Fixed height to prevent overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              Container(
                height: 90, // Reduced height to accommodate text
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Center(
                    child: NetworkImageWithFallback(
                      imageUrl: isVendorMode
                          ? (item as PujaItemModel).vendorImageUrl
                          : (item as ConsultantModel).imageLink,
                      height: 90,
                      fit: BoxFit.fitHeight,
                      placeholder: Container(
                        height: 90,
                        width: double.infinity,
                        decoration: const BoxDecoration(color: Colors.grey),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: Container(
                        height: 90,
                        width: double.infinity,
                        decoration: BoxDecoration(color: Colors.grey[300]),
                        child: const Center(
                          child: Icon(
                            Icons.person,
                            size: 35,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Text content section with fixed height
              Container(
                height: 110, // Fixed height for text section
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Container(
                      height: 18, // Fixed height for name
                      child: Text(
                        isVendorMode
                            ? (item as PujaItemModel).vendorName
                            : (item as ConsultantModel).displayName,
                        style: GoogleFonts.lora(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Description - Fixed height for exactly 2 lines
                    Container(
                      height:
                          32, // Fixed height for exactly 2 lines (16px per line)
                      child: Text(
                        isVendorMode
                            ? (item as PujaItemModel).vendorDescription
                            : (item as ConsultantModel).areaOfSpecialization,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey[600],
                          height: 1.4, // Line height for better readability
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Price section
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: const Color(0xFFF7EBD6),
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        child: Center(
                          child: Text(
                            isVendorMode
                                ? '₹${(item as PujaItemModel).vendorFees}'
                                : '₹${widget.itemBasePrice?.toInt() ?? 0}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
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
    );
  }
}
