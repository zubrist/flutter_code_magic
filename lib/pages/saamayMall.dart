import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar.dart';
import 'package:saamay/pages/config.dart';
import 'package:saamay/pages/saamayMallItems.dart';
import 'package:google_fonts/google_fonts.dart';

// Model class for category
class Category {
  final int categoryId;
  final String categoryName;
  final String categoryDescription;
  final bool categoryStatus;
  final String createdDate;

  Category({
    required this.categoryId,
    required this.categoryName,
    required this.categoryDescription,
    required this.categoryStatus,
    required this.createdDate,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      categoryDescription: json['category_description'],
      categoryStatus: json['category_status'],
      createdDate: json['created_date'],
    );
  }
}

// Model class for subcategory
class Subcategory {
  final int subcategoryId;
  final int categoryId;
  final String subcategoryName;
  final String subcategoryDescription;
  final bool subcategoryStatus;
  final String createdDate;

  Subcategory({
    required this.subcategoryId,
    required this.categoryId,
    required this.subcategoryName,
    required this.subcategoryDescription,
    required this.subcategoryStatus,
    required this.createdDate,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      subcategoryId: json['subcategory_id'],
      categoryId: json['category_id'],
      subcategoryName: json['subcategory_name'],
      subcategoryDescription: json['subcategory_description'],
      subcategoryStatus: json['subcategory_status'],
      createdDate: json['created_date'],
    );
  }
}

class SaamayMallPage extends StatefulWidget {
  const SaamayMallPage({Key? key}) : super(key: key);

  @override
  State<SaamayMallPage> createState() => _SaamayMallPageState();
}

class _SaamayMallPageState extends State<SaamayMallPage> {
  List<Category> categories = [];
  List<Subcategory> subcategories = [];
  bool isLoadingCategories = true;
  bool isLoadingSubcategories = false;
  String? errorMessage;
  bool showAllCategories = false; // Control whether to show all categories
  int? selectedCategoryId;
  String selectedCategoryName = '';

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$api/categories'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['Status'] == 'Successfull') {
          List<Category> fetchedCategories = [];
          for (var item in data['data']) {
            fetchedCategories.add(Category.fromJson(item));
          }

          setState(() {
            categories = fetchedCategories;
            isLoadingCategories = false;
          });

          // After fetching categories, fetch the subcategories of the first category
          if (fetchedCategories.isNotEmpty) {
            fetchSubcategories(fetchedCategories[0].categoryId);
            selectedCategoryName = fetchedCategories[0].categoryName;
          }
        } else {
          setState(() {
            errorMessage = 'Failed to load categories: ${data['Status']}';
            isLoadingCategories = false;
          });
        }
      } else {
        setState(() {
          errorMessage =
              'Failed to load categories. Status code: ${response.statusCode}';
          isLoadingCategories = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching categories: $e';
        isLoadingCategories = false;
      });
    }
  }

  Future<void> fetchSubcategories(int categoryId) async {
    setState(() {
      isLoadingSubcategories = true;
      selectedCategoryId = categoryId;
      errorMessage = null;

      // Find the category name for the selected category
      for (var category in categories) {
        if (category.categoryId == categoryId) {
          selectedCategoryName = category.categoryName;
          break;
        }
      }
    });

    try {
      final response = await http.get(
        Uri.parse('$api/sub_categories/$categoryId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['Status'] == 'Successful') {
          List<Subcategory> fetchedSubcategories = [];
          for (var item in data['data']) {
            fetchedSubcategories.add(Subcategory.fromJson(item));
          }

          setState(() {
            subcategories = fetchedSubcategories;
            isLoadingSubcategories = false;
          });
        } else {
          setState(() {
            errorMessage = 'Failed to load subcategories: ${data['Status']}';
            isLoadingSubcategories = false;
          });
        }
      } else {
        setState(() {
          errorMessage =
              'Failed to load subcategories. Status code: ${response.statusCode}';
          isLoadingSubcategories = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching subcategories: $e';
        isLoadingSubcategories = false;
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
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color.fromARGB(
                    255,
                    255,
                    250,
                    236,
                  ), // Starting color (your original beige)
                  Color.fromARGB(
                    255,
                    254,
                    233,
                    170,
                  ), // Middle color (example: gold)
                  Color.fromARGB(
                    255,
                    255,
                    250,
                    236,
                  ), // End color (example: orange)
                ],
              ),
            ),
            child: Text(
              'SAAMAY MALL',
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),

          // Loading indicator or error message or content
          if (isLoadingCategories)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (errorMessage != null)
            Expanded(
              child: Center(
                child: Text(
                  errorMessage!,
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Booking options - Category Grid (Limited or All based on showAllCategories)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.5,
                        ),
                        // Show only 2 items or all based on state
                        itemCount: showAllCategories
                            ? categories.length
                            : (categories.length >= 2 ? 2 : categories.length),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return _buildBookingCard(
                            title: "${category.categoryName.toUpperCase()}",
                            subtitle: category.categoryDescription,
                            icon: 'assets/images/category.png',
                            isSelected:
                                selectedCategoryId == category.categoryId,
                            onTap: () {
                              // Fetch subcategories when category is selected
                              fetchSubcategories(category.categoryId);
                            },
                          );
                        },
                      ),
                    ),

                    // More button - only show if there are more than 2 categories
                    if (categories.length > 2)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              showAllCategories = !showAllCategories;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  showAllCategories ? 'Show Less' : 'More',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Icon(
                                  showAllCategories
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Dynamic section title based on selected category
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: 8,
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            selectedCategoryId != null && categories.isNotEmpty
                                ? '${selectedCategoryName.toUpperCase()} SERVICES'
                                : 'PUJAS FOR BOOKING',
                            style: GoogleFonts.lora(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Subcategories display
                    // Subcategories display
                    if (isLoadingSubcategories)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (subcategories.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // Two items per row
                            childAspectRatio:
                                1.2, // Adjusted for better proportions
                            crossAxisSpacing: 12, // Horizontal spacing
                            mainAxisSpacing: 16, // Vertical spacing
                          ),
                          itemCount: subcategories.length,
                          itemBuilder: (context, index) {
                            final subcategory = subcategories[index];
                            return _buildPujaItem(
                              title: subcategory.subcategoryName,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SaamayMallItems(
                                      categoryId: subcategory.categoryId,
                                      subcategoryId: subcategory.subcategoryId,
                                    ),
                                  ),
                                );
                                //print("Selected subcategory: ${subcategory.subcategoryName}");
                              },
                            );
                          },
                        ),
                      )
                    else
                      // Default display if no subcategories
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                          children: [
                            _buildPujaItem(title: 'Grahan\nShanti Puja'),
                            _buildPujaItem(title: 'Dosh\nShanti Puja'),
                            _buildPujaItem(title: 'Graha\nShanti Puja'),
                            _buildPujaItem(title: 'Puja For\nBlessing'),
                          ],
                        ),
                      ),

                    // Add some bottom padding
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingCard({
    required String title,
    required String subtitle,
    required String icon,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? const Color(0xFFA4216A) : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? Colors.pink.shade50 : Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.lora(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: isSelected
                              ? const Color(0xFFA4216A)
                              : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    //color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Image(
                    image: AssetImage("assets/images/category.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPujaItem({required String title, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12), // Padding around the image
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1, // Makes the image square
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image(
                      image: AssetImage("assets/images/subcategory.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
