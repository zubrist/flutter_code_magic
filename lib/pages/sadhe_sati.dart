import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:saamay/pages/config.dart';
import 'package:google_fonts/google_fonts.dart';

class SadheSati extends StatefulWidget {
  final Map<String, dynamic> userInput;

  const SadheSati({Key? key, required this.userInput}) : super(key: key);

  @override
  _SadheSatiState createState() => _SadheSatiState();
}

class _SadheSatiState extends State<SadheSati> {
  bool isLoading = true;
  String? error;
  Map<String, dynamic>? sadheSatiData;
  bool _debugMode = true; // Set to true to see debug info

  @override
  void initState() {
    super.initState();
    _fetchSadheSatiData();
  }

  Future<void> _fetchSadheSatiData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final url = Uri.parse('$api/indian-api/kundali-api/sadhe-sati');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(widget.userInput),
      );

      // Debug API response
      if (_debugMode) {
        //print("API Response Status: ${response.statusCode}");
        //print("API Response Body (first 1000 chars): ${response.body.substring(0, response.body.length > 1000 ? 1000 : response.body.length)}...");
      }

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        if (jsonData['success'] == 1) {
          setState(() {
            sadheSatiData = jsonData['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            error = 'Failed to fetch Sadhesati data.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error =
              'Failed to fetch Sadhesati data. Status code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'An error occurred: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return _buildLoadingIndicator();
    } else if (error != null) {
      return _buildErrorWidget();
    } else if (sadheSatiData != null) {
      return _buildSadheSatiContent();
    } else {
      return _buildNoDataWidget();
    }
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.red[900]),
          SizedBox(height: 16),
          Text(
            'Loading Sadhesati analysis...',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.red[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 48),
            SizedBox(height: 16),
            Text(
              'Error',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.red[900],
              ),
            ),
            SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
            SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Color(0xFFF9C702), Colors.red[900]!],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: _fetchSadheSatiData,
                child: Text('Try Again', style: GoogleFonts.poppins()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Colors.red[300], size: 48),
            SizedBox(height: 16),
            Text(
              'No data available',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.red[900],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Unable to retrieve Sadhesati information.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSadheSatiContent() {
    // Adding null safety checks for all values
    bool isSadheSati =
        sadheSatiData?['sadhesati']?['result']?.toString().toLowerCase() ==
            'true';
    String saturnSign =
        sadheSatiData?['sadhesati']?['saturn_sign']?.toString() ?? 'Unknown';
    bool saturnRetrograde = sadheSatiData?['sadhesati']?['saturn_retrograde']
            ?.toString()
            .toLowerCase() ==
        'true';
    String moonSign = sadheSatiData?['moon_sign']?.toString() ?? 'Unknown';

    // For the timeline data
    List<dynamic> sadhesatiLifeAnalysis =
        sadheSatiData?['sadhesati_life_analysis'] ?? [];
    List<dynamic> smallPanoti = sadheSatiData?['small_panoti'] ?? [];

    // For remedies
    List<dynamic> remedies = sadheSatiData?['remedies'] ?? [];

    return Container(
      color: const Color(0xFFFCF7EF),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(
              isSadheSati,
              saturnSign,
              saturnRetrograde,
              moonSign,
            ),
            SizedBox(height: 16),
            _buildImprovedTimelineTable(
              "Sadhesati Life Analysis",
              sadhesatiLifeAnalysis,
            ),
            SizedBox(height: 16),
            _buildImprovedTimelineTable("Small Panoti Periods", smallPanoti),
            SizedBox(height: 16),
            if (remedies.isNotEmpty) _buildRemediesCard(remedies),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    bool isSadheSati,
    String saturnSign,
    bool saturnRetrograde,
    String moonSign,
  ) {
    return Card(
      elevation: 8,
      shadowColor: Colors.grey.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white, // Added white background
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sadhesati Status',
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                ),
                Icon(
                  isSadheSati ? Icons.warning_rounded : Icons.check_circle,
                  color: isSadheSati ? Colors.red[700] : Colors.green[700],
                  size: 32,
                ),
              ],
            ),
            Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'Status',
                    isSadheSati ? 'In Sadhesati' : 'Not in Sadhesati',
                    isSadheSati ? Colors.red[700]! : Colors.green[700]!,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    'Moon Sign',
                    moonSign,
                    Colors.red[700]!,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'Saturn Sign',
                    saturnSign,
                    Colors.red[700]!,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    'Saturn Retrograde',
                    saturnRetrograde ? 'Yes' : 'No',
                    Colors.red[700]!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
          textAlign: TextAlign.center, // Added this
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
          textAlign: TextAlign.center, // Added this
          maxLines: 2, // Optional: limit to 2 lines
          overflow: TextOverflow.ellipsis, // Optional: handle very long text
        ),
      ],
    );
  }

  // Improved timeline table with proper headers and rows - no gaps
  Widget _buildImprovedTimelineTable(String title, List<dynamic> timelineData) {
    // Group data by phase for better organization
    Map<String, List<dynamic>> groupedData = {};

    for (var item in timelineData) {
      String phase = item['phase'] ?? 'Unknown';
      if (!groupedData.containsKey(phase)) {
        groupedData[phase] = [];
      }
      groupedData[phase]!.add(item);
    }

    return Card(
      elevation: 8,
      shadowColor: Colors.grey.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white, // Added white background
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.red[900],
              ),
            ),
            SizedBox(height: 16),
            ...groupedData.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phase header
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    width: double.infinity,
                    child: Text(
                      _formatPhase(entry.key),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[900],
                      ),
                    ),
                  ),

                  // Table structure with no gaps between header and rows
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    child: Column(
                      children: [
                        // Table header - no bottom margin
                        Container(
                          color: Colors.red[50],
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Sign',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red[800],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Date',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red[800],
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 24,
                                child: Text(
                                  'R',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red[800],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Table rows - directly below header with no gaps
                        ...entry.value.asMap().entries.map((mapEntry) {
                          int index = mapEntry.key;
                          var item = mapEntry.value;
                          String signName = item['sign_name'] ?? 'Unknown';
                          String date = _formatDate(item['date'] ?? 'Unknown');
                          bool isRetro =
                              item['is_retro']?.toString().toLowerCase() ==
                                  'true';

                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: index < entry.value.length - 1
                                    ? BorderSide(color: Colors.red[50]!)
                                    : BorderSide.none,
                              ),
                              color: index.isEven
                                  ? Colors.white
                                  : Colors.red[50]!.withOpacity(0.3),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    signName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    date,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 24,
                                  child: isRetro
                                      ? Icon(
                                          Icons.replay,
                                          color: Colors.red[700],
                                          size: 16,
                                        )
                                      : SizedBox(),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRemediesCard(List<dynamic> remedies) {
    return Card(
      elevation: 8,
      shadowColor: Colors.grey.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white, // Added white background
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommended Remedies',
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.red[900],
              ),
            ),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red[100]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: remedies.length,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: index < remedies.length - 1
                            ? BorderSide(color: Colors.red[50]!)
                            : BorderSide.none,
                      ),
                      color: index.isEven
                          ? Colors.white
                          : Colors.red[50]!.withOpacity(0.3),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 3.0),
                            child: Icon(
                              Icons.brightness_1,
                              size: 8,
                              color: Colors.red[700],
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              remedies[index]?.toString() ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[800],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final inputFormat = DateFormat('yyyy-MM-dd');
      final outputFormat = DateFormat('MMM d, yyyy');
      final date = inputFormat.parse(dateStr);
      return outputFormat.format(date);
    } catch (e) {
      return dateStr; // Return original if parsing fails
    }
  }

  String _formatPhase(String phase) {
    // Convert phrases like RISING_START to "Rising Start"
    if (phase.contains('_')) {
      return phase
          .split('_')
          .map(
            (word) =>
                '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
          )
          .join(' ');
    }

    // If it's a single word, just capitalize the first letter
    return '${phase[0].toUpperCase()}${phase.substring(1).toLowerCase()}';
  }
}
