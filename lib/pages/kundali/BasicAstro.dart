import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:saamay/pages/config.dart';

class BasicAstroTab extends StatefulWidget {
  final Map<String, dynamic> matchData;
  final Map<String, dynamic>? cachedData;
  final Function(Map<String, dynamic>) onDataCached;

  const BasicAstroTab({
    Key? key,
    required this.matchData,
    this.cachedData,
    required this.onDataCached,
  }) : super(key: key);

  @override
  _BasicAstroTabState createState() => _BasicAstroTabState();
}

class _BasicAstroTabState extends State<BasicAstroTab> {
  Map<String, dynamic>? resultData;
  bool isLoading = false;
  String? error;

  // Custom gradient for headers
  final Gradient _customGradient = const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF89216B), Color(0xFFDA4453), // #AE0074
    ],
  );

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didUpdateWidget(BasicAstroTab oldWidget) {
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
        error = null;
      });
    } else {
      // Fetch data if not cached
      _fetchBasicAstroDetails();
    }
  }

  Future<void> _fetchBasicAstroDetails() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final url = Uri.parse('$api/indian-api/match-making/basic-astro-details');

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
        final data = json.decode(utf8.decode(response.bodyBytes))['data'];
        setState(() {
          resultData = data;
          isLoading = false;
        });

        // Cache the data in parent
        widget.onDataCached(data);
      } else {
        setState(() {
          isLoading = false;
          error =
              'Failed to fetch basic astro details. Status code: ${response.statusCode}';
        });
        _showErrorSnackBar('Error fetching details');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        error = 'An error occurred: $e';
      });
      _showErrorSnackBar('Network error occurred');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text(message, style: GoogleFonts.poppins()),
              ],
            ),
            backgroundColor: Colors.red[900],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red[900]!),
        ),
      );
    }

    if (error != null || resultData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[300], size: 48),
            SizedBox(height: 16),
            Text(
              error ?? 'No data available',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[900],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _fetchBasicAstroDetails();
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Boy's Section Title
          Container(
            margin: EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              children: [
                Icon(Icons.male, color: Colors.red[900], size: 24),
                SizedBox(width: 8),
                Text(
                  "Boy's Details",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                ),
              ],
            ),
          ),
          // Boy's Details Card
          _buildPersonDetailsWithNewTableStyle(resultData!['p1']),

          SizedBox(height: 16),

          // Girl's Section Title
          Container(
            margin: EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              children: [
                Icon(Icons.female, color: Colors.red[900], size: 24),
                SizedBox(width: 8),
                Text(
                  "Girl's Details",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                ),
              ],
            ),
          ),
          // Girl's Details Card
          _buildPersonDetailsWithNewTableStyle(resultData!['p2']),
        ],
      ),
    );
  }

  Widget _buildPersonDetailsWithNewTableStyle(Map<String, dynamic> details) {
    // Group the data for better organization
    final Map<String, dynamic> personalInfo = {};
    final Map<String, dynamic> astroInfo = {};
    final Map<String, dynamic> otherInfo = {};

    // Personal information fields
    final personalFields = [
      'full_name',
      'gender',
      'place',
      'day',
      'month',
      'year',
      'hour',
      'minute',
      'timezone',
    ];

    // Astrological information fields
    final astroFields = [
      'sunrise',
      'sunset',
      'tithi',
      'paksha',
      'sunsign',
      'moonsign',
      'rashi_akshar',
      'nakshatra',
      'vaar',
      'yoga',
      'karana',
    ];

    // Sort data into categories
    details.forEach((key, value) {
      if (personalFields.contains(key)) {
        personalInfo[key] = value;
      } else if (astroFields.contains(key)) {
        astroInfo[key] = value;
      } else {
        otherInfo[key] = value;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Personal Information Section
        _buildSectionHeader('Personal Information', Colors.red[900]!),
        _buildDataSection({
          'Full Name': details['full_name'],
          'Gender': details['gender'],
          'Place': details['place'],
          'Birth Date':
              '${details['day']}/${details['month']}/${details['year']}',
          'Birth Time': '${details['hour']}:${details['minute']}',
          'Timezone': details['timezone'] ?? '5.5',
        }),
        SizedBox(height: 24),

        // Astrological Information Section
        _buildSectionHeader('Astrological Information', Colors.red[800]!),
        _buildDataSection({
          'Sunrise': details['sunrise'],
          'Sunset': details['sunset'],
          'Tithi': details['tithi'],
          'Paksha': details['paksha'],
          'Sun Sign': details['sunsign'],
          'Moon Sign': details['moonsign'],
          'Rashi Akshar': details['rashi_akshar'],
          'Nakshatra': details['nakshatra'],
          'Vaar': details['vaar'],
          'Yoga': details['yoga'],
          'Karana': details['karana'],
        }),
        SizedBox(height: 24),

        // Additional details section
        _buildSectionHeader('Additional Details', Colors.red[700]!),
        _buildDataSection({
          'Tatva': details['tatva'],
          'Varna': details['varna'],
          'Vashya': details['vashya'],
          'Yoni': details['yoni'],
          'Gana': details['gana'],
          'Nadi': details['nadi'],
          'Paya Type': details['paya'] != null ? details['paya']['type'] : null,
          'Paya Result':
              details['paya'] != null ? details['paya']['result'] : null,
        }),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: _customGradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDataSection(Map<String, dynamic> data) {
    final List<MapEntry<String, dynamic>> entries = data.entries.toList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          final key = entry.key;
          final value = entry.value;

          final formattedValue = value == null ? 'N/A' : value.toString();

          return Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: index % 2 == 0 ? Colors.white : Colors.grey.shade100,
              border: index < entries.length - 1
                  ? Border(bottom: BorderSide(color: Colors.grey.shade200))
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    key,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.red[900],
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Text(
                    formattedValue,
                    style: GoogleFonts.poppins(color: Colors.black87),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
