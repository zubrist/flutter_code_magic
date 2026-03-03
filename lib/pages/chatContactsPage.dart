import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar2.dart';
import 'package:saamay/pages/config.dart';
import 'package:saamay/pages/login.dart';

import 'chatHistoryPage.dart';

class ChatContactsPage extends StatefulWidget {
  const ChatContactsPage({Key? key}) : super(key: key);

  @override
  State<ChatContactsPage> createState() => _ChatContactsPageState();
}

class _ChatContactsPageState extends State<ChatContactsPage> {
  List<Map<String, dynamic>> contacts = [];
  bool _isLoading = false;
  String? errorMessage;
  int? userId;


  @override
  void initState() {
    super.initState();
    _initializeAndFetchContacts();
  }

  Future<void> _initializeAndFetchContacts() async {
    // Get user_id from responseList or fetch from API
    userId = responseList['userdata']?['user_id'] ?? responseList['user_id'];

    if (userId == null) {
      // If userId is not in responseList, fetch it from API
      await _fetchUserId();
    }

    if (userId != null) {
      await _fetchChatContacts();
    } else {
      setState(() {
        errorMessage = 'User ID not found';
      });
    }
  }

  Future<void> _fetchUserId() async {
    if (token == null || token == '') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$api/user/own'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'Success') {
          setState(() {
            // Extract user_id from the data object
            userId = jsonData['data']['user_id'];
          });
        }
      }
    } catch (e) {
      print('Error fetching user ID: $e');
    }
  }

  Future<void> _fetchChatContacts() async {
    if (userId == null) return;

    setState(() {
      _isLoading = true;
      errorMessage = null;
    });

    final url = '$api/chat_index/$userId';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success' && data['data'] != null) {
          setState(() {
            contacts = List<Map<String, dynamic>>.from(
                data['data'].map((item) => {
                  "consultant_id": item['consultant_id'],
                  "consultant_name": item['consultant_name'],
                  "rate": item['rate']?.toDouble() ?? 0.0,
                  "image_link": item['image_link'] ?? '',
                  "availability": item['availability'],
                  "service_id": item['service_id'],
                  "Chat_US_rate": item['Chat_US_rate']?.toDouble() ?? 0.0,
                  "Chat_Asia_rate": item['Chat_Asia_rate']?.toDouble() ?? 0.0,
                  "Chat_In_rate": item['Chat_In_rate']?.toDouble() ?? 0.0,
                })
            );
          });
        } else {
          setState(() {
            errorMessage = 'No data found';
          });
        }
      } else if (response.statusCode == 401) {
        // Unauthorized - redirect to login
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        throw Exception('Failed to load chat contacts');
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Failed to load contacts. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load contacts. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _fetchChatContacts();
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is logged in
    if (token == null || token == '') {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar2(title: 'Chat Contacts'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Please login to view chat contacts',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.button,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Login',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar2(title: 'Chat Contact',),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.background,
        onRefresh: _onRefresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.text))
            : errorMessage != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.button,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _initializeAndFetchContacts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
            : contacts.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No chat history found',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start chatting with consultants',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        )
            : Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  return _buildContactListItem(
                    consultantId: contact['consultant_id'],
                    name: contact['consultant_name'] ?? 'Unknown',
                    rate: contact['Chat_In_rate'] ?? 0.0,
                    imageUrl: contact['image_link'] ?? '',
                    availability: contact['availability'] ?? 'N',
                    serviceId: contact['service_id'],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactListItem({
    required int consultantId,
    required String name,
    required double rate,
    required String imageUrl,
    required String availability,
    required int? serviceId,
  }) {
    Color availabilityColor;
    String availabilityText;

    if (availability == "A") {
      availabilityColor = const Color(0xFF28A746);
      availabilityText = "Available";
    } else if (availability == "B") {
      availabilityColor = const Color(0xFFDC3546);
      availabilityText = "Busy";
    } else {
      availabilityColor = Colors.grey;
      availabilityText = "Offline";
    }

    return GestureDetector(
      onTap: () {
        // Navigate to chat page with consultant
        // You can uncomment and modify this when you have the chat page ready
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => ChatPage(
        //       consultantId: consultantId,
        //       consultantName: name,
        //       rate: rate,
        //     ),
        //   ),
        // );

        print('Navigate to chat with consultant: $consultantId');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    height: 80,
                    width: 80,
                    fit: BoxFit.fitHeight,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: availabilityColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.lora(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: availabilityColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          availabilityText,
                          style: GoogleFonts.poppins(
                            color: availabilityColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chat Rate: ₹$rate/min',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.button,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to chat
                        debugPrint('Start chat with: $consultantId');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatHistoryPage(
                              userId: userId!,
                              consultantId: consultantId,
                              consultantName: name,
                              consultantImage: imageUrl,
                              availability: availability,
                              rate: rate,
                            ),
                          ),
                        );
                        // Add your navigation logic here
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Show Chat',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
