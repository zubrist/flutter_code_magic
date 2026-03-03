import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';
import 'package:saamay/pages/Notification.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/config.dart';
import 'package:saamay/pages/walletTransactions.dart';
import 'package:saamay/pages/editProfile.dart';
import 'package:saamay/pages/login.dart';
import 'package:saamay/pages/recharge.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saamay/pages/editProfile.dart';

class ConsultantProfileModel {
  final int id;
  final String name;
  final String displayName;
  final String category;
  final int yearOfExperience;
  final String areaOfSpec;
  final String? language;
  final String imageLink;
  final String type;
  final int role;
  final String? aboutMe;
  final String rating;
  final String totalChatMinutes;
  final String totalCallMinutes;
  final String availabilityFlag; // Added availability flag
  final String? availabilityColor; // Added availability color
  final List schedules;
  final List feedbacks;

  ConsultantProfileModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.category,
    required this.yearOfExperience,
    required this.areaOfSpec,
    required this.language,
    required this.imageLink,
    required this.type,
    required this.role,
    required this.aboutMe,
    required this.rating,
    required this.totalChatMinutes,
    required this.totalCallMinutes,
    required this.availabilityFlag, // Added availability flag
    required this.availabilityColor, // Added availability color
    required this.schedules,
    required this.feedbacks,
  });

  factory ConsultantProfileModel.fromJson(Map<String, dynamic> json) {
    //print('Profile rating: ${json['rating']}');
    return ConsultantProfileModel(
      id: json['id'],
      name: json['name'],
      displayName: json['display_name'],
      category: json['category'],
      yearOfExperience: json['year_of_experience'],
      areaOfSpec: json['area_of_spec'],
      language: json['language'],
      imageLink: json['image_link'],
      type: json['type'],
      role: json['role'],
      aboutMe: json['about_me'] ?? '',
      rating: json['rating']?.toString() ?? '0.0',
      totalChatMinutes: json['total_chat_minutes']?.toString() ?? '0',
      totalCallMinutes: json['total_call_minutes']?.toString() ?? '0',
      availabilityFlag:
          json['availability_flag'] ?? 'N', // Added availability flag
      availabilityColor: json['availability_color'], // Added availability color
      schedules: json['schedules'] ?? [],
      feedbacks: json['feedbacks'] ?? [],
    );
  }

  // Helper method to check if consultant is available
  bool get isAvailable => availabilityFlag == 'A';

  // Helper method to get availability status text
  String get availabilityStatusText {
    return isAvailable ? 'Available' : 'Unavailable';
  }
}

class ConsultantReview {
  final int orderId;
  final String? userFullname;
  final String sessionStatus;
  final int serviceId;
  final String? feedback;
  final int? rating;
  final String? startTime;
  final String? category;

  ConsultantReview({
    required this.orderId,
    this.userFullname,
    required this.sessionStatus,
    required this.serviceId,
    this.feedback,
    this.rating,
    this.startTime,
    this.category,
  });

  factory ConsultantReview.fromJson(Map<String, dynamic> json) {
    return ConsultantReview(
      orderId: json['order_id'] ?? 0,
      userFullname: json['user_fullname']?.toString() ?? 'Anonymous',
      sessionStatus: json['session_status']?.toString() ?? 'Unknown',
      serviceId: json['service_id'] ?? 0,
      feedback: json['feedback']?.toString(),
      rating: json['rating'],
      startTime: json['start_time']?.toString(),
      category: json['con_category']?.toString() ?? 'Unknown',
    );
  }

  String get serviceName {
    switch (serviceId) {
      case 1:
        return 'Chat';
      case 2:
        return 'Call';
      case 3:
        return 'Puja';
      case 4:
        return 'Session';
      default:
        return 'Service';
    }
  }

