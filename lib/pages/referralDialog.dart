import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/config.dart';
import 'package:google_fonts/google_fonts.dart';

class ReferralDialog {
  static Future<void> showReferralDialog(BuildContext context) async {
    final TextEditingController phoneController = TextEditingController();
    bool isLoading = false;
    String responseMessage = '';
    bool showResponse = false;

    // Function to validate phone number
    bool isValidPhoneNumber(String phone) {
      // Basic validation for Indian phone numbers
      RegExp regExp = RegExp(r'^[0-9]{10}$');
      return regExp.hasMatch(phone);
    }

    // Function to send referral request
    Future<void> sendReferral() async {
      String phoneNumber = phoneController.text.trim();

      // Add country code if not present
      if (!phoneNumber.startsWith('91')) {
        phoneNumber = '91$phoneNumber';
      }

      try {
        // Show loading state
        isLoading = true;
        if (context.mounted) {
          Navigator.pop(context);
          _showLoadingDialog(context, 'Sending referral...');
        }

        final response = await http.post(
          Uri.parse('$api/send_referral'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'referee_ph': phoneNumber}),
        );

        // Close loading dialog
        if (context.mounted) {
          Navigator.pop(context);
        }

        Map<String, dynamic> responseData = jsonDecode(response.body);

        // Show response dialog
        if (context.mounted) {
          if (responseData['status'] == 'Successful') {
            _showSuccessDialog(
              context,
              'Referral sent successfully! Your friend will receive a WhatsApp message.',
            );
          } else {
            _showErrorDialog(
              context,
              'Failed to send referral. Please try again.',
            );
          }
        }
      } catch (e) {
        // Close loading dialog if open
        if (context.mounted && isLoading) {
          Navigator.pop(context);
        }

        // Show error dialog
        if (context.mounted) {
          _showErrorDialog(context, 'Error: ${e.toString()}');
        }
      }
    }

    // Show the actual dialog
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                'Refer a Friend',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter your friend\'s phone number to send them a referral',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Phone Number',
                      prefixText: '+91 ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDA4453)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                  ),
                  if (showResponse)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        responseMessage,
                        style: TextStyle(
                          color: responseMessage.contains('successfully')
                              ? AppColors.primary
                              : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (isValidPhoneNumber(phoneController.text.trim())) {
                      sendReferral();
                    } else {
                      setState(() {
                        showResponse = true;
                        responseMessage =
                            'Please enter a valid 10-digit phone number';
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Send Referral',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper function to show loading dialog
  static void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDA4453)),
                ),
                const SizedBox(width: 20),
                Text(message),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper function to show success dialog
  static void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Success',
            style: TextStyle(color: AppColors.primary),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFF89216B)),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper function to show error dialog
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Error', style: TextStyle(color: Colors.red)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'OK',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}
