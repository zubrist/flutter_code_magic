import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/config.dart';
import 'package:google_fonts/google_fonts.dart';

class AshtakootMilanTab extends StatefulWidget {
  final Map<String, dynamic> matchData;
  final Map<String, dynamic>? cachedData;
  final Function(Map<String, dynamic>) onDataCached;

  const AshtakootMilanTab({
    Key? key,
    required this.matchData,
    this.cachedData,
    required this.onDataCached,
  }) : super(key: key);

  @override
  _AshtakootMilanTabState createState() => _AshtakootMilanTabState();
}

class _AshtakootMilanTabState extends State<AshtakootMilanTab> {
  Map<String, dynamic>? resultData;
  bool isLoading = false;

  // Track expanded sections
  Map<String, bool> expandedKoots = {};
  Map<String, bool> expandedDoshas = {
    'manglik': false,
    'nadi': false,
    'bhakoot': false,
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didUpdateWidget(AshtakootMilanTab oldWidget) {
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
      _fetchAshtakootMilan();
    }
  }

  Future<void> _fetchAshtakootMilan() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('$api/indian-api/match-making/ashtakoot-milan');

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
        _showError('Error fetching Ashtakoot Milan data');
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

  // Overall compatibility widget
  Widget _buildOverallCompatibility() {
    if (resultData == null) return SizedBox.shrink();

    final result = resultData!['ashtakoot_milan_result'];
    final pointsObtained = double.parse(result['points_obtained'].toString());
    final maxPoints = double.parse(result['max_ponits'].toString());
    final percentage = (pointsObtained / maxPoints * 100).round();

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
                  Icons.favorite_rounded,
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
                          // Format with one decimal place if not a whole number
                          "${pointsObtained % 1 == 0 ? pointsObtained.toInt() : pointsObtained.toStringAsFixed(1)}/${maxPoints % 1 == 0 ? maxPoints.toInt() : maxPoints.toStringAsFixed(1)}",
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

    // New logic for Manglik compatibility
    final manglikCompatible =
        (manglikP1 && manglikP2) || (!manglikP1 && !manglikP2);

    final nadiDosha =
        resultData!['nadi_dosha'].toString().toLowerCase() == 'true';
    final bhakootDosha =
        resultData!['bhakoot_dosha'].toString().toLowerCase() == 'true';

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

          // Collapsible Dosha items
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildCollapsibleDoshaItem(
                  "manglik",
                  "Manglik Dosha",
                  "Boy: ${manglikP1 ? 'Yes' : 'No'}, Girl: ${manglikP2 ? 'Yes' : 'No'} , ${manglikCompatible ? 'Compatible' : 'Not Compatible'}",
                  hasDosha:
                      !manglikCompatible, // Only considered a problem if they're incompatible
                  description:
                      "Manglik Dosha is related to the influence of Mars (Mangal) in the birth chart. When Mars is placed in certain houses, it is believed to affect marital harmony. In traditional matchmaking, this is considered important for compatibility. Couples are considered compatible if both partners are Manglik or if both are non-Manglik. Incompatibility arises when one partner is Manglik and the other is not.",
                ),
                Divider(height: 8, color: Colors.grey[200]),
                _buildCollapsibleDoshaItem(
                  "nadi",
                  "Nadi Dosha",
                  nadiDosha ? "Present" : "Not Present",
                  hasDosha: nadiDosha,
                  description:
                      "Nadi Dosha is considered one of the most important factors in matchmaking. It relates to the physiological and biological compatibility between partners. When both partners have the same Nadi (pulse), it may lead to health issues and problems related to progeny. Remedial measures are usually recommended when Nadi Dosha is present.",
                ),
                Divider(height: 8, color: Colors.grey[200]),
                _buildCollapsibleDoshaItem(
                  "bhakoot",
                  "Bhakoot Dosha",
                  bhakootDosha ? "Present" : "Not Present",
                  hasDosha: bhakootDosha,
                  description:
                      "Bhakoot Dosha is related to the compatibility of moon signs (Rashi) between partners. It affects the emotional bonding, mutual understanding, and general harmony in the relationship. When present, it may cause misunderstandings and conflicts between partners. Proper remedies can help mitigate its effects.",
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
    bool isExpanded = expandedDoshas[key] ?? false;

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
            padding: EdgeInsets.symmetric(vertical: 12),
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
            padding: EdgeInsets.only(left: 48, right: 0, bottom: 12),
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

  // Koota card
  Widget _buildKootaCard(String key, Map<String, dynamic> koot) {
    // Keep as double instead of rounding to int
    final pointsObtained = double.parse(koot['points_obtained'].toString());
    final maxPoints = double.parse(koot['max_ponits'].toString());
    final percentage = (pointsObtained / maxPoints * 100)
        .round(); // Percentage can still be rounded

    final Color scoreColor = _getPointColor(percentage.toDouble());
    final Color scoreBgColor = _getPointBgColor(percentage.toDouble());
    final IconData scoreIcon = _getScoreIcon(percentage.toDouble());

    bool isExpanded = expandedKoots[key] ?? false;

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
          // Header (clickable)
          InkWell(
            onTap: () {
              setState(() {
                expandedKoots[key] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: isExpanded ? Radius.zero : Radius.circular(16),
              bottomRight: isExpanded ? Radius.zero : Radius.circular(16),
            ),
            child: Container(
              padding: EdgeInsets.all(16),
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
                  Expanded(
                    child: Row(
                      children: [
                        Icon(scoreIcon, color: scoreColor, size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                key.toUpperCase(),
                                style: GoogleFonts.lora(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Area: ${koot['area_of_life']}",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                          // Format with one decimal place if not a whole number
                          "${pointsObtained % 1 == 0 ? pointsObtained.toInt() : pointsObtained.toStringAsFixed(1)}/${maxPoints % 1 == 0 ? maxPoints.toInt() : maxPoints.toStringAsFixed(1)}",
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
                  SizedBox(height: 8),
                  _buildPartnerAttributeRow("Boy", koot['p1']),
                  SizedBox(height: 8),
                  _buildPartnerAttributeRow("Girl", koot['p2']),
                  SizedBox(height: 16),
                  Text(
                    koot['description'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
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
              "Analyzing Ashtakoot Milan...",
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
                _fetchAshtakootMilan();
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

    final ashtakootMilan =
        resultData!['ashtakoot_milan'] as Map<String, dynamic>;

    // Define the specific order for Koota display (from Varna to Nadi)
    final List<String> kootOrder = [
      'varna',
      'vashya',
      'tara',
      'yoni',
      'graha_maitri',
      'gana',
      'bhakoota',
      'nadi',
    ];

    // Filter out only the Koota entries in the specified order
    List<MapEntry<String, dynamic>> orderedKoots = [];
    for (String kootName in kootOrder) {
      if (ashtakootMilan.containsKey(kootName)) {
        orderedKoots.add(MapEntry(kootName, ashtakootMilan[kootName]));
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
              return _buildKootaCard(
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
