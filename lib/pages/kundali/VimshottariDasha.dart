import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/config.dart';
import 'package:google_fonts/google_fonts.dart';

class VimshottariDashaTab extends StatefulWidget {
  final Map<String, dynamic> matchData;
  final Map<String, dynamic>? cachedData;
  final Function(Map<String, dynamic>) onDataCached;

  const VimshottariDashaTab({
    Key? key,
    required this.matchData,
    this.cachedData,
    required this.onDataCached,
  }) : super(key: key);

  @override
  _VimshottariDashaTabState createState() => _VimshottariDashaTabState();
}

class _VimshottariDashaTabState extends State<VimshottariDashaTab> {
  Map<String, dynamic>? resultData;
  bool isLoading = false;
  int _selectedPersonIndex = 0; // 0 for boy (p1), 1 for girl (p2)
  Set<String> _expandedMahaDashas = {}; // Track which mahadashas are expanded

  // Theme colors
  Color get primaryColor => Colors.red[900]!;
  Color get secondaryColor => const Color(0xFFF9C702);
  Color get backgroundColor => const Color(0xFFFCF7EF);
  Color get boyColor => Colors.blue.shade700;
  Color get girlColor => Colors.pink.shade400;

  // Get theme color based on selected person for the switcher
  Color get switcherColor => _selectedPersonIndex == 0 ? boyColor : girlColor;
  // Use red as the primary theme color for all other UI elements
  Color get themeColor => primaryColor;

  // Translation map for planet names (Hindi to English)
  final Map<String, String> planetTranslation = {
    'मंगल': 'Mars',
    'राहु': 'Rahu',
    'बृहस्पति': 'Jupiter',
    'शनि': 'Saturn',
    'बुध': 'Mercury',
    'केतु': 'Ketu',
    'शुक्र': 'Venus',
    'रवि': 'Sun',
    'चंद्रमा': 'Moon',
    // Include English names to map to themselves
    'Mars': 'Mars',
    'Rahu': 'Rahu',
    'Jupiter': 'Jupiter',
    'Saturn': 'Saturn',
    'Mercury': 'Mercury',
    'Ketu': 'Ketu',
    'Venus': 'Venus',
    'Sun': 'Sun',
    'Moon': 'Moon',
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
  };

  // Helper method to get the English planet name
  String getEnglishPlanetName(String planetName) {
    return planetTranslation[planetName] ?? planetName;
  }

  // Helper method to get planet color
  Color getPlanetColor(String planetName) {
    String englishName = getEnglishPlanetName(planetName);
    return planetColors[englishName] ?? Colors.grey;
  }

  // Helper method to get planet image
  String getPlanetImage(String planetName) {
    String englishName = getEnglishPlanetName(planetName);
    return planetImages[englishName] ?? '';
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didUpdateWidget(VimshottariDashaTab oldWidget) {
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
      _fetchVimshottariDasha();
    }
  }

  Future<void> _fetchVimshottariDasha() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('$api/indian-api/match-making/vimshottari-dasha');

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
        final data = decodedData['data'] as Map<String, dynamic>;

        setState(() {
          resultData = data;
          isLoading = false;
        });

