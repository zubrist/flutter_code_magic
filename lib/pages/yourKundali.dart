import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/config.dart';
import 'package:saamay/pages/editProfile.dart';
// Import the other pages
import 'package:saamay/pages/manglik_Dosha.dart';
import 'package:saamay/pages/sadhe_Sati.dart';
import 'package:saamay/pages/kaal_Sarpa_Yoga.dart';
import 'package:google_fonts/google_fonts.dart';

class YourKundali extends StatefulWidget {
  const YourKundali({Key? key}) : super(key: key);

  @override
  _YourKundaliState createState() => _YourKundaliState();
}

class _YourKundaliState extends State<YourKundali>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  Map<String, dynamic>? _responseData;
  String? _errorMessage;
  TabController? _tabController;
  Map<String, dynamic>? _userInput;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchKundaliData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _fetchKundaliData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = responseList['user_data']['user_id'];

      if (userId == 0) {
        setState(() {
          _errorMessage = 'User ID not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final profileResponse = await http.get(
        Uri.parse('$api/username/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (profileResponse.statusCode != 200) {
        setState(() {
          _errorMessage = 'Failed to load user profile. Please try again.';
          _isLoading = false;
        });
        return;
      }

      final profileData = jsonDecode(profileResponse.body);

      if (profileData['status'] != 'Success' || profileData['data'] == null) {
        setState(() {
          _errorMessage = 'Invalid profile data received.';
          _isLoading = false;
        });
        return;
      }

      final userData = profileData['data'];

      // Check for null or empty required fields
      final requiredFields = {
        'user_fullname': userData['user_fullname'],
        'user_DoB': userData['user_DoB'],
        'user_ToB': userData['user_ToB'],
        'user_gender': userData['user_gender'],
        'user_PoB': userData['user_PoB'],
        'user_lat': userData['user_lat'],
        'user_long': userData['user_long'],
        'user_timezone': userData['user_timezone'],
      };

      final missingFields = requiredFields.entries
          .where(
            (entry) => entry.value == null || entry.value.toString().isEmpty,
          )
          .map((entry) => entry.key)
          .toList();

      if (missingFields.isNotEmpty) {
        setState(() {
          _isLoading = false;
        });
        // Show alert dialog for missing fields
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                'Missing Information',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              content: Text(
                'Please complete your profile',
                style: GoogleFonts.poppins(color: Colors.black87),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                    // Optionally navigate to EditProfile page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfile(),
                      ),
                    );
                  },
                  child: Text(
                    'Update Profile',
                    style: GoogleFonts.poppins(color: Color(0xFF89216B)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(color: Color(0xFF89216B)),
                  ),
                ),
              ],
            );
          },
        );
        return;
      }

      final dob = userData['user_DoB'].split('-');
      final year = dob[0];
      final month = dob[1];
      final day = dob[2];

      final tob = userData['user_ToB'].split(':');
      final hour = tob[0];
      final minute = tob[1];

      // Prepare user input for other tabs
      _userInput = {
        "full_name": userData['user_fullname'],
        "day": day,
        "month": month,
        "year": year,
        "hour": hour,
        "min": minute,
        "sec": "00",
        "gender": userData['user_gender'],
        "place": userData['user_PoB'],
        "lat": userData['user_lat'],
        "lon": userData['user_long'],
        "tzone": userData['user_timezone'].toString() != ''
            ? userData['user_timezone'].toString()
            : '5.5',
        "lan": "en",
        "planet_color": "white",
        "sign_color": "red",
        "line_color": "red",
        "chart_color": "white",
        "chart_type": "north",
      };

      final response = await http.put(
        Uri.parse('$api/indian-api/kundali-api/basic-astro-details'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(_userInput),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          _responseData = jsonResponse;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load kundali data. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        flexibleSpace: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF89216B), Color(0xFFDA4453)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned.fill(
              child: Image.asset('assets/images/BG.png', fit: BoxFit.cover),
            ),
          ],
        ),
        title: Text(
          'Your Kundali',
          style: GoogleFonts.lora(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Basic Info'),
            Tab(text: 'Manglik Dosha'),
            Tab(text: 'Sadhe Sati'),
            Tab(text: 'Kaal Sarpa Yoga'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Basic Info Tab - Current content
          _buildBasicInfoTab(),
          // Manglik Dosha Tab
          _userInput != null
              ? ManglikDosha(userInput: _userInput!)
              : const Center(child: CircularProgressIndicator()),
          // Sadhe Sati Tab
          _userInput != null
              ? SadheSati(userInput: _userInput!)
              : const Center(child: CircularProgressIndicator()),
          // Kaal Sarpa Yoga Tab
          _userInput != null
              ? KaalSarpaYoga(userInput: _userInput!)
              : const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.red[900]));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: GoogleFonts.poppins(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchKundaliData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_responseData == null) {
      return const Center(child: Text('No data available'));
    }

    final data = _responseData!['data'];
    if (data == null) {
      return const Center(child: Text('Invalid response format'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRedesignedInfoCard('Personal Information', [
            _buildInfoRowAlternating(
              'Full Name',
              data['full_name'] ?? '',
              0,
              4,
            ),
            _buildInfoRowAlternating('Gender', data['gender'] ?? '', 1, 4),
            _buildInfoRowAlternating('Place', data['place'] ?? '', 2, 4),
            _buildInfoRowAlternating(
              'Timezone',
              data['timezone']?.toString() ?? '',
              3,
              4,
            ),
          ]),
          const SizedBox(height: 16),
          _buildRedesignedInfoCard('Astrological Details', [
            _buildInfoRowAlternating('Sun Sign', data['sunsign'] ?? '', 0, 5),
            _buildInfoRowAlternating('Moon Sign', data['moonsign'] ?? '', 1, 5),
            _buildInfoRowAlternating(
              'Nakshatra',
              data['nakshatra'] ?? '',
              2,
              5,
            ),
            _buildInfoRowAlternating('Tithi', data['tithi'] ?? '', 3, 5),
            _buildInfoRowAlternating('Paksha', data['paksha'] ?? '', 4, 5),
          ]),
          const SizedBox(height: 16),
          _buildRedesignedInfoCard('Additional Information', [
            _buildInfoRowAlternating('Day', data['vaar'] ?? '', 0, 6),
            _buildInfoRowAlternating(
              'Chandra Masa',
              data['chandramasa'] ?? '',
              1,
              6,
            ),
            _buildInfoRowAlternating('Tatva', data['tatva'] ?? '', 2, 6),
            _buildInfoRowAlternating('Varna', data['varna'] ?? '', 3, 6),
            _buildInfoRowAlternating('Gana', data['gana'] ?? '', 4, 6),
            _buildInfoRowAlternating('Nadi', data['nadi'] ?? '', 5, 6),
          ]),
          const SizedBox(height: 16),
          _buildRedesignedInfoCard('Timings', [
            _buildInfoRowAlternating('Sunrise', data['sunrise'] ?? '', 0, 2),
            _buildInfoRowAlternating('Sunset', data['sunset'] ?? '', 1, 2),
          ]),
          if (data['paya'] != null) ...[
            const SizedBox(height: 16),
            _buildRedesignedInfoCard('Paya', [
              _buildInfoRowAlternating(
                'Type',
                data['paya']['type'] ?? '',
                0,
                2,
              ),
              _buildInfoRowAlternating(
                'Result',
                data['paya']['result'] ?? '',
                1,
                2,
              ),
            ]),
          ],
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildRedesignedInfoCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: AppColors.button,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              title,
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Content with no additional padding to allow rows to go edge-to-edge
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowAlternating(
    String label,
    String value,
    int index,
    int totalItems,
  ) {
    // Alternate background colors based on index
    final backgroundColor = index % 2 == 0 ? Colors.white : Color(0xFFF5F5F5);

    // Determine if this is the last item
    final isLastItem = index == totalItems - 1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        // Add bottom radius only to the last item
        borderRadius: isLastItem
            ? BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
