import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/config.dart';
//import 'package:dashboard_apps/core/theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class ManglikDoshaTab extends StatefulWidget {
  final Map<String, dynamic> matchData;
  final Map<String, dynamic>? cachedData;
  final Function(Map<String, dynamic>) onDataCached;

  const ManglikDoshaTab({
    Key? key,
    required this.matchData,
    this.cachedData,
    required this.onDataCached,
  }) : super(key: key);

  @override
  _ManglikDoshaTabState createState() => _ManglikDoshaTabState();
}

class _ManglikDoshaTabState extends State<ManglikDoshaTab> {
  Map<String, dynamic>? resultData;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didUpdateWidget(ManglikDoshaTab oldWidget) {
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
      _fetchManglikDosha();
    }
  }

  Future<void> _fetchManglikDosha() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('$api/indian-api/match-making/manglik-dosha');

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
        _showError('Error fetching Manglik Dosha data');
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

  Color _getStatusColor(bool isManglik) {
    return isManglik ? Colors.red : Colors.green;
  }

  Color _getStatusLightColor(bool isManglik) {
    return isManglik ? Colors.red.shade50 : Colors.green.shade50;
  }

  Color _getCardGradientColor(bool isBlue) {
    return isBlue
        ? const Color.fromARGB(255, 47, 33, 243)
        : const Color.fromARGB(255, 233, 30, 30);
  }

  Widget _buildRemedyList(List<dynamic> remedies) {
    if (remedies.isEmpty) {
      return Text(
        'No remedies needed',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: Colors.black54,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Remedies:',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        ...remedies.map(
          (remedy) => Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 8, color: Colors.red.shade300),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    remedy.toString(),
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
        ),
      ],
    );
  }

  Widget _buildPersonManglik(
    String title,
    bool isMale,
    Map<String, dynamic> personData,
  ) {
    final bool isManglik = personData['manglik_dosha'] as bool;
    final Color statusColor = _getStatusColor(isManglik);
    final Color statusLightColor = _getStatusLightColor(isManglik);
    final Color cardColor = isMale ? Colors.lightBlueAccent : Colors.pink;

    return Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.15),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isMale ? Icons.male_rounded : Icons.female_rounded,
                  color: cardColor,
                  size: 22,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.lora(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: statusLightColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isSmallScreen = constraints.maxWidth < 300;

                      // On very small screens, stack the icon and content vertically
                      if (isSmallScreen) {
                        return Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withOpacity(0.2),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isManglik
                                    ? Icons.warning_rounded
                                    : Icons.check_circle_rounded,
                                color: statusColor,
                                size: 32,
                              ),
                            ),
                            SizedBox(height: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  isManglik ? 'Manglik' : 'Non-Manglik',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  isManglik
                                      ? 'Manglik dosha is present'
                                      : 'No manglik dosha detected',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      // Default layout for larger screens
                      return Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Icon(
                              isManglik
                                  ? Icons.warning_rounded
                                  : Icons.check_circle_rounded,
                              color: statusColor,
                              size: 32,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isManglik ? 'Manglik' : 'Non-Manglik',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  isManglik
                                      ? 'Manglik dosha is present in the horoscope'
                                      : 'No manglik dosha detected in the horoscope',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                SizedBox(height: 20),

                // Details
                _buildDetailRow('Strength:', personData['strength']),
                SizedBox(height: 12),

                // Percentage Indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Manglik Percentage:',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${personData['percentage']}%',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value:
                            (personData['percentage'] as num).toDouble() / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Remedies
                _buildRemedyList(personData['remedies'] as List<dynamic>),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchAnalysis() {
    if (resultData == null) return SizedBox.shrink();

    final content = resultData!['content'] as String;
    final p1Manglik = resultData!['p1']['manglik_dosha'] as bool;
    final p2Manglik = resultData!['p2']['manglik_dosha'] as bool;

    // Updated compatibility logic
    // They are compatible if both are manglik or both are non-manglik
    final bool isCompatible = p1Manglik == p2Manglik;

    return Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isCompatible ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCompatible
                      ? Icons.favorite_rounded
                      : Icons.warning_amber_rounded,
                  color: isCompatible ? Colors.green : Colors.orange,
                  size: 22,
                ),
                SizedBox(width: 12),
                Text(
                  "Compatibility Analysis",
                  style: GoogleFonts.lora(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Compatibility illustration - responsive sizing
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Adjust size and spacing based on available width
                    final bool isSmallScreen = constraints.maxWidth < 400;
                    final double circleSize = isSmallScreen ? 45.0 : 60.0;
                    final double lineWidth = isSmallScreen ? 50.0 : 80.0;
                    final double iconSize = isSmallScreen ? 24.0 : 32.0;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildProfileCircle(
                          true,
                          p1Manglik,
                          circleSize,
                          iconSize,
                        ),
                        _buildConnectionLine(isCompatible, lineWidth),
                        _buildProfileCircle(
                          false,
                          p2Manglik,
                          circleSize,
                          iconSize,
                        ),
                      ],
                    );
                  },
                ),

                SizedBox(height: 24),

                // Recommendation tag
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCompatible
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isCompatible ? "Recommended Match" : "Not Recommended",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCompatible
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Analysis content
                Text(
                  content,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCircle(
    bool isMale,
    bool isManglik,
    double size,
    double iconSize,
  ) {
    final Color borderColor = isManglik ? Colors.red : Colors.green;
    final Color bgColor = isMale ? Colors.blue.shade50 : Colors.pink.shade50;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Center(
        child: Icon(
          isMale ? Icons.male_rounded : Icons.female_rounded,
          color: isMale ? Colors.blue : Colors.pink,
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildConnectionLine(bool isCompatible, double width) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: isCompatible ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      margin: EdgeInsets.symmetric(horizontal: 8),
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
              "Analyzing Manglik Dosha...",
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
              "No Manglik Dosha data available",
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
                _fetchManglikDosha();
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

    return Container(
      // Content should be responsive and adaptable to small screens
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: 16),

            // Compatibility analysis section
            _buildMatchAnalysis(),

            // Responsive layout for person cards (row on large screens, column on small screens)
            LayoutBuilder(
              builder: (context, constraints) {
                // Use column layout if width is less than 600px
                final bool useColumnLayout = constraints.maxWidth < 600;

                if (useColumnLayout) {
                  return Column(
                    children: [
                      // Boy's analysis
                      _buildPersonManglik(
                        widget.matchData['p1_full_name'],
                        true, // is male
                        resultData!['p1'] as Map<String, dynamic>,
                      ),

                      // Girl's analysis
                      _buildPersonManglik(
                        widget.matchData['p2_full_name'],
                        false, // is female
                        resultData!['p2'] as Map<String, dynamic>,
                      ),
                    ],
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Boy's analysis
                      Expanded(
                        child: _buildPersonManglik(
                          widget.matchData['p1_full_name'],
                          true, // is male
                          resultData!['p1'] as Map<String, dynamic>,
                        ),
                      ),

                      // Girl's analysis
                      Expanded(
                        child: _buildPersonManglik(
                          widget.matchData['p2_full_name'],
                          false, // is female
                          resultData!['p2'] as Map<String, dynamic>,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