  String get formattedDate {
    if (startTime == null) return 'Not scheduled';
    DateTime? dateTime = DateTime.tryParse(startTime!);
    if (dateTime == null) return 'Invalid date';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class ConsultantReviewsResponse {
  final String status;
  final ConsultantReviewsData data;

  ConsultantReviewsResponse({required this.status, required this.data});

  factory ConsultantReviewsResponse.fromJson(Map<String, dynamic> json) {
    return ConsultantReviewsResponse(
      status: json['status'],
      data: ConsultantReviewsData.fromJson(json['data']),
    );
  }
}

class ConsultantReviewsData {
  final int consultantId;
  final List<ConsultantReview> orders;
  final double avgRating;
  final int totalRatings;
  final int totalOrders;

  ConsultantReviewsData({
    required this.consultantId,
    required this.orders,
    required this.avgRating,
    required this.totalRatings,
    required this.totalOrders,
  });

  factory ConsultantReviewsData.fromJson(Map<String, dynamic> json) {
    //print('Raw avg_rating: ${json['avg_rating']}');
    return ConsultantReviewsData(
      consultantId: json['consultant_id'] ?? 0,
      orders: (json['orders'] as List)
          .map((order) => ConsultantReview.fromJson(order))
          .toList(),
      avgRating: json['avg_rating'] != null
          ? double.tryParse(json['avg_rating'].toString()) ?? 0.0
          : 0.0,
      totalRatings: json['total_ratings'] ?? 0,
      totalOrders: json['total_orders'] ?? 0,
    );
  }

  List<ConsultantReview> get reviewsWithFeedback {
    return orders.where((order) => order.feedback != null).toList();
  }
}

class AstrologerProfilePage extends StatefulWidget {
  final int consultantId;
  final double rate;
  final int? availabilityServiceId; // Added this parameter

  const AstrologerProfilePage({
    Key? key,
    required this.consultantId,
    required this.rate,
    this.availabilityServiceId, // Added this parameter
  }) : super(key: key);

  @override
  State<AstrologerProfilePage> createState() => _AstrologerProfilePageState();
}

class _AstrologerProfilePageState extends State<AstrologerProfilePage> {
  bool isLoading = true;
  bool isLoadingReviews = false;
  bool showAllReviews = false;
  bool _isBookingLoading = false;
  ConsultantProfileModel? consultantProfile;
  ConsultantReviewsData? reviewsData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchConsultantProfile();
    //print("first time:"+responseList['user_data']?['user_first_time']);
  }

  Future<bool> _checkUserProfileData() async {
    try {
      final userId =
          responseList['user_data']?['user_id'] ?? responseList['user_id'];
      final response = await http.get(
        Uri.parse('$api/username/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'Success') {
          final userData = jsonData['data'];
          final requiredFields = {
            'full_name': userData['user_fullname'],
            'user_DoB': userData['user_DoB'],
            'user_ToB': userData['user_ToB'],
            'gender': userData['user_gender'],
            'place': userData['user_PoB'],
            'lat': userData['user_lat'],
            'lon': userData['user_long'],
            'tzone': userData['user_timezone']?.toString() ?? '5.5',
          };

          final missingFields = requiredFields.entries
              .where(
                (entry) =>
                    entry.value == null || entry.value.toString().isEmpty,
              )
              .map((entry) => entry.key)
              .toList();

          if (missingFields.isNotEmpty) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.white,
                title: const Text('Incomplete Profile'),
                content: const Text(
                  'Please complete your profile with all required details before booking',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfile()),
                      );
                    },
                    child: Text(
                      'Update profile',
                      style: GoogleFonts.poppins(color: AppColors.text),
                    ),
                  ),
                ],
              ),
            );
            return false;
          }

          return true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to fetch user profile')),
          );
          return false;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
      return false;
    }
  }

  Future<void> fetchConsultantProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$api/consultant_profile/${widget.consultantId}'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        //print('Profile API Response: $jsonData');
        if (jsonData['status'] == 'Success') {
          setState(() {
            consultantProfile = ConsultantProfileModel.fromJson(
              jsonData['data'],
            );
            isLoading = false;
          });
          fetchConsultantReviews();
        } else {
          setState(() {
            errorMessage = 'Failed to load data';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchConsultantReviews() async {
    if (mounted) {
      setState(() {
        isLoadingReviews = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse('$api/consultant_orders_with_ratings/${widget.consultantId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        //print('Reviews API Response: $jsonData');
        if (jsonData['status'] == 'Success') {
          if (mounted) {
            setState(() {
              reviewsData = ConsultantReviewsData.fromJson(jsonData['data']);
              isLoadingReviews = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              errorMessage =
                  'Failed to load reviews: ${jsonData['message'] ?? 'Unknown error'}';
              isLoadingReviews = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage =
                'Server error fetching reviews: ${response.statusCode}';
            isLoadingReviews = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Network error fetching reviews: $e';
          isLoadingReviews = false;
        });
      }
    }
  }

  Future<void> _handleBooking({
    required int serviceId,
    required String successMsg,
    required String failMsg,
  }) async {
    if (!consultantProfile!.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consultant is currently unavailable'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (token == '') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
      return;
    }

    final isProfileComplete = await _checkUserProfileData();
    if (!isProfileComplete) return;

    setState(() {
      _isBookingLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Fetch user data
      final userResponse = await http.get(
        Uri.parse('$api/user/own'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (userResponse.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${userResponse.statusCode}')),
        );
        setState(() {
          _isBookingLoading = false;
        });
        return;
      }

      final userData = jsonDecode(userResponse.body);

      if (userData['status'] != 'Success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch user data')),
        );
        setState(() {
          _isBookingLoading = false;
        });
        return;
      }

      // Extract phone number from API response
      final String userPhone = userData['data']['user_wa'] ?? userData['data']['user_mob'] ?? '';

      if (userPhone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number not found')),
        );
        setState(() {
          _isBookingLoading = false;
        });
        return;
      }

      // Fetch wallet data
      final walletResponse = await http.get(
        Uri.parse('$api/user_wallet_balance'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (walletResponse.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch wallet data')),
        );
        setState(() {
          _isBookingLoading = false;
        });
        return;
      }

      final walletData = jsonDecode(walletResponse.body);
      final userWallet = walletData['wallet_balance']?.toDouble() ?? 0.0;
      final packRechargeIdAstrology = walletData['pack_recharge_id_Astrology'];
      final requiredBalance = 5 * widget.rate;

      bool? userFirstTime = prefs.getBool('user_first_time');
      final bool whatsappVerified = userData['whatsapp_verified'] ?? false;
      int? packRechargeId;

      // Check if first time user
      if (userFirstTime == true) {
        if (whatsappVerified) {
          // A.1: Mobile verified - allow free chat
          packRechargeId = null;
        } else {
          // A.2: Not verified - ask to verify or continue
          setState(() {
            _isBookingLoading = false;
          });

          final shouldContinue = await _showVerificationOptionsDialog();

          if (shouldContinue == null) return; // User cancelled

          if (shouldContinue == true) {
            // User chose to verify - pass phone number
            final verificationSuccess = await _showVerificationDialog(userPhone);

            if (verificationSuccess == true) {
              // Verification successful - allow free chat
              packRechargeId = null;
            } else {
              // Verification failed or cancelled
              return;
            }
          } else {
            // User chose to continue without verification
            // Check for pack or wallet balance
            packRechargeId = await _checkPaymentMethod(
              packRechargeIdAstrology,
              userWallet,
              requiredBalance,
              failMsg,
            );

            if (packRechargeId == null && userWallet < requiredBalance) {
              return; // Payment check failed
            }
          }

          setState(() {
            _isBookingLoading = true;
          });
        }
      } else {
        // Not first time user - check pack or wallet balance
        packRechargeId = await _checkPaymentMethod(
          packRechargeIdAstrology,
          userWallet,
          requiredBalance,
          failMsg,
        );

        if (packRechargeId == null && userWallet < requiredBalance) {
          return; // Payment check failed
        }
      }

      // Fetch schedules
      final scheduleResponse = await http.get(
        Uri.parse('$api/consultants_schedules/${widget.consultantId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (scheduleResponse.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${scheduleResponse.statusCode}')),
        );
        setState(() {
          _isBookingLoading = false;
        });
        return;
      }

      final scheduleData = jsonDecode(scheduleResponse.body);
      if (!(scheduleData['status'] == 'Success')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch schedules')),
        );
        setState(() {
          _isBookingLoading = false;
        });
        return;
      }

      final validSchedules = scheduleData['data']['valid_schedules'] as List;
      if (validSchedules.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid schedules available')),
        );
        setState(() {
          _isBookingLoading = false;
        });
        return;
      }

      final firstSchedule = validSchedules[0];
      final endTime = firstSchedule['end'].split('T')[1];
      final now = DateTime.now().add(Duration(seconds: 20));
      final startTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      final payload = {
        'consultant_id': widget.consultantId,
        'con_category': consultantProfile!.category,
        'session_rate': widget.rate,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'start_time': startTime,
        'end_time': endTime,
        'session_status': 'Scheduled',
        'service_id': serviceId,
        'promo_id': null,
        'pack_recharge_id': packRechargeId,
      };

      final orderResponse = await http.post(
        Uri.parse('$api/placeorder'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (orderResponse.statusCode == 201) {
        final orderData = jsonDecode(orderResponse.body);
        if (orderData['status'] == 'Success') {
          prefs.setBool('user_first_time', false);
          responseList['user_data']?['user_first_time'] = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(successMsg)),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NotificationPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${orderData['message']}')),
          );
        }
      } else if (orderResponse.statusCode < 500) {
        final orderData = jsonDecode(orderResponse.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(orderData['detail'] ?? 'Failed to schedule')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network Error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    } finally {
      setState(() {
        _isBookingLoading = false;
      });
    }
  }

  // Check payment method (pack or wallet)
  Future<int?> _checkPaymentMethod(
      int? packRechargeIdAstrology,
      double userWallet,
      double requiredBalance,
      String failMsg,
      ) async {
    if (packRechargeIdAstrology != null) {
      // User has astrology pack
      return packRechargeIdAstrology;
    } else if (userWallet >= requiredBalance) {
      // Sufficient wallet balance
      return null; // pack_recharge_id not required
    } else {
      // Insufficient balance
      _showInsufficientBalanceDialog(requiredBalance, userWallet, failMsg);
      setState(() {
        _isBookingLoading = false;
      });
      return null;
    }
  }

// Show verification options dialog
  Future<bool?> _showVerificationOptionsDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Validate your Mobile Number',
            style: GoogleFonts.lora(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Validate your phone number for your first  Free Chat/ Call \nपहली फ्री चैट या कॉल के लिए अपना फ़ोन नंबर वेरीफाई करें।',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false); // Continue without verification
              },
              child: Text(
                'Skip',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true); // Proceed to verification
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Validate Now',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

// Show verification dialog with OTP
  // Parse phone number to extract country code and number
  Map<String, String> _parsePhoneNumber(String fullPhone) {
    // Assuming format like "917439291801" where first 2-3 digits are country code
    // For India (91), it's 2 digits
    String countryCode = '';
    String phoneNumber = '';

    if (fullPhone.startsWith('91') && fullPhone.length > 10) {
      countryCode = '91';
      phoneNumber = fullPhone.substring(2);
    } else if (fullPhone.startsWith('1') && fullPhone.length == 11) {
      // US/Canada
      countryCode = '1';
      phoneNumber = fullPhone.substring(1);
    } else if (fullPhone.length > 10) {
      // Generic: assume last 10 digits are phone, rest is country code
      phoneNumber = fullPhone.substring(fullPhone.length - 10);
      countryCode = fullPhone.substring(0, fullPhone.length - 10);
    } else {
      phoneNumber = fullPhone;
    }

    return {'countryCode': countryCode, 'phoneNumber': phoneNumber};
  }

// Show verification dialog with OTP - Updated to accept phone parameter
  Future<bool?> _showVerificationDialog(String fullPhoneFromApi) async {
    final otpController = TextEditingController();
    bool isVerifyingOtp = false;
    String? otpValidationMessage;
    bool otpSent = false;

    // Parse the phone number
    final parsedPhone = _parsePhoneNumber(fullPhoneFromApi);
    final countryCode = parsedPhone['countryCode'] ?? '';
    final phoneNumber = parsedPhone['phoneNumber'] ?? '';

    // Send OTP first
    try {
      final response = await http.post(
        Uri.parse('$api/verify_whatsapp_send_otp'),
        body: json.encode({"whatsapp_no": fullPhoneFromApi}),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP. Try again.')),
        );
        return false;
      }
      otpSent = true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending OTP: $e')),
      );
      return false;
    }

    if (!otpSent) return false;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.red[900]),
                  SizedBox(width: 10),
                  Text(
                    'Enter OTP',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter the 4-digit code sent to',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '+$countryCode $phoneNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 30),
                  Pinput(
                    length: 4,
                    controller: otpController,
                    focusedPinTheme: PinTheme(
                      width: 56,
                      height: 56,
                      textStyle: TextStyle(
                        fontSize: 22,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red.shade900, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    defaultPinTheme: PinTheme(
                      width: 56,
                      height: 56,
                      textStyle: TextStyle(
                        fontSize: 22,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    submittedPinTheme: PinTheme(
                      width: 56,
                      height: 56,
                      textStyle: TextStyle(
                        fontSize: 22,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withOpacity(0.1),
                        border: Border.all(color: Colors.red.shade900),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                    showCursor: true,
                    onCompleted: (pin) async {
                      setDialogState(() {
                        isVerifyingOtp = true;
                      });

                      final verified = await _verifyOtpInline(fullPhoneFromApi, pin);

                      if (verified) {
                        Navigator.pop(dialogContext, true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Number verified successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        setDialogState(() {
                          isVerifyingOtp = false;
                          otpValidationMessage = "Incorrect OTP. Try again.";
                        });
                      }
                    },
                  ),
                  if (otpValidationMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        otpValidationMessage!,
                        style: TextStyle(
                          color: otpValidationMessage!.contains('Incorrect')
                              ? Colors.red
                              : Colors.green,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  if (isVerifyingOtp)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: CircularProgressIndicator(
                        color: Colors.red.shade900,
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isVerifyingOtp
                      ? null
                      : () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isVerifyingOtp || otpController.text.length != 4
                      ? null
                      : () async {
                    setDialogState(() {
                      isVerifyingOtp = true;
                    });

                    final verified = await _verifyOtpInline(
                      fullPhoneFromApi,
                      otpController.text.trim(),
                    );

                    if (verified) {
                      Navigator.pop(dialogContext, true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Number verified successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      setDialogState(() {
                        isVerifyingOtp = false;
                        otpValidationMessage = "Incorrect OTP. Try again.";
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _verifyOtpInline(String fullPhone, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$api/verify_whatsapp_otp'),
        body: json.encode({
          "whatsapp_no": fullPhone,
          "otp": otp,
        }),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['is_verified'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _showInsufficientBalanceDialog(
      double required, double current, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Insufficient Wallet Balance'),
        content: Text(
            'You need at least ₹$required to $action. Your current balance is ₹$current.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppColors.text)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RechargePage()),
              );
            },
            child: Text('Top Up Wallet',
                style: GoogleFonts.poppins(color: AppColors.text)),
          ),
        ],
      ),
    );
  }

  void _handleStartChat() async {
    await _handleBooking(
      serviceId: 1,
      successMsg: 'Chat session scheduled successfully!',
      failMsg: 'book a chat',
    );
  }

  void _handleStartCall() async {
    await _handleBooking(
      serviceId: 2,
      successMsg: 'Call session scheduled successfully!',
      failMsg: 'book a call',
    );
  }

  // New method to build buttons based on availability service ID
  Widget _buildAvailableButtons() {
    // Determine which buttons to show based on availabilityServiceId
    bool showChat = widget.availabilityServiceId == null ||
        widget.availabilityServiceId == 0 ||
        widget.availabilityServiceId == 1;
    bool showCall = widget.availabilityServiceId == null ||
        widget.availabilityServiceId == 0 ||
        widget.availabilityServiceId == 2;

    if (showChat && showCall) {
      // Show both buttons
      return Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.button,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble, color: Colors.white),
                label: Text(
                  'Start Chat',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isBookingLoading ? null : _handleStartChat,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.button,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.call, color: Colors.white),
                label: Text(
                  'Start Call',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isBookingLoading ? null : _handleStartCall,
              ),
            ),
          ),
        ],
      );
    } else if (showChat) {
      // Show only chat button
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.button,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.chat_bubble, color: Colors.white),
          label: Text(
            'Start Chat',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _isBookingLoading ? null : _handleStartChat,
        ),
      );
    } else if (showCall) {
      // Show only call button
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.button,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.call, color: Colors.white),
          label: Text(
            'Start Call',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _isBookingLoading ? null : _handleStartCall,
        ),
      );
    } else {
      // Fallback - no buttons available (shouldn't happen in normal cases)
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              'No Services Available',
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          extendBodyBehindAppBar: true,
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.text),
                )
              : errorMessage != null
                  ? Center(
                      child: Text(
                        errorMessage!,
                        style: GoogleFonts.poppins(
                            color: Colors.red, fontSize: 16),
                      ),
                    )
                  : _buildProfileContent(),
        ),
        if (_isBookingLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.text),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileContent() {
    final displayRating =
        (reviewsData?.avgRating != null && reviewsData!.avgRating > 0.0)
            ? reviewsData!.avgRating.toStringAsFixed(1)
            : consultantProfile!.rating;

    return Stack(
      children: [
        Column(
          children: [
            Stack(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(consultantProfile!.imageLink),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Add availability indicator overlay
                Positioned(
                  top: 60,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: consultantProfile!.isAvailable
                          ? Colors.green
                          : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          consultantProfile!.availabilityStatusText,
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
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                transform: Matrix4.translationValues(0, -40, 0),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 80 +
                          MediaQuery.of(
                            context,
                          ).padding.bottom, // Added safe area padding
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          consultantProfile!.displayName,
                          style: GoogleFonts.lora(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildInfoSection(
                                'RATING:',
                                displayRating,
                                'assets/icons/star.png',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInfoSection(
                                'EXPERIENCE:',
                                '${consultantProfile!.yearOfExperience.toString()} years',
                                'assets/icons/experience.png',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildInfoSection(
                                'SKILLS:',
                                consultantProfile!.areaOfSpec,
                                'assets/icons/awards.png',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInfoSection(
                                'LANGUAGES:',
                                consultantProfile!.language ?? 'Not specified',
                                'assets/icons/language.png',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildInfoSection(
                                'CATEGORY:',
                                consultantProfile!.category,
                                'assets/icons/rate.png',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInfoSection(
                                'ROLE:',
                                'Consultant',
                                'assets/icons/roles.png',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ABOUT ME',
                                style: GoogleFonts.lora(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF800000),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                consultantProfile!.aboutMe ??
                                    '${consultantProfile!.displayName} is a ${consultantProfile!.category} specialist with ${consultantProfile!.yearOfExperience} years of experience. Specialized in ${consultantProfile!.areaOfSpec}.',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'RATINGS & REVIEWS',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF800000),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const WalletPage(
                                            initialTabIndex: 2,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Image.asset(
                                      'assets/icons/pen.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildReviewsSection(displayRating),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Modified bottom buttons section - conditional rendering with safe area
        Positioned(
          bottom: MediaQuery.of(
            context,
          ).padding.bottom, // Added safe area padding
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(color: Colors.transparent),
            padding: const EdgeInsets.all(16),
            child: consultantProfile!.isAvailable
                ? _buildAvailableButtons()
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Currently Unavailable',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(String displayRating) {
    final reviewsWithFeedback = reviewsData?.reviewsWithFeedback ?? [];

    if (isLoadingReviews) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: AppColors.text),
        ),
      );
    }

    if (reviewsWithFeedback.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 4),
        child: Text(
          'No reviews, Be the first one to provide feedback.',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
        ),
      );
    }

    reviewsWithFeedback.sort((a, b) {
      final aDate = DateTime.tryParse(a.startTime ?? '') ?? DateTime.now();
      final bDate = DateTime.tryParse(b.startTime ?? '') ?? DateTime.now();
      return bDate.compareTo(aDate);
    });

    final displayReviews = showAllReviews
        ? reviewsWithFeedback
        : reviewsWithFeedback.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          '${reviewsData?.totalRatings ?? 0} reviews',
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: showAllReviews ? 300 : 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayReviews.length,
            itemBuilder: (context, index) =>
                _buildReviewItem(displayReviews[index]),
          ),
        ),
        const SizedBox(height: 12),
        if (reviewsWithFeedback.length > 2)
          InkWell(
            onTap: () {
              //print('Reviews with feedback: ${reviewsWithFeedback.length}');
              setState(() {
                showAllReviews = !showAllReviews;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      showAllReviews
                          ? 'Show less'
                          : 'Show all ${reviewsWithFeedback.length} reviews',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      showAllReviews ? Icons.arrow_upward : Icons.arrow_forward,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewItem(ConsultantReview review) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16, bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  review.userFullname ?? 'Anonymous',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (review.rating != null)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromRGBO(250, 214, 192, 1),
                        Color.fromRGBO(247, 231, 210, 1),
                        Color.fromRGBO(250, 214, 192, 1),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: AppColors.text, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        review.rating!.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          color: AppColors.text,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${review.serviceName} • ${review.category ?? 'Unknown'} • ${review.formattedDate}',
            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 10),
          ),
          const SizedBox(height: 8),
          Text(
            review.feedback ?? 'No feedback provided',
            style: GoogleFonts.poppins(fontSize: 12, height: 1.4),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, String iconPath) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(iconPath, width: 20, height: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
