import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/astrologerProfilePage.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar.dart';
import 'package:saamay/pages/config.dart';
import 'package:saamay/pages/login.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saamay/pages/follow_service.dart';

class AstrologersPage extends StatefulWidget {
  final String title;

  const AstrologersPage({Key? key, required this.title}) : super(key: key);

  @override
  State<AstrologersPage> createState() => _AstrologersPageState();
}

class _AstrologersPageState extends State<AstrologersPage> {
  Set<int> _followedConsultantIds = {};

  Future<void> _fetchFollowedConsultants() async {
    if (token != null && token != '') {
      final ids = await FollowService.fetchFollowedConsultants(token);
      setState(() {
        _followedConsultantIds = ids.toSet();
      });
    } else {
      setState(() {
        _followedConsultantIds = {};
      });
    }
  }

  List<Map<String, dynamic>> astrologers = [];
  List<Map<String, dynamic>> popularAstrologers = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  List<String> _selectedLanguages = [];
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = '';
  String _Category = "";
  String _selectedSortBy = 'all';
  String _selectedSortOrder = 'all';

  final List<String> _categories = [
    'All',
    'Vedic',
    'Vastu',
    'Tarot',
    'Numerology',
    'Reiki',
  ];

  final List<Map<String, String>> _sortOptions = [
    {'label': 'Default', 'sortBy': 'all', 'sortOrder': 'all'},
    {'label': 'Experience', 'sortBy': 'year_of_experience', 'sortOrder': 'all'},
    {'label': 'Rating (High to Low)', 'sortBy': 'rating', 'sortOrder': 'desc'},
    {'label': 'Rating (Low to High)', 'sortBy': 'rating', 'sortOrder': 'asc'},
    {'label': 'Price (Low to High)', 'sortBy': 'rate', 'sortOrder': 'asc'},
    {'label': 'Price (High to Low)', 'sortBy': 'rate', 'sortOrder': 'desc'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchAstrologerData();
    _fetchPopularAstrologers();
    _fetchFollowedConsultants();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.8 &&
          !_isLoadingMore &&
          _hasMoreData) {
        _fetchAstrologerData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() {
      astrologers = [];
      popularAstrologers = [];
      _currentPage = 1;
      _hasMoreData = true;
      _isLoading = true;
      _isLoadingMore = false;
    });
    try {
      await Future.wait([_fetchAstrologerData(), _fetchPopularAstrologers()]);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to refresh astrologers. Please try again.'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAstrologerData() async {
    if (_isLoadingMore) return;
    String cat = _Category.isEmpty ? widget.title : _Category;
    _selectedCategory = cat;
    String languageParam =
        _selectedLanguages.isEmpty ? 'all' : _selectedLanguages.join(',');

    final url =
        '$api/consultant_by_filters/Astrology/$cat/$languageParam/$_selectedSortBy/$_selectedSortOrder/18/$_currentPage';

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'Success' && data['data'] != null) {
          final List astrologerData = data['data'];

          setState(() {
            if (astrologerData.isEmpty) {
              _hasMoreData = false;
            } else {
              final filteredData =
                  astrologerData.where((item) => item['id'] != 1).toList();

              astrologers.addAll(
                filteredData.map((item) {
                  return {
                    "id": item['id'],
                    "name": item['display_name'],
                    "skills": item['area_of_spec'],
                    "languages": item['language'],
                    "experience": "${item['year_of_experience']} Years",
                    "rating": item['rating'] != null
                        ? double.tryParse(item['rating'].toString()) ?? 0.0
                        : 0.0,
                    "orders": item['order_count'],
                    "price": item['rate'].toString(),
                    "language": item['language'] ?? "",
                    "image_link": item['image_link'] ?? 'default_image_url',
                    "availability_flag": item['availability_flag'],
                    "availability_service_id":
                        item['availability_service_id'], // Added this line
                    "rate": item['rate'],
                  };
                }).toList(),
              );
              _currentPage++;
            }
          });
        } else {
          throw Exception('Unexpected response format or no data');
        }
      } else {
        throw Exception(
          'Failed to load astrologer data. Status code: ${response.statusCode}',
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load astrologers. Please try again.'),
        ),
      );
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _fetchPopularAstrologers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      const url =
          '$api/consultant_by_filters/Astrology/all/all/rating/desc/18/1';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'Success' && data['data'] != null) {
          final List popularData = data['data'];

          setState(() {
            popularAstrologers = popularData.map((item) {
              return {
                "id": item['id'],
                "name": item['display_name'],
                "skills": item['area_of_spec'],
                "experience": "${item['year_of_experience']} Years",
                "rating": item['rating'] != null
                    ? double.tryParse(item['rating'].toString()) ?? 0.0
                    : 0.0,
                "price": item['rate'].toString(),
                "language": item['language'] ?? "",
                "image_link": item['image_link'] ?? 'default_image_url',
                "availability_service_id":
                    item['availability_service_id'], // Added this line
                "rate": item['rate'],
              };
            }).toList();
          });
        }
      }
    } catch (error) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilter(String category) {
    setState(() {
      _selectedCategory = category;
      _Category = category;
      astrologers = [];
      _currentPage = 1;
      _hasMoreData = true;
    });
    _fetchAstrologerData();
  }

  void _applySorting(String sortBy, String sortOrder) {
    setState(() {
      _selectedSortBy = sortBy;
      _selectedSortOrder = sortOrder;
      astrologers = [];
      _currentPage = 1;
      _hasMoreData = true;
    });
    _fetchAstrologerData();
  }

  void showSortDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sort, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Sort By',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _sortOptions.length,
                  itemBuilder: (context, index) {
                    final option = _sortOptions[index];
                    final isSelected = _selectedSortBy == option['sortBy'] &&
                        _selectedSortOrder == option['sortOrder'];

                    return ListTile(
                      title: Text(
                        option['label']!,
                        style: GoogleFonts.poppins(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primary : Colors.black,
                        ),
                      ),
                      leading: Radio(
                        value: '${option['sortBy']}_${option['sortOrder']}',
                        groupValue: '${_selectedSortBy}_${_selectedSortOrder}',
                        onChanged: (String? value) {
                          _applySorting(
                            option['sortBy']!,
                            option['sortOrder']!,
                          );
                          Navigator.pop(context);
                        },
                      ),
                      onTap: () {
                        _applySorting(option['sortBy']!, option['sortOrder']!);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void showFilterDialog(BuildContext context) {
    Map<String, bool> selectedLanguages = {
      'English': _selectedLanguages.contains('English'),
      'Hindi': _selectedLanguages.contains('Hindi'),
      'Bengali': _selectedLanguages.contains('Bengali'),
      'Telugu': _selectedLanguages.contains('Telugu'),
      'Marathi': _selectedLanguages.contains('Marathi'),
      'Tamil': _selectedLanguages.contains('Tamil'),
      'Urdu': _selectedLanguages.contains('Urdu'),
      'Gujrati': _selectedLanguages.contains('Gujrati'),
      'Malayalam': _selectedLanguages.contains('Malayalam'),
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Filters',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromRGBO(250, 214, 192, 1),
                          Color.fromRGBO(247, 231, 210, 1),
                          Color.fromRGBO(250, 214, 192, 1),
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Language',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFAE8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListView(
                        children: selectedLanguages.keys.map((language) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: selectedLanguages[language],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        selectedLanguages[language] = value!;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  language,
                                  style: GoogleFonts.poppins(fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              selectedLanguages.updateAll(
                                (key, value) => false,
                              );
                            });
                          },
                          child: Text(
                            'Clear All',
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.button,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              List<String> selectedLangs = selectedLanguages
                                  .entries
                                  .where((entry) => entry.value)
                                  .map((entry) => entry.key)
                                  .toList();
                              Navigator.pop(context, selectedLangs);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Apply',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((value) {
      if (value != null) {
        setState(() {
          _selectedLanguages = value;
          astrologers = [];
          _currentPage = 1;
          _hasMoreData = true;
        });
        _fetchAstrologerData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
      appBar: CustomAppBar(),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: Colors.white,
              onRefresh: _onRefresh,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 5),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'MOST POPULARS',
                          style: GoogleFonts.lora(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: popularAstrologers.length,
                            itemBuilder: (context, index) {
                              final astrologer = popularAstrologers[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AstrologerProfilePage(
                                        consultantId: astrologer['id'],
                                        rate: astrologer['rate'],
                                        availabilityServiceId: astrologer[
                                            'availability_service_id'], // Added this line
                                      ),
                                    ),
                                  ).then((_) {
                                    _onRefresh();
                                  });
                                },
                                child: _buildPopularAstrologerCard(
                                  astrologer['name'] ?? 'Unknown',
                                  astrologer['experience'] ?? 'Experience: ',
                                  '₹${astrologer['price'] ?? '0'}/min',
                                  (astrologer['skills'] as String?)?.split(
                                        ',',
                                      ) ??
                                      [],
                                  astrologer['image_link'],
                                  astrologer['language'] ?? '',
                                  rating:
                                      astrologer['rating']?.toDouble() ?? 0.0,
                                ),
                              );
                            },
                          ),
                        ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'LIST OF ASTROLOGERS',
                          style: GoogleFonts.lora(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 35,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => showFilterDialog(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.tune, size: 12),
                                SizedBox(width: 6),
                                Text(
                                  'Filters',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => showSortDialog(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.sort, size: 12),
                                SizedBox(width: 6),
                                Text(
                                  'Sort',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => _applyFilter(_categories[index]),
                                child: _buildCategoryChip(
                                  _categories[index],
                                  isSelected:
                                      _selectedCategory == _categories[index],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  ...astrologers.map(
                    (astrologer) => _buildAstrologerListItem(
                      astrologer['name'] ?? 'Unknown',
                      astrologer['experience'] ?? 'Experience: ',
                      astrologer['languages'] ?? '',
                      (astrologer['skills'] as String?)?.split(',') ?? [],
                      '₹${astrologer['price'] ?? '0'}/mins',
                      astrologer['availability_flag'],
                      astrologer['image_link'],
                      rating: astrologer['rating']?.toDouble() ?? 0.0,
                      id: astrologer['id'],
                      rate: astrologer['rate'],
                      availabilityServiceId: astrologer[
                          'availability_service_id'], // Added this parameter
                    ),
                  ),
                  if (_isLoadingMore)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    ),
                  if (!_hasMoreData && astrologers.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      alignment: Alignment.center,
                      child: Text(
                        'No more astrologers to load',
                        style: GoogleFonts.poppins(color: Colors.grey.shade600),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularAstrologerCard(
    String name,
    String experience,
    String price,
    List<String> specialties,
    String imageUrl,
    String languages, {
    double rating = 0.0,
  }) {
    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              clipBehavior: Clip.hardEdge,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.person, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: GoogleFonts.lora(fontWeight: FontWeight.w600, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            "Exp: $experience",
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),
          Container(
            height: 28,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.background,
            ),
            child: Center(
              child: Text(
                price,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, {bool isSelected = false}) {
    final gradientColors = [
      Color.fromRGBO(250, 214, 192, 1),
      Color.fromRGBO(247, 231, 210, 1),
      Color.fromRGBO(250, 214, 192, 1),
    ];

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.text : null,
        gradient: isSelected
            ? null
            : LinearGradient(
                colors: gradientColors,
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: isSelected ? Color.fromRGBO(250, 214, 192, 1) : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildAstrologerListItem(
    String name,
    String experience,
    String languages,
    List<String> specialties,
    String price,
    String availability_flag,
    String imageUrl, {
    double rating = 0.0,
    required dynamic id,
    required double rate,
    required int? availabilityServiceId, // Added this parameter
  }) {
    final displaySpecialties =
        specialties.length > 3 ? specialties.sublist(0, 3) : specialties;

    Color availabilityColor;
    String availabilityText;
    if (availability_flag == "A") {
      availabilityColor = Color(0xFF28A746);
      availabilityText = "Available";
    } else if (availability_flag == "B") {
      availabilityColor = Color(0xFFDC3546);
      availabilityText = "Busy";
    } else {
      availabilityColor = Colors.grey;
      availabilityText = "Offline";
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AstrologerProfilePage(
            consultantId: id,
            rate: rate,
            availabilityServiceId:
                availabilityServiceId, // Added this parameter
          ),
        ),
      ).then((_) {
        _onRefresh();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        margin: const EdgeInsets.only(bottom: 5),
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    height: 100,
                    width: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.lora(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 20,
                        decoration: BoxDecoration(
                          color: availabilityColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            availabilityText,
                            style: GoogleFonts.poppins(
                              color: availabilityColor,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 13),
                    ],
                  ),
                  Text(
                    'Exp: $experience',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    languages,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: displaySpecialties.map((specialty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(254, 244, 239, 1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          specialty.trim(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppColors.text,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(252, 247, 239, 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          price,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: AppColors.text,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.button,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (availability_flag == 'A') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AstrologerProfilePage(
                                      consultantId: id,
                                      rate: rate,
                                      availabilityServiceId:
                                          availabilityServiceId, // Added this parameter
                                    ),
                                  ),
                                ).then((_) {
                                  _onRefresh();
                                });
                              } else {
                                token == ''
                                    ? Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LoginPage(),
                                        ),
                                      )
                                    : showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          DateTime selectedDate =
                                              DateTime.now();
                                          TimeOfDay selectedTime =
                                              TimeOfDay.now();
                                          return StatefulBuilder(
                                            builder: (context, setState) {
                                              return AlertDialog(
                                                backgroundColor: Colors.white,
                                                title: Text(
                                                  "Request for availability",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.text,
                                                  ),
                                                ),
                                                content: SingleChildScrollView(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      ListTile(
                                                        title: const Text(
                                                          "Date",
                                                        ),
                                                        subtitle: Text(
                                                          "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                                                        ),
                                                        trailing: const Icon(
                                                          Icons.calendar_today,
                                                        ),
                                                        onTap: () async {
                                                          final DateTime?
                                                              picked =
                                                              await showDatePicker(
                                                            context: context,
                                                            initialDate:
                                                                selectedDate,
                                                            firstDate:
                                                                DateTime.now(),
                                                            lastDate:
                                                                DateTime.now()
                                                                    .add(
                                                              const Duration(
                                                                days: 30,
                                                              ),
                                                            ),
                                                          );
                                                          if (picked != null &&
                                                              picked !=
                                                                  selectedDate) {
                                                            setState(() {
                                                              selectedDate =
                                                                  picked;
                                                            });
                                                          }
                                                        },
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      ListTile(
                                                        title: const Text(
                                                          "Time",
                                                        ),
                                                        subtitle: Text(
                                                          "${selectedTime.format(context)}",
                                                        ),
                                                        trailing: const Icon(
                                                          Icons.access_time,
                                                        ),
                                                        onTap: () async {
                                                          final TimeOfDay?
                                                              picked =
                                                              await showTimePicker(
                                                            context: context,
                                                            initialTime:
                                                                selectedTime,
                                                          );
                                                          if (picked != null &&
                                                              picked !=
                                                                  selectedTime) {
                                                            setState(() {
                                                              selectedTime =
                                                                  picked;
                                                            });
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                    },
                                                    child: Text(
                                                      "Cancel",
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color:
                                                            AppColors.lightText,
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      final formattedDate =
                                                          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                                                      final formattedTime =
                                                          "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";

                                                      final payload = {
                                                        "consultant_id": id,
                                                        "date": formattedDate,
                                                        "time": formattedTime,
                                                      };

                                                      try {
                                                        showDialog(
                                                          context: context,
                                                          barrierDismissible:
                                                              false,
                                                          builder: (
                                                            BuildContext
                                                                context,
                                                          ) {
                                                            return const Center(
                                                              child:
                                                                  CircularProgressIndicator(),
                                                            );
                                                          },
                                                        );

                                                        final response =
                                                            await http.post(
                                                          Uri.parse(
                                                            '$api/whatsapp_for_slot_request',
                                                          ),
                                                          headers: {
                                                            'Content-Type':
                                                                'application/json',
                                                            'Authorization':
                                                                'Bearer $token',
                                                          },
                                                          body: jsonEncode(
                                                            payload,
                                                          ),
                                                        );

                                                        Navigator.of(
                                                          context,
                                                        ).pop();

                                                        if (response
                                                                .statusCode ==
                                                            200) {
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                        } else if (response.statusCode == 429) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text('Too Many Request-Please try after sometime'),
                                                              backgroundColor: Colors.orange,
                                                            ),
                                                          );
                                                        }else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'Error: ${response.reasonPhrase}',
                                                              ),
                                                              backgroundColor:
                                                                  Colors.red,
                                                            ),
                                                          );
                                                        }
                                                      } catch (e) {
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'Network Error: $e',
                                                            ),
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    child: Text(
                                                      "Submit",
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color: AppColors.text,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                            ),
                            child: availability_flag == 'A'
                                ? Text(
                                    'Book now',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textwhite,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Image.asset(
                                      'assets/icons/chat.png',
                                      width: 20,
                                      height: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Builder(
                          builder: (context) {
                            final isLoggedIn = token != null && token != '';
                            final isFollowed = isLoggedIn &&
                                _followedConsultantIds.contains(id);
                            return GestureDetector(
                              onTap: () async {
                                if (!isLoggedIn) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoginPage(),
                                    ),
                                  );
                                  return;
                                }
                                try {
                                  final response = await http.post(
                                    Uri.parse('$api/follow_consultant/$id'),
                                    headers: {
                                      'Authorization': 'Bearer $token',
                                      'Content-Type': 'application/json',
                                    },
                                  );
                                  if (response.statusCode == 200) {
                                    final data = jsonDecode(response.body);
                                    if (data['status'] == 'Success') {
                                      setState(() {
                                        if (data['action'] == 'followed') {
                                          _followedConsultantIds.add(id);
                                        } else if (data['action'] ==
                                            'unfollowed') {
                                          _followedConsultantIds.remove(id);
                                        }
                                      });
                                    }
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Network error, please try again.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Icon(
                                isFollowed
                                    ? Icons.thumb_up
                                    : Icons.thumb_up_outlined,
                                color: isFollowed ? Colors.red : Colors.red,
                                size: 20,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
