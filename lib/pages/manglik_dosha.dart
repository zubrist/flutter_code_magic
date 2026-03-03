import 'package:saamay/pages/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart'; // Import for Poppins font

class ManglikDosha extends StatefulWidget {
  final Map<String, dynamic> userInput;

  ManglikDosha({required this.userInput});

  @override
  _ManglikDoshaState createState() => _ManglikDoshaState();
}

class _ManglikDoshaState extends State<ManglikDosha> {
  bool isLoading = true;
  String? error;
  Map<String, dynamic>? manglikData;

  @override
  void initState() {
    super.initState();
    _fetchManglikDoshaData();
  }

  Future<void> _fetchManglikDoshaData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final url = Uri.parse('$api/indian-api/kundali-api/manglik-dosha');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          // Add your authorization token if required
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(widget.userInput),
      );
      //print("responce body manglik dosha :${response.body}");
      //print(response.statusCode);
      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        if (jsonData['success'] == 1) {
          setState(() {
            manglikData = jsonData['data'];
            isLoading = false;
          });
          //print("Manglik data: $manglikData"); // Debug print
        } else {
          setState(() {
            error = 'Failed to fetch Manglik Dosha data.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error =
              'Failed to fetch Manglik Dosha data. Status code: ${response.statusCode}';
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
    } else if (manglikData != null) {
      return _buildManglikDoshaContent();
    } else {
      return _buildNoDataWidget();
    }
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red[900]!),
          ),
          SizedBox(height: 16),
          Text(
            'Loading Manglik Dosha analysis...',
            style: GoogleFonts.poppins(
              fontSize: 16,
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
                fontSize: 18,
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
                onPressed: _fetchManglikDoshaData,
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[900],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Unable to retrieve Manglik Dosha information.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManglikDoshaContent() {
    // Adding null safety checks for all values
    bool isManglik = manglikData?['manglik_dosha'] ?? false;
    String strength = manglikData?['strength']?.toString() ?? 'Unknown';
    num percentage = (manglikData?['percentage'] ?? 0) is num
        ? manglikData!['percentage']
        : int.tryParse(manglikData?['percentage']?.toString() ?? '0') ?? 0;

    // Handle the case where remedies might be null or not a list
    List<dynamic> remedies = [];
    if (manglikData?['remedies'] != null) {
      if (manglikData!['remedies'] is List) {
        remedies = manglikData!['remedies'];
      }
    }

    return Container(
      color: const Color(0xFFFCF7EF),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(isManglik, strength, percentage),
            SizedBox(height: 16),
            _buildInfoCard(),
            SizedBox(height: 16),
            if (remedies.isNotEmpty) _buildRemediesCard(remedies),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isManglik, String strength, num percentage) {
    return Card(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.grey.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Manglik Dosha Status',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                ),
                Icon(
                  isManglik ? Icons.warning_rounded : Icons.check_circle,
                  color: isManglik ? Colors.red[700] : Colors.green[700],
                  size: 32,
                ),
              ],
            ),
            Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Added this
              crossAxisAlignment: CrossAxisAlignment.center, // Added this
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'Status',
                    isManglik ? 'Manglik' : 'Non-Manglik',
                    isManglik ? Colors.red[700]! : Colors.green[700]!,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    'Strength',
                    strength,
                    strength == 'No'
                        ? Colors.green[700]!
                        : strength == 'Mild'
                            ? Colors.orange[700]!
                            : Colors.red[700]!,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    'Percentage',
                    '$percentage%',
                    percentage < 25
                        ? Colors.green[700]!
                        : percentage < 50
                            ? Colors.orange[700]!
                            : Colors.red[700]!,
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
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center, // Added this
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
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

  Widget _buildInfoCard() {
    return Card(
      color: Colors.white, // Added white background
      elevation: 8,
      shadowColor: Colors.grey.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // child: Padding(
      //   padding: const EdgeInsets.all(20.0),
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       Text(
      //         'What is Manglik Dosha?',
      //         style: TextStyle(
      //           fontSize: 20,
      //           fontWeight: FontWeight.bold,
      //           color: Colors.indigo[900],
      //         ),
      //       ),
      //       SizedBox(height: 16),
      //       Text(
      //         'Manglik Dosha occurs when Mars is placed in the 1st, 2nd, 4th, 7th, 8th, or 12th house of the birth chart. It is believed to impact marital harmony and compatibility.',
      //         style: TextStyle(
      //           fontSize: 16,
      //           color: Colors.grey[800],
      //           height: 1.5,
      //         ),
      //       ),
      //       SizedBox(height: 12),
      //       Text(
      //         'The severity of Manglik Dosha varies based on the exact placement of Mars and its relationships with other planets in the birth chart.',
      //         style: TextStyle(
      //           fontSize: 16,
      //           color: Colors.grey[800],
      //           height: 1.5,
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }

  Widget _buildRemediesCard(List<dynamic> remedies) {
    return Card(
      color: Colors.white, // Added white background
      elevation: 8,
      shadowColor: Colors.grey.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommended Remedies',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[900],
              ),
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: remedies.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.brightness_1,
                        size: 12,
                        color: Colors.red[700],
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          remedies[index]?.toString() ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