        // Cache the data in parent
        widget.onDataCached(data);
      } else {
        setState(() => isLoading = false);
        _showError('Error fetching Vimshottari Dasha data');
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
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message, style: GoogleFonts.poppins())),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(12),
      ),
    );
  }

  // Toggle expanded state for a mahadasha
  void _toggleExpanded(String planetId) {
    setState(() {
      if (_expandedMahaDashas.contains(planetId)) {
        _expandedMahaDashas.remove(planetId);
      } else {
        _expandedMahaDashas.add(planetId);
      }
    });
  }

  Widget _buildPersonSelector() {
    final boyName = widget.matchData['p1_full_name'] as String;
    final girlName = widget.matchData['p2_full_name'] as String;

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedPersonIndex = 0;
                _expandedMahaDashas
                    .clear(); // Clear expanded state when switching
              }),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedPersonIndex == 0
                      ? boyColor.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      boyName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedPersonIndex == 0
                            ? boyColor
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Colors.grey.shade200,
            indent: 12,
            endIndent: 12,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedPersonIndex = 1;
                _expandedMahaDashas
                    .clear(); // Clear expanded state when switching
              }),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedPersonIndex == 1
                      ? girlColor.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      girlName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedPersonIndex == 1
                            ? girlColor
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAntarDashaRow(String planet, Map<String, dynamic> antarDasha) {
    final bool isRunning = antarDasha['start_time'] != '--' &&
        antarDasha['end_time'] != '--' &&
        _isCurrentlyRunning(antarDasha['start_time'], antarDasha['end_time']);

    return Card(
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRunning ? themeColor : Colors.grey.shade200,
          width: isRunning ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: getPlanetColor(planet).withOpacity(0.15),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Image.network(
              getPlanetImage(planet),
              width: 36,
              height: 36,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.public, size: 24, color: getPlanetColor(planet)),
            ),
          ),
        ),
        title: Text(
          '$planet Antar Dasha',
          style: GoogleFonts.poppins(
            fontWeight: isRunning ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
            color: isRunning ? themeColor : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start: ${antarDasha['start_time'] != '--' ? antarDasha['start_time'] : 'N/A'}',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            Text(
              'End: ${antarDasha['end_time'] != '--' ? antarDasha['end_time'] : 'N/A'}',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ],
        ),
        trailing: isRunning
            ? Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Current',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  // Helper to check if a date range includes the current date
  bool _isCurrentlyRunning(String startDate, String endDate) {
    // Basic date parsing for common formats (YYYY-MM-DD)
    try {
      if (startDate == '--' || endDate == '--') return false;

      final DateTime start = DateTime.parse(startDate);
      final DateTime end = DateTime.parse(endDate);
      final DateTime now = DateTime.now();

      return now.isAfter(start) && now.isBefore(end);
    } catch (e) {
      return false; // If date parsing fails
    }
  }

  Widget _buildMahaDashaSection(String planet, Map<String, dynamic> mahaDasha) {
    final String planetId = '${planet}_${_selectedPersonIndex}';
    final bool isExpanded = _expandedMahaDashas.contains(planetId);
    final bool isRunning = _isCurrentlyRunning(
      mahaDasha['start_date'],
      mahaDasha['end_date'],
    );

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: isRunning ? Border.all(color: primaryColor, width: 1.5) : null,
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
          childrenPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
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
              color: getPlanetColor(planet).withOpacity(0.15),
            ),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  getPlanetImage(planet),
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.public,
                    size: 30,
                    color: getPlanetColor(planet),
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            '$planet Maha Dasha',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: isRunning ? primaryColor : Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${mahaDasha['start_date']} - ${mahaDasha['end_date']}',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              if (isRunning)
                Container(
                  margin: EdgeInsets.only(top: 6),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Running Now',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.only(
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
                          Icons.schedule,
                          size: 18,
                          color: Colors.grey.shade700,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Antar Dasha Periods',
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
                  SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 12),
                    itemCount:
                        (mahaDasha['antar_dasha'] as Map<String, dynamic>)
                            .length,
                    itemBuilder: (context, index) {
                      final planet =
                          (mahaDasha['antar_dasha'] as Map<String, dynamic>)
                              .keys
                              .elementAt(index);
                      final antarDasha = (mahaDasha['antar_dasha']
                          as Map<String, dynamic>)[planet];
                      return _buildAntarDashaRow(planet, antarDasha);
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

  Widget _buildPersonDasha() {
    // Get the correct person's data
    final personData = _selectedPersonIndex == 0
        ? resultData!['p1'] as Map<String, dynamic>
        : resultData!['p2'] as Map<String, dynamic>;

    final mahaDashaMap = personData['maha_dasha'] as Map<String, dynamic>;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: backgroundColor,
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  spreadRadius: 0,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Maha Dasha Periods',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                /*
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (_expandedMahaDashas.isEmpty) {
                        // Expand all
                        _expandedMahaDashas = mahaDashaMap.keys
                            .map((p) => '${p}_$_selectedPersonIndex')
                            .toSet();
                      } else {
                        // Collapse all
                        _expandedMahaDashas.clear();
                      }
                    });
                  },
                  icon: Icon(
                    _expandedMahaDashas.isEmpty
                        ? Icons.unfold_more
                        : Icons.unfold_less,
                    size: 20,
                    color: primaryColor,
                  ),
                  label: Text(
                    _expandedMahaDashas.isEmpty ? 'Expand All' : 'Collapse All',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),*/
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: mahaDashaMap.length,
              itemBuilder: (context, index) {
                final planet = mahaDashaMap.keys.elementAt(index);
                return _buildMahaDashaSection(planet, mahaDashaMap[planet]);
              },
            ),
          ),
        ],
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
            SizedBox(height: 20),
            Text(
              'Loading Vimshottari Dasha data...',
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
            SizedBox(height: 20),
            Text(
              'No data available',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _fetchVimshottariDasha();
              },
              icon: Icon(Icons.refresh, size: 20),
              label: Text(
                'Retry',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          _buildPersonSelector(),
          Expanded(child: _buildPersonDasha()),
        ],
      ),
    );
  }
}
