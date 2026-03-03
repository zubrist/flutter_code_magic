import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/config.dart';
import 'package:google_fonts/google_fonts.dart';

class NavaPanchamYogaTab extends StatefulWidget {
  final Map<String, dynamic> matchData;
  final Map<String, dynamic>? cachedData;
  final Function(Map<String, dynamic>) onDataCached;

  const NavaPanchamYogaTab({
    Key? key,
    required this.matchData,
    this.cachedData,
    required this.onDataCached,
  }) : super(key: key);

  @override
  _NavaPanchamYogaTabState createState() => _NavaPanchamYogaTabState();
}

class _NavaPanchamYogaTabState extends State<NavaPanchamYogaTab> {
  Map<String, dynamic>? resultData;
  bool isLoading = false;
  Set<String> _expandedYogas = {}; // Track which yoga cards are expanded

  // Theme colors
  Color get primaryColor => Colors.red[900]!;
  Color get secondaryColor => const Color(0xFFF9C702);
  Color get backgroundColor => const Color(0xFFFCF7EF);

  // Add Hindi to English planet name mapping
  final Map<String, String> hindiToEnglishPlanetNames = {
    'रवि': 'Sun',
    'चंद्रमा': 'Moon',
    'मंगल': 'Mars',
    'राहु': 'Rahu',
    'बृहस्पति': 'Jupiter',
    'शनि': 'Saturn',
    'बुध': 'Mercury',
    'केतु': 'Ketu',
    'शुक्र': 'Venus',
    'लग्न': 'Ascendant',
    // Add other planets if needed
    'अरुण': 'Uranus',
    'नेपच्यून': 'Neptune',
    'प्लूटो': 'Pluto',
  };

  // Planet colors for visual distinction
  final Map<String, Color> planetColors = {
    'Sun': Colors.orange.shade600,
    'Moon': Colors.grey.shade500,
    'Mars': Colors.red.shade600,
    'Rahu': Colors.purple.shade700,
    'Jupiter': Colors.yellow.shade700,
    'Saturn': Colors.indigo.shade600,
    'Mercury': Colors.green.shade600,
    'Ketu': Colors.brown.shade600,
    'Venus': Colors.pink.shade400,
    'Uranus': Colors.teal.shade600,
    'Neptune': Colors.blue.shade600,
    'Pluto': Colors.deepPurple.shade800,
    'Ascendant': Colors.amber.shade700,
  };

  // Planet images
  final Map<String, String> planetImages = {
    'Sun':
        'https://divineapi.com/public/api-assets/assets/images/planets/Sun.png',
    'Moon':
        'https://divineapi.com/public/api-assets/assets/images/planets/Moon.png',
    'Mars':
        'https://divineapi.com/public/api-assets/assets/images/planets/Mars.png',
    'Mercury':
        'https://divineapi.com/public/api-assets/assets/images/planets/Mercury.png',
    'Jupiter':
        'https://divineapi.com/public/api-assets/assets/images/planets/Jupiter.png',
    'Venus':
        'https://divineapi.com/public/api-assets/assets/images/planets/Venus.png',
    'Saturn':
        'https://divineapi.com/public/api-assets/assets/images/planets/Saturn.png',
    'Rahu':
        'https://divineapi.com/public/api-assets/assets/images/planets/Rahu.png',
    'Ketu':
        'https://divineapi.com/public/api-assets/assets/images/planets/Ketu.png',
    'Uranus':
        'https://divineapi.com/public/api-assets/assets/images/planets/Uranus.png',
    'Neptune':
        'https://divineapi.com/public/api-assets/assets/images/planets/Neptune.png',
    'Pluto':
        'https://divineapi.com/public/api-assets/assets/images/planets/Pluto.png',
    'Ascendant':
        'https://divineapi.com/public/api-assets/assets/images/planets/Ascendant.png',
  };

  // Helper method to get English planet name
  String _getEnglishPlanetName(String planetName) {
    return hindiToEnglishPlanetNames[planetName] ?? planetName;
  }

