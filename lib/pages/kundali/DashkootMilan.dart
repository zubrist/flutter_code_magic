import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/config.dart';
//import 'package:dashboard_apps/core/theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class DashakootMilanTab extends StatefulWidget {
  final Map<String, dynamic> matchData;
  final Map<String, dynamic>? cachedData;
  final Function(Map<String, dynamic>) onDataCached;

  const DashakootMilanTab({
    Key? key,
    required this.matchData,
    this.cachedData,
    required this.onDataCached,
  }) : super(key: key);

  @override
  _DashakootMilanTabState createState() => _DashakootMilanTabState();
}

class _DashakootMilanTabState extends State<DashakootMilanTab> {
  Map<String, dynamic>? resultData;
  bool isLoading = false;

  // Track expanded sections
  Map<String, bool> expandedKoots = {};
  Map<String, bool> expandedDoshas = {'manglik': false, 'rajju': false};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didUpdateWidget(DashakootMilanTab oldWidget) {
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
      _fetchDashakootMilan();
    }
  }

  Future<void> _fetchDashakootMilan() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('$api/indian-api/match-making/dashakoot-milan');

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
        _showError('Error fetching Dashakoot Milan data');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Network error occurred');
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
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Helper functions for color and icons
  Color _getPointColor(double percentage) {
    if (percentage >= 75) {
      return Colors.green[700]!;
    } else if (percentage >= 50) {
      return Colors.orange[700]!;
    } else {
      return Colors.red[700]!;
    }
  }

  Color _getPointBgColor(double percentage) {
    if (percentage >= 75) {
      return Colors.green[100]!;
    } else if (percentage >= 50) {
      return Colors.orange[100]!;
    } else {
      return Colors.red[100]!;
    }
  }

  IconData _getScoreIcon(double percentage) {
    if (percentage >= 75) {
      return Icons.favorite;
    } else if (percentage >= 50) {
      return Icons.favorite_border;
    } else {
      return Icons.favorite_border;
    }
  }

  // Updated method to handle both English and Hindi result text
  String _getResultText(String result) {
    // Convert to lowercase for case-insensitive comparison
    String lowerResult = result.toLowerCase();

    // Check for both English and Hindi result values
    if (lowerResult == 'good' || lowerResult == 'अच्छा') {
      return result; // Return original text to preserve case and language
    } else if (lowerResult == 'satisfactory' || lowerResult == 'संतोषजनक') {
      return result;
    } else if (lowerResult == 'not satisfactory' ||
        lowerResult == 'संतोषजनक नहीं' ||
        lowerResult == 'संतोषजनक नहीं') {
      return result;
    } else {
      return result;
    }
  }

  // New method to check result category for color coding
  bool _isGoodResult(String result) {
    String lowerResult = result.toLowerCase();
    return lowerResult == 'good' || lowerResult == 'अच्छा';
  }

  bool _isSatisfactoryResult(String result) {
    String lowerResult = result.toLowerCase();
    return lowerResult == 'satisfactory' || lowerResult == 'संतोषजनक';
  }

  bool _isNotSatisfactoryResult(String result) {
    String lowerResult = result.toLowerCase();
    return lowerResult == 'not satisfactory' ||
        lowerResult == 'संतोषजनक नहीं' ||
        lowerResult.contains('नहीं');
  }

  // Overall compatibility widget
  Widget _buildOverallCompatibility() {
    if (resultData == null) return SizedBox.shrink();

    final result = resultData!['dashakoot_milan_result'];
    // Use double.parse to handle decimal values without rounding
    final pointsObtained = double.parse(result['points_obtained'].toString());
    final maxPoints = double.parse(result['max_ponits'].toString());
    final percentage = (pointsObtained / maxPoints * 100).round();
    final isCompatible =
        result['is_compatible'].toString().toLowerCase() == 'true';

    final Color scoreColor = _getPointColor(percentage.toDouble());
    final Color scoreBgColor = _getPointBgColor(percentage.toDouble());

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 211, 19, 57).withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCompatible ? Icons.favorite_rounded : Icons.favorite_border,
                  color: Color.fromARGB(255, 211, 19, 57),
                ),
                SizedBox(width: 12),
                Text(
                  "Overall Compatibility",
                  style: GoogleFonts.lora(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Score Card with left score and right text
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left side: Score indicator
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scoreBgColor.withOpacity(0.2),
                    border: Border.all(color: scoreColor, width: 3),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$percentage%",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        Text(
                          // Format to show one decimal place if it's a decimal, otherwise show as integer
                          "${pointsObtained % 1 == 0 ? pointsObtained.toInt() : pointsObtained}/${maxPoints % 1 == 0 ? maxPoints.toInt() : maxPoints}",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 16),

                // Right side: Description
                Expanded(
                  child: Text(
                    result['content'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dosha analysis section
  Widget _buildDoshaAnalysis() {
    if (resultData == null) return SizedBox.shrink();

    final manglikDosha = resultData!['manglik_dosha'] as Map<String, dynamic>;
    final manglikP1 = manglikDosha['p1'].toString().toLowerCase() == 'true';
    final manglikP2 = manglikDosha['p2'].toString().toLowerCase() == 'true';

    // New manglik compatibility logic
    final bool manglikCompatible =
        (manglikP1 && manglikP2) || (!manglikP1 && !manglikP2);

    final rajjuDosha =
        resultData!['rajju_dosha'].toString().toLowerCase() == 'true';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (not clickable)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
                SizedBox(width: 12),
                Text(
                  "Dosha Analysis",
                  style: GoogleFonts.lora(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Dosha list items
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildCollapsibleDoshaItem(
                  "manglik",
                  "Manglik Dosha",
                  "Boy: ${manglikP1 ? 'Yes' : 'No'}, Girl: ${manglikP2 ? 'Yes' : 'No'}, ${manglikCompatible ? 'Compatible' : 'Not Compatible'}",
                  hasDosha:
                      !manglikCompatible, // Only show warning if not compatible
                  description:
                      "Manglik Dosha is related to the influence of Mars (Mangal) in the birth chart. When Mars is placed in certain houses, it is believed to affect marital harmony. Compatibility is achieved when both partners either have or don't have Manglik Dosha. Incompatibility occurs when only one partner has it.",
                ),
                Divider(height: 8, color: Colors.grey[200]),
                _buildCollapsibleDoshaItem(
                  "rajju",
                  "Rajju Dosha",
                  rajjuDosha ? "Present" : "Not Present",
                  hasDosha: rajjuDosha,
                  description:
                      "Rajju Dosha occurs when the bride and groom belong to the same Rajju (rope) of the five classified in Vedic astrology. It is believed to affect longevity and harmony in marriage. Remedial measures may be required if Rajju Dosha is present.",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Collapsible Dosha item
  Widget _buildCollapsibleDoshaItem(
    String key,
    String title,
    String value, {
    required bool hasDosha,
    required String description,
  }) {
    bool isExpanded =
        expandedDoshas[key] ?? false; // Using the dedicated map for doshas

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              expandedDoshas[key] = !isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasDosha ? Colors.red[50] : Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasDosha ? Icons.warning_amber_rounded : Icons.check_circle,
                    color: hasDosha ? Colors.red[700] : Colors.green[700],
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: hasDosha ? Colors.red[50] : Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          value,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                hasDosha ? Colors.red[700] : Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: EdgeInsets.only(left: 48, right: 0, bottom: 8, top: 8),
            child: Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  // Updated Koot card with expandable content to handle Hindi text
  Widget _buildKootCard(String title, Map<String, dynamic> koot) {
    // Use double.parse to handle decimal values without rounding
    final pointsObtained = double.parse(koot['points_obtained'].toString());
    final maxPoints = double.parse(koot['max_ponits'].toString());
    // Only round the percentage for display purposes
    final percentage = (pointsObtained / maxPoints * 100).round();
    final result = koot['result'] as String;

    // Determine color based on result using the new helper methods
    Color scoreColor;
    Color scoreBgColor;
    IconData scoreIcon;

    if (_isGoodResult(result)) {
      scoreColor = Colors.green[700]!;
      scoreBgColor = Colors.green[100]!;
      scoreIcon = Icons.favorite;
    } else if (_isSatisfactoryResult(result)) {
      scoreColor = Colors.orange[700]!;
      scoreBgColor = Colors.orange[100]!;
      scoreIcon = Icons.favorite_border;
    } else {
      scoreColor = Colors.red[700]!;
      scoreBgColor = Colors.red[100]!;
      scoreIcon = Icons.favorite_border;
    }

    bool isExpanded = expandedKoots[title] ?? false;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (clickable) - Only showing title and score
          InkWell(
            onTap: () {
              setState(() {
                expandedKoots[title] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: isExpanded ? Radius.zero : Radius.circular(16),
              bottomRight: isExpanded ? Radius.zero : Radius.circular(16),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: scoreBgColor.withOpacity(0.5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: isExpanded ? Radius.zero : Radius.circular(16),
                  bottomRight: isExpanded ? Radius.zero : Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(scoreIcon, color: scoreColor, size: 22),
                      SizedBox(width: 12),
                      Text(
                        title.toUpperCase(),
                        style: GoogleFonts.lora(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Text(
                          // Format to show as decimal if it has decimal places, otherwise as integer
                          "${pointsObtained % 1 == 0 ? pointsObtained.toInt() : pointsObtained}/${maxPoints % 1 == 0 ? maxPoints.toInt() : maxPoints}",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (isExpanded)
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Area of Life section (moved from header to expanded content)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Area of Life",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          koot['area_of_life'],
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Partner attributes
                  _buildPartnerAttributeRow("Boy", koot['p1']),
                  SizedBox(height: 8),
                  _buildPartnerAttributeRow("Girl", koot['p2']),
                  SizedBox(height: 16),

                  // Result indicator with updated color determination
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isGoodResult(result)
                          ? Colors.green[50]
                          : _isSatisfactoryResult(result)
                              ? Colors.orange[50]
                              : Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Result: ${_getResultText(result)}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _isGoodResult(result)
                            ? Colors.green[700]
                            : _isSatisfactoryResult(result)
                                ? Colors.orange[700]
                                : Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Partner attribute row
  Widget _buildPartnerAttributeRow(String partner, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: partner == "Boy" ? Colors.blue[50] : Colors.pink[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                partner == "Boy" ? Icons.male : Icons.female,
                size: 14,
                color: partner == "Boy" ? Colors.blue[700] : Colors.pink[700],
              ),
              SizedBox(width: 4),
              Text(
                partner,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: partner == "Boy" ? Colors.blue[700] : Colors.pink[700],
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
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
            SizedBox(height: 16),
            Text(
              "Analyzing Dashakoot Milan...",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
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
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            SizedBox(height: 16),
            Text(
              "No compatibility data available",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Please try again later",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _fetchDashakootMilan();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    final dashakootMilan =
        resultData!['dashakoot_milan'] as Map<String, dynamic>;

    // Define a specific order for Koot display
    final List<String> kootOrder = [
      'dina',
      'gana',
      'yoni',
      'rashi',
      'rajju',
      'rasyadhipati',
      'vedha',
      'vashya',
      'mahendra',
      'streedargha',
    ];

    // Filter out only the Koota entries in the specified order
    List<MapEntry<String, dynamic>> orderedKoots = [];
    for (String kootName in kootOrder) {
      if (dashakootMilan.containsKey(kootName)) {
        orderedKoots.add(MapEntry(kootName, dashakootMilan[kootName]));
      }
    }

    return Container(
      color: Color(0xFFFCF7EF),
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: 16),
            _buildOverallCompatibility(),
            _buildDoshaAnalysis(),
            ...orderedKoots.map((entry) {
              return _buildKootCard(
                entry.key,
                entry.value as Map<String, dynamic>,
              );
            }).toList(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
