import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

class SearchPopupCard extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final Function(String) onSuggestionTapped;
  final double width;
  final String searchQuery;
  final List<Map<String, dynamic>> filteredSuggestions;
  final List<Map<String, dynamic>> trendingTopics;

  const SearchPopupCard({
    Key? key,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSuggestionTapped,
    required this.width,
    required this.searchQuery,
    required this.filteredSuggestions,
    required this.trendingTopics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show Most Relevant section only when typing
            if (searchQuery.isNotEmpty && filteredSuggestions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  "MOST RELEVANT",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),

              // Filtered suggestions based on search query
              ...filteredSuggestions
                  .map(
                    (suggestion) => _buildSuggestionItem(
                      suggestion["name"],
                      suggestion["icon"],
                    ),
                  )
                  .toList(),

              Divider(height: 24),
            ],

            // Trending Topics Section (always visible)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                "TRENDING TOPICS",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),

            // Trending Items
            ...trendingTopics
                .map(
                  (topic) => _buildSuggestionItem(topic["name"], topic["icon"]),
                )
                .toList(),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(String text, IconData icon) {
    return InkWell(
      onTap: () => onSuggestionTapped(text),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
              ),
              child: Icon(icon, size: 20, color: Colors.grey[700]),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class SearchBarWithPopup extends StatefulWidget {
  const SearchBarWithPopup({Key? key}) : super(key: key);

  @override
  State<SearchBarWithPopup> createState() => _SearchBarWithPopupState();
}

class _SearchBarWithPopupState extends State<SearchBarWithPopup> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showPopup = false;
  final GlobalKey _searchBarKey = GlobalKey();
  double _searchBarWidth = 0;
  String _searchQuery = "";

  // Sample data - this would typically come from your backend or local database
  final List<Map<String, dynamic>> _allAstrologers = [
    {"name": "Astrologer Prasun", "icon": Icons.person_outline},
    {"name": "Astrologer Suvra", "icon": Icons.person_outline},
    {"name": "Astrologer Abhishek", "icon": Icons.person_outline},
    {"name": "Astrologer Rajiv", "icon": Icons.person_outline},
    {"name": "Astrologer Meena", "icon": Icons.person_outline},
    {"name": "Astrologer Deepak", "icon": Icons.person_outline},
    {"name": "Astrologer Priya", "icon": Icons.person_outline},
  ];

  final List<Map<String, dynamic>> _trendingTopics = [
    {"name": "Astrologer Consultation", "icon": Icons.question_answer_outlined},
    {"name": "Saamay Mall", "icon": Icons.shopping_bag_outlined},
    {"name": "Book Puja", "icon": Icons.local_fire_department_outlined},
  ];

  List<Map<String, dynamic>> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleFocusChange);
    _searchController.addListener(_handleSearchQueryChange);
  }

  void _handleFocusChange() {
    setState(() {
      _showPopup = _searchFocusNode.hasFocus;
      // Get search bar width after build
      if (_searchFocusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final RenderBox? box =
              _searchBarKey.currentContext?.findRenderObject() as RenderBox?;
          if (box != null) {
            setState(() {
              _searchBarWidth = box.size.width;
            });
          }
        });
      }
    });
  }

  void _handleSearchQueryChange() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterSuggestions();
    });
  }

  void _filterSuggestions() {
    if (_searchQuery.isEmpty) {
      _filteredSuggestions = [];
    } else {
      // Filter astrologers based on search query
      _filteredSuggestions = _allAstrologers
          .where(
            (astrologer) => astrologer["name"].toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchQueryChange);
    _searchFocusNode.removeListener(_handleFocusChange);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    _searchFocusNode.unfocus();
    setState(() {
      _showPopup = false;
    });
    // Navigate to search results or appropriate page
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background blur when search is focused
        if (_showPopup)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _searchFocusNode.unfocus();
                setState(() {
                  _showPopup = false;
                });
              },
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(color: Colors.black.withOpacity(0.1)),
              ),
            ),
          ),

        Column(
          children: [
            // Search bar
            Container(
              color: Colors.transparent,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                key: _searchBarKey,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search Astrologers',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // Popup card
            if (_showPopup && _searchBarWidth > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SearchPopupCard(
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  onSuggestionTapped: _handleSuggestionTap,
                  width: _searchBarWidth,
                  searchQuery: _searchQuery,
                  filteredSuggestions: _filteredSuggestions,
                  trendingTopics: _trendingTopics,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