  // Helper method to get planet color
  Color _getPlanetColor(String planetName) {
    final englishName = _getEnglishPlanetName(planetName);
    return planetColors[englishName] ?? Colors.grey;
  }

  // Helper method to get planet image
  String? _getPlanetImage(String planetName) {
    final englishName = _getEnglishPlanetName(planetName);
    return planetImages[englishName];
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didUpdateWidget(NavaPanchamYogaTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if we need to update data when widget changes
    if (widget.cachedData != oldWidget.cachedData) {
      _initializeData();
    }
  }

  void _initializeData() {
    if (widget.cachedData != null) {
      // Use cached data if available
      setState(() {
        resultData = widget.cachedData;
        isLoading = false;
      });
    } else {
      // Fetch data if not cached
      _fetchNavaPanchamYoga();
    }
  }

  Future<void> _fetchNavaPanchamYoga() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('$api/indian-api/match-making/nav-pancham-yoga');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(widget.matchData),
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(utf8.decode(response.bodyBytes));

        if (decodedData['success'] == 1 &&
            decodedData['data'] != null &&
            decodedData['data']['nav_pancham_yoga'] != null) {
          final data =
              decodedData['data']['nav_pancham_yoga'] as Map<String, dynamic>;

          setState(() {
            resultData = data;
            isLoading = false;
          });

          // Cache the data in parent
          widget.onDataCached(data);
        } else {
          setState(() {
            isLoading = false;
          });
          _showError('Invalid data format received');
        }
      } else {
        setState(() => isLoading = false);
        _showError('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Network error occurred: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // Toggle expanded state for a yoga card
  void _toggleExpanded(String planetId) {
    setState(() {
      if (_expandedYogas.contains(planetId)) {
        _expandedYogas.remove(planetId);
      } else {
        _expandedYogas.add(planetId);
      }
    });
  }

  Widget _buildYogaPlanetTile(String targetPlanet, String position) {
    // Split the position string to get the houses
    final List<String> houses = position.split('/');

    // Get English name for image and color lookup
    final String englishPlanetName = _getEnglishPlanetName(targetPlanet);

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getPlanetColor(targetPlanet).withOpacity(0.15),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Image.network(
              _getPlanetImage(targetPlanet) ?? '',
              width: 36,
              height: 36,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.public,
                size: 24,
                color: _getPlanetColor(targetPlanet),
              ),
            ),
          ),
        ),
        title: Text(
          targetPlanet,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            position,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYogaSection(String planet, Map<String, dynamic> yogaData) {
    final String planetId = planet;
    final bool isExpanded = _expandedYogas.contains(planetId);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          colorScheme: ColorScheme.light(primary: primaryColor),
        ),
        child: ExpansionTile(
          key: Key(planetId), // Important for expansion state
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            _toggleExpanded(planetId);
          },
          childrenPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 8,
          ),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getPlanetColor(planet).withOpacity(0.15),
            ),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  _getPlanetImage(planet) ?? '',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.public,
                    size: 30,
                    color: _getPlanetColor(planet),
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            planet,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: primaryColor,
            ),
          ),
          subtitle: Text(
            '${yogaData.length} planetary positions',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.explore,
                          size: 18,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Planetary Combinations',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: yogaData.length,
                    itemBuilder: (context, index) {
                      final targetPlanet = yogaData.keys.elementAt(index);
                      final position = yogaData[targetPlanet];
                      return _buildYogaPlanetTile(targetPlanet, position);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red[900]!),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading NavaPancham Yoga data...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (resultData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade400),
            const SizedBox(height: 20),
            Text(
              'No NavaPancham Yoga data available',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _fetchNavaPanchamYoga();
              },
              icon: const Icon(Icons.refresh, size: 20),
              label: Text(
                'Retry',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final planets = resultData!.keys.toList();

    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: planets.length,
              itemBuilder: (context, index) {
                final planet = planets[index];
                return _buildYogaSection(
                  planet,
                  resultData![planet] as Map<String, dynamic>,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
