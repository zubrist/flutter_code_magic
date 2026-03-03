import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/login.dart';
import 'package:saamay/pages/config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

final places = GoogleMapsPlaces(apiKey: gapi2);

class RegistrationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(resizeToAvoidBottomInset: false, body: ProfileForm());
  }
}

class ProfileForm extends StatefulWidget {
  @override
  _ProfileFormState createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  String? name;
  String? phone;
  String? email;
  String? password;
  String? gender;
  String? dateOfBirth;
  String? birthTime;
  String? placeOfBirth;
  String? referralCode;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController placeOfBirthController = TextEditingController();
  final TextEditingController referralCodeController = TextEditingController();

  // Initialize as null
  double? lat;
  double? long;
  double? timezone;

  bool isOtpSent = false;
  bool isNumberVerified = false;
  bool isVerifyingOtp = false;
  String? otpValidationMessage;
  final TextEditingController otpController = TextEditingController();

  int currentStep = 0;
  bool isTextFieldFilled = false;
  String? selectedGender;
  DateTime? selectedDate;
  String? selectedTime;
  bool _obscureText = true;
  bool isLoading = false;

  bool isCheckingEmail = false;
  bool isCheckingPhone = false;
  String? emailValidationMessage;
  String? phoneValidationMessage;
  bool isEmailValid = true;
  bool isPhoneValid = true;

  String selectedCountryCode = '91'; // Default to India
  String selectedCountryName = 'India';

  final List<Map<String, String>> countries = [
    {'name': 'Afghanistan', 'code': '93'},
    {'name': 'Albania', 'code': '355'},
    {'name': 'Algeria', 'code': '213'},
    {'name': 'Andorra', 'code': '376'},
    {'name': 'Angola', 'code': '244'},
    {'name': 'Argentina', 'code': '54'},
    {'name': 'Armenia', 'code': '374'},
    {'name': 'Australia', 'code': '61'},
    {'name': 'Austria', 'code': '43'},
    {'name': 'Azerbaijan', 'code': '994'},
    {'name': 'Bahrain', 'code': '973'},
    {'name': 'Bangladesh', 'code': '880'},
    {'name': 'Belarus', 'code': '375'},
    {'name': 'Belgium', 'code': '32'},
    {'name': 'Belize', 'code': '501'},
    {'name': 'Benin', 'code': '229'},
    {'name': 'Bhutan', 'code': '975'},
    {'name': 'Bolivia', 'code': '591'},
    {'name': 'Bosnia and Herzegovina', 'code': '387'},
    {'name': 'Botswana', 'code': '267'},
    {'name': 'Brazil', 'code': '55'},
    {'name': 'Brunei', 'code': '673'},
    {'name': 'Bulgaria', 'code': '359'},
    {'name': 'Burkina Faso', 'code': '226'},
    {'name': 'Burundi', 'code': '257'},
    {'name': 'Cambodia', 'code': '855'},
    {'name': 'Cameroon', 'code': '237'},
    {'name': 'Canada', 'code': '1'},
    {'name': 'Cape Verde', 'code': '238'},
    {'name': 'Central African Republic', 'code': '236'},
    {'name': 'Chad', 'code': '235'},
    {'name': 'Chile', 'code': '56'},
    {'name': 'China', 'code': '86'},
    {'name': 'Colombia', 'code': '57'},
    {'name': 'Comoros', 'code': '269'},
    {'name': 'Costa Rica', 'code': '506'},
    {'name': 'Croatia', 'code': '385'},
    {'name': 'Cuba', 'code': '53'},
    {'name': 'Cyprus', 'code': '357'},
    {'name': 'Czech Republic', 'code': '420'},
    {'name': 'Democratic Republic of the Congo', 'code': '243'},
    {'name': 'Denmark', 'code': '45'},
    {'name': 'Djibouti', 'code': '253'},
    {'name': 'East Timor', 'code': '670'},
    {'name': 'Ecuador', 'code': '593'},
    {'name': 'Egypt', 'code': '20'},
    {'name': 'El Salvador', 'code': '503'},
    {'name': 'Equatorial Guinea', 'code': '240'},
    {'name': 'Eritrea', 'code': '291'},
    {'name': 'Estonia', 'code': '372'},
    {'name': 'Ethiopia', 'code': '251'},
    {'name': 'Fiji', 'code': '679'},
    {'name': 'Finland', 'code': '358'},
    {'name': 'France', 'code': '33'},
    {'name': 'Gabon', 'code': '241'},
    {'name': 'Gambia', 'code': '220'},
    {'name': 'Georgia', 'code': '995'},
    {'name': 'Germany', 'code': '49'},
    {'name': 'Ghana', 'code': '233'},
    {'name': 'Greece', 'code': '30'},
    {'name': 'Guatemala', 'code': '502'},
    {'name': 'Guinea', 'code': '224'},
    {'name': 'Guinea-Bissau', 'code': '245'},
    {'name': 'Guyana', 'code': '592'},
    {'name': 'Haiti', 'code': '509'},
    {'name': 'Honduras', 'code': '504'},
    {'name': 'Hong Kong', 'code': '852'},
    {'name': 'Hungary', 'code': '36'},
    {'name': 'Iceland', 'code': '354'},
    {'name': 'India', 'code': '91'},
    {'name': 'Indonesia', 'code': '62'},
    {'name': 'Iran', 'code': '98'},
    {'name': 'Iraq', 'code': '964'},
    {'name': 'Ireland', 'code': '353'},
    {'name': 'Israel', 'code': '972'},
    {'name': 'Italy', 'code': '39'},
    {'name': 'Ivory Coast', 'code': '225'},
    {'name': 'Japan', 'code': '81'},
    {'name': 'Jordan', 'code': '962'},
    {'name': 'Kazakhstan', 'code': '7'},
    {'name': 'Kenya', 'code': '254'},
    {'name': 'Kiribati', 'code': '686'},
    {'name': 'Kosovo', 'code': '383'},
    {'name': 'Kuwait', 'code': '965'},
    {'name': 'Kyrgyzstan', 'code': '996'},
    {'name': 'Laos', 'code': '856'},
    {'name': 'Latvia', 'code': '371'},
    {'name': 'Lebanon', 'code': '961'},
    {'name': 'Lesotho', 'code': '266'},
    {'name': 'Liberia', 'code': '231'},
    {'name': 'Libya', 'code': '218'},
    {'name': 'Liechtenstein', 'code': '423'},
    {'name': 'Lithuania', 'code': '370'},
    {'name': 'Luxembourg', 'code': '352'},
    {'name': 'Macau', 'code': '853'},
    {'name': 'Macedonia', 'code': '389'},
    {'name': 'Madagascar', 'code': '261'},
    {'name': 'Malawi', 'code': '265'},
    {'name': 'Malaysia', 'code': '60'},
    {'name': 'Maldives', 'code': '960'},
    {'name': 'Mali', 'code': '223'},
    {'name': 'Malta', 'code': '356'},
    {'name': 'Marshall Islands', 'code': '692'},
    {'name': 'Mauritania', 'code': '222'},
    {'name': 'Mauritius', 'code': '230'},
    {'name': 'Mexico', 'code': '52'},
    {'name': 'Micronesia', 'code': '691'},
    {'name': 'Moldova', 'code': '373'},
    {'name': 'Monaco', 'code': '377'},
    {'name': 'Mongolia', 'code': '976'},
    {'name': 'Montenegro', 'code': '382'},
    {'name': 'Morocco', 'code': '212'},
    {'name': 'Mozambique', 'code': '258'},
    {'name': 'Myanmar', 'code': '95'},
    {'name': 'Namibia', 'code': '264'},
    {'name': 'Nauru', 'code': '674'},
    {'name': 'Nepal', 'code': '977'},
    {'name': 'Netherlands', 'code': '31'},
    {'name': 'New Zealand', 'code': '64'},
    {'name': 'Nicaragua', 'code': '505'},
    {'name': 'Niger', 'code': '227'},
    {'name': 'Nigeria', 'code': '234'},
    {'name': 'North Korea', 'code': '850'},
    {'name': 'Norway', 'code': '47'},
    {'name': 'Oman', 'code': '968'},
    {'name': 'Pakistan', 'code': '92'},
    {'name': 'Palau', 'code': '680'},
    {'name': 'Palestine', 'code': '970'},
    {'name': 'Panama', 'code': '507'},
    {'name': 'Papua New Guinea', 'code': '675'},
    {'name': 'Paraguay', 'code': '595'},
    {'name': 'Peru', 'code': '51'},
    {'name': 'Philippines', 'code': '63'},
    {'name': 'Poland', 'code': '48'},
    {'name': 'Portugal', 'code': '351'},
    {'name': 'Qatar', 'code': '974'},
    {'name': 'Republic of the Congo', 'code': '242'},
    {'name': 'Romania', 'code': '40'},
    {'name': 'Russia', 'code': '7'},
    {'name': 'Rwanda', 'code': '250'},
    {'name': 'San Marino', 'code': '378'},
    {'name': 'Sao Tome and Principe', 'code': '239'},
    {'name': 'Saudi Arabia', 'code': '966'},
    {'name': 'Senegal', 'code': '221'},
    {'name': 'Serbia', 'code': '381'},
    {'name': 'Seychelles', 'code': '248'},
    {'name': 'Sierra Leone', 'code': '232'},
    {'name': 'Singapore', 'code': '65'},
    {'name': 'Slovakia', 'code': '421'},
    {'name': 'Slovenia', 'code': '386'},
    {'name': 'Solomon Islands', 'code': '677'},
    {'name': 'Somalia', 'code': '252'},
    {'name': 'South Africa', 'code': '27'},
    {'name': 'South Korea', 'code': '82'},
    {'name': 'South Sudan', 'code': '211'},
    {'name': 'Spain', 'code': '34'},
    {'name': 'Sri Lanka', 'code': '94'},
    {'name': 'Sudan', 'code': '249'},
    {'name': 'Suriname', 'code': '597'},
    {'name': 'Swaziland', 'code': '268'},
    {'name': 'Sweden', 'code': '46'},
    {'name': 'Switzerland', 'code': '41'},
    {'name': 'Syria', 'code': '963'},
    {'name': 'Taiwan', 'code': '886'},
    {'name': 'Tajikistan', 'code': '992'},
    {'name': 'Tanzania', 'code': '255'},
    {'name': 'Thailand', 'code': '66'},
    {'name': 'Togo', 'code': '228'},
    {'name': 'Tonga', 'code': '676'},
    {'name': 'Tunisia', 'code': '216'},
    {'name': 'Turkey', 'code': '90'},
    {'name': 'Turkmenistan', 'code': '993'},
    {'name': 'Tuvalu', 'code': '688'},
    {'name': 'Uganda', 'code': '256'},
    {'name': 'Ukraine', 'code': '380'},
    {'name': 'United Arab Emirates', 'code': '971'},
    {'name': 'United Kingdom', 'code': '44'},
    {'name': 'United States', 'code': '1'},
    {'name': 'Uruguay', 'code': '598'},
    {'name': 'Uzbekistan', 'code': '998'},
    {'name': 'Vanuatu', 'code': '678'},
    {'name': 'Vatican', 'code': '379'},
    {'name': 'Venezuela', 'code': '58'},
    {'name': 'Vietnam', 'code': '84'},
    {'name': 'Yemen', 'code': '967'},
    {'name': 'Zambia', 'code': '260'},
    {'name': 'Zimbabwe', 'code': '263'},
  ];

  List<Map<String, String>> filteredCountries = [];
  TextEditingController countrySearchController = TextEditingController();

  // Place suggestions
  List<Prediction> placeSuggestions = [];
  Timer? _debounce;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    placeOfBirthController.dispose();
    referralCodeController.dispose();
    otpController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> sendOtp() async {
    setState(() {
      isVerifyingOtp = false;
      isOtpSent = false;
      otpValidationMessage = null;
    });
    final phone = phoneController.text.trim();
    final fullPhone = selectedCountryCode + phone;
    final url = Uri.parse('$api/verify_whatsapp_send_otp');
    final response = await http.post(url,
        body: json.encode({"whatsapp_no": fullPhone}),
        headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      setState(() {
        isOtpSent = true;
        otpValidationMessage = "OTP sent! Please enter the PIN.";
      });
    } else {
      setState(() {
        otpValidationMessage = "Failed to send OTP. Try again.";
      });
    }
  }

  Future<void> verifyOtp() async {
    setState(() {
      isVerifyingOtp = true;
      otpValidationMessage = null;
    });
    final phone = phoneController.text.trim();
    final fullPhone = selectedCountryCode + phone;
    final url = Uri.parse('$api/verify_whatsapp_otp');
    final response = await http.post(url,
        body: json.encode(
            {"whatsapp_no": fullPhone, "otp": otpController.text.trim()}),
        headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['is_verified'] == true) {
        setState(() {
          isNumberVerified = true;
          isVerifyingOtp = false;
          otpValidationMessage = "Number verified!";
        });
      } else {
        setState(() {
          otpValidationMessage = "Incorrect OTP. Try again.";
        });
      }
    } else {
      setState(() {
        otpValidationMessage = "Failed to verify. Try again.";
      });
    }
  }

  Future<void> _checkEmailExists(String email) async {
    if (email.trim().isEmpty || !_isValidEmail(email.trim())) {
      setState(() {
        isCheckingEmail = false;
        emailValidationMessage = null;
        isEmailValid = true;
      });
      return;
    }

    setState(() {
      isCheckingEmail = true;
      emailValidationMessage = null;
    });

    try {
      final url = Uri.parse('$api/check_user_email/${email.trim()}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'exists') {
          setState(() {
            emailValidationMessage = 'Email is already registered';
            isEmailValid = false;
          });
        } else {
          setState(() {
            emailValidationMessage = null;
            isEmailValid = true;
          });
        }
      }
    } catch (e) {
      //print('Error checking email: $e');
      setState(() {
        emailValidationMessage = 'Error checking email availability';
        isEmailValid = false;
      });
    } finally {
      setState(() {
        isCheckingEmail = false;
      });
    }
  }

  Future<void> _checkPhoneExists(String phone) async {
    if (phone.trim().isEmpty) {
      setState(() {
        isCheckingPhone = false;
        phoneValidationMessage = null;
        isPhoneValid = true;
      });
      return;
    }

    setState(() {
      isCheckingPhone = true;
      phoneValidationMessage = null;
    });

    try {
      // Use dynamic country code instead of hardcoded 91
      final url = Uri.parse('$api/check_ph_no/$selectedCountryCode/$phone');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'exists') {
          setState(() {
            phoneValidationMessage = 'Phone number is already registered';
            isPhoneValid = false;
          });
        } else {
          setState(() {
            phoneValidationMessage = null;
            isPhoneValid = true;
          });
        }
      }
    } catch (e) {
      setState(() {
        phoneValidationMessage = 'Error checking phone availability';
        isPhoneValid = false;
      });
    } finally {
      setState(() {
        isCheckingPhone = false;
      });
    }
  }

  Future<void> moveToNextStep() async {
    if (currentStep < 8) {
      switch (currentStep) {
        case 0:
          name = nameController.text.trim();
          break;
        case 1:
          // Validate phone with API before moving to next step
          phone = phoneController.text.trim();
          if (phone != null && phone!.isNotEmpty) {
            // Show loading state
            setState(() {
              isCheckingPhone = true;
            });

            await _checkPhoneExists(phone!);

            setState(() {
              isCheckingPhone = false;
            });

            if (!isPhoneValid) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    phoneValidationMessage ?? 'Phone number already exists',
                  ),
                ),
              );
              return;
            }
          }
          break;
        case 2:
          // Validate email with API before moving to next step
          String trimmedEmail = emailController.text.trim();
          if (trimmedEmail.isNotEmpty) {
            if (!_isValidEmail(trimmedEmail)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please enter a valid email address')),
              );
              return;
            }

            // Show loading state
            setState(() {
              isCheckingEmail = true;
            });

            await _checkEmailExists(trimmedEmail);

            setState(() {
              isCheckingEmail = false;
            });

            if (!isEmailValid) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    emailValidationMessage ?? 'Email already exists',
                  ),
                ),
              );
              return;
            }
          }
          email = trimmedEmail;
          break;
        case 3:
          password = passwordController.text;
          break;
        case 4:
          gender = selectedGender;
          break;
        case 5:
          if (selectedDate != null) {
            dateOfBirth =
                '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}';
          }
          break;
        case 6:
          placeOfBirth = placeOfBirthController.text.trim();
          if (placeOfBirth != null && placeOfBirth!.isNotEmpty) {
            _geocodeManualPlace(placeOfBirth!);
          }
          break;
        case 7:
          birthTime = selectedTime;
          break;
        case 8:
          referralCode = referralCodeController.text.trim();
          break;
      }

      setState(() {
        currentStep++;
        isTextFieldFilled = _isCurrentStepFilled();

        if (currentStep == 0)
          nameController.clear();
        else if (currentStep == 1)
          phoneController.clear();
        else if (currentStep == 2)
          emailController.clear();
        else if (currentStep == 3)
          passwordController.clear();
        else if (currentStep == 6)
          placeOfBirthController.clear();
        else if (currentStep == 7)
          selectedTime = null;
        else if (currentStep == 8) referralCodeController.clear();
      });
    } else {
      _sendPostRequest();
    }
  }

  bool _isCurrentStepFilled() {
    switch (currentStep) {
      case 0:
        return nameController.text.trim().isNotEmpty;
      case 1:
        return phoneController.text.trim().isNotEmpty;
      case 2:
        String trimmedEmail = emailController.text.trim();
        if (trimmedEmail.isEmpty) return true;
        return _isValidEmail(trimmedEmail);
      case 3:
        return true;
      case 4:
        return true;
      case 5:
        return true;
      case 6:
        return true;
      case 7:
        return true;
      case 8:
        return true;
      default:
        return true;
    }
  }

  Future<void> _sendPostRequest() async {
    setState(() {
      isLoading = true;
    });
    final url = Uri.parse('$api/users');
    final headers = {"Content-Type": "application/json"};

    // Format dateOfBirth to yyyy-mm-dd
    String formattedDoB = '';
    if (selectedDate != null) {
      formattedDoB =
          '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
    }

    // Format birthTime to HH:mm (24-hour format)
    String formattedToB = '';
    if (selectedTime != null) {
      final timeParts = selectedTime!.split(' ');
      final time = timeParts[0];
      final period = timeParts[1];
      final timeSplit = time.split(':');
      int hour = int.parse(timeSplit[0]);
      final minute = timeSplit[1];

      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      formattedToB = '${hour.toString().padLeft(2, '0')}:$minute';
    }

    // Use trimmed email for API
    String? emailToUse = email?.trim();
    if ((emailToUse == null || emailToUse.isEmpty) &&
        phone != null &&
        phone!.isNotEmpty) {
      emailToUse = '$selectedCountryCode$phone@email.com';
    }

    // Combine country code with phone number
    String fullPhoneNumber = '$selectedCountryCode$phone';

    // Build request body with timezone handling
    Map<String, dynamic> requestBodyMap = {
      "username": emailToUse,
      "password": password ?? '',
      "full_name": name ?? '',
      "gender": gender ?? '',
      "email": emailToUse,
      "DoB": formattedDoB,
      "ToB": formattedToB,
      "PoB": placeOfBirth ?? '',
      "mob": fullPhoneNumber,
      "wa": fullPhoneNumber,
      "referral_code": referralCode ?? '',
    };

    // Always include coordinates and timezone
    requestBodyMap["lat"] = lat ?? 0.0;
    requestBodyMap["long"] = long ?? 0.0;
    requestBodyMap["timezone"] = timezone ?? 0.0;

    final requestBody = json.encode(requestBodyMap);

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: requestBody,
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Please login")));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else if (response.statusCode == 409) {
        final jsonData = jsonDecode(response.body);
        final message = jsonData['message'] ?? "User already registered";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      } else if (response.statusCode == 429) {
        // Handle 429 Too Many Requests
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text("Too Many Request-Please try after sometime"),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Invalid Details")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error during signup: $e")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onPlaceInputChanged(String input) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (input.trim().isEmpty) {
        // Clear everything when place is empty
        setState(() {
          placeSuggestions = [];
          lat = null;
          long = null;
          timezone = null;
          isTextFieldFilled = true;
        });
      } else if (input.length > 2) {
        _getPlaceSuggestions(input);
      } else {
        setState(() {
          placeSuggestions = [];
          isTextFieldFilled = true;
        });
      }
    });
  }

  // Add this new method to geocode manually typed places
  Future<void> _geocodeManualPlace(String placeName) async {
    if (placeName.trim().isEmpty) return;

    try {
      // Use Google Places Text Search API to get coordinates for manually typed place
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json?query=${Uri.encodeComponent(placeName)}&key=$gapi2',
      );

      //print('Geocoding API URL: $url'); // Debug log

      final response = await http.get(url);

      //print('Geocoding API Response Status: ${response.statusCode}'); // Debug log
      //print('Geocoding API Response Body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'OK' && jsonData['results'].isNotEmpty) {
          final result = jsonData['results'][0];
          final location = result['geometry']['location'];

          final newLat = location['lat'].toDouble();
          final newLng = location['lng'].toDouble();

          setState(() {
            lat = newLat;
            long = newLng;
          });

          //print('Geocoded coordinates: lat=$lat, long=$long');

          // Get timezone for this location
          await _getTimezone(newLat, newLng);

          //print('Geocoded manually typed place: $placeName');
          //print('Final coordinates: lat=$lat, long=$long, timezone=$timezone');
        } else {
          //print('No results found for manually typed place: $placeName');
          //print('API Status: ${jsonData['status']}');
          setState(() {
            lat = null;
            long = null;
            timezone = null;
          });
        }
      } else {
        //print('HTTP Error in geocoding: ${response.statusCode}');
        setState(() {
          lat = null;
          long = null;
          timezone = null;
        });
      }
    } catch (e) {
      //print('Error geocoding manually typed place: $e');
      setState(() {
        lat = null;
        long = null;
        timezone = null;
      });
    }
  }

  Future<void> _getPlaceSuggestions(String input) async {
    try {
      // Removed country restriction to allow worldwide places
      final response = await places.autocomplete(
        input,
        types: ['(cities)'],
        // Removed: components: [Component(Component.country, 'in')],
      );

      if (response.status == 'OK' && response.predictions.isNotEmpty) {
        setState(() {
          placeSuggestions = response.predictions;
        });
      } else {
        setState(() {
          placeSuggestions = [];
        });
      }
    } catch (e) {
      //print('Error getting place suggestions: $e');
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    try {
      final response = await places.getDetailsByPlaceId(placeId);

      //print('Place Details Response Status: ${response.status}'); // Debug log

      if (response.status == 'OK' && response.result.geometry != null) {
        final location = response.result.geometry!.location;

        setState(() {
          placeOfBirth = response.result.formattedAddress;
          placeOfBirthController.text = placeOfBirth ?? '';
          lat = location.lat;
          long = location.lng;
          isTextFieldFilled = true;
        });

        //print('Selected place coordinates: lat=${location.lat}, long=${location.lng}');

        // Always fetch timezone when place is selected
        await _getTimezone(location.lat, location.lng);

        //print('Place selection complete: lat=$lat, long=$long, timezone=$timezone');
      } else {
        //print('Error in place details: ${response.status}');
        setState(() {
          placeSuggestions = [];
        });
      }
    } catch (e) {
      //print('Error getting place details: $e');
      setState(() {
        placeSuggestions = [];
      });
    }
  }

  Future<void> _getTimezone(double lat, double lng) async {
    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/timezone/json?location=$lat,$lng&timestamp=$timestamp&key=$gapi2',
      ); // Changed from gapi to gapi2

      //print('Timezone API URL: $url'); // Debug log

      final response = await http.get(url);

      //print('Timezone API Response Status: ${response.statusCode}'); // Debug log
      //print('Timezone API Response Body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        //print('Parsed JSON Data: $jsonData'); // Debug log

        if (jsonData['status'] == 'OK') {
          final rawOffset = jsonData['rawOffset'] as int;
          final dstOffset = jsonData['dstOffset'] as int;
          final offsetHours = (rawOffset + dstOffset) / 3600;

          setState(() {
            timezone = offsetHours;
          });

          //print('Successfully set timezone: $timezone hours'); // Debug log
        } else {
          //print('Timezone API Error Status: ${jsonData['status']}');
          //print('Error Message: ${jsonData['error_message'] ?? 'No error message'}');

          // Set a default timezone or handle the error appropriately
          setState(() {
            timezone = 0.0; // or calculate based on coordinates if needed
          });
        }
      } else {
        //print('HTTP Error: ${response.statusCode}');
        setState(() {
          timezone = 0.0;
        });
      }
    } catch (e) {
      //print('Error getting timezone: $e');
      setState(() {
        timezone = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(color: Color(0xFFFCF7EF))),
          Positioned.fill(
            child: Image.asset(
              'assets/images/getstartedBG.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back),
                            onPressed: () {
                              if (currentStep > 0) {
                                setState(() {
                                  currentStep--;
                                  switch (currentStep) {
                                    case 0:
                                      nameController.text = name ?? '';
                                      isTextFieldFilled =
                                          name != null && name!.isNotEmpty;
                                      break;
                                    case 1:
                                      phoneController.text = phone ?? '';
                                      isTextFieldFilled =
                                          phone != null && phone!.length == 10;
                                      break;
                                    case 2:
                                      emailController.text = email ?? '';
                                      isTextFieldFilled = email != null &&
                                          email!.trim().isNotEmpty &&
                                          _isValidEmail(email!.trim());
                                      break;
                                    case 3:
                                      passwordController.text = password ?? '';
                                      isTextFieldFilled = true;
                                      break;
                                    case 4:
                                      isTextFieldFilled = true;
                                      break;
                                    case 5:
                                      isTextFieldFilled = true;
                                      break;
                                    case 6:
                                      placeOfBirthController.text =
                                          placeOfBirth ?? '';
                                      isTextFieldFilled = true;
                                      break;
                                    case 7:
                                      selectedTime = birthTime;
                                      isTextFieldFilled = true;
                                      break;
                                    case 8:
                                      referralCodeController.text =
                                          referralCode ?? '';
                                      isTextFieldFilled = true;
                                      break;
                                  }
                                });
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            color: Colors.black,
                          ),
                          Text(
                            'Enter your details',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      if (currentStep >= 2 && currentStep != 8)
                        TextButton(
                          onPressed: moveToNextStep,
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Stack(
                  children: [
                    Container(height: 2, color: Colors.grey[200]),
                    Container(
                      height: 2,
                      width: MediaQuery.of(context).size.width *
                          (currentStep + 1) /
                          9,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF89216B), Color(0xFFDA4453)],
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: currentStep == 0
                          ? buildNameStep()
                          : currentStep == 1
                              ? buildNumberStep()
                              : currentStep == 2
                                  ? buildEmailStep()
                                  : currentStep == 3
                                      ? buildPasswordStep()
                                      : currentStep == 4
                                          ? buildGenderStep()
                                          : currentStep == 5
                                              ? buildBirthdayStep()
                                              : currentStep == 6
                                                  ? buildBirthplaceStep()
                                                  : currentStep == 7
                                                      ? buildBirthTimeStep()
                                                      : buildReferralCodeStep(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isTextFieldFilled
                          ? LinearGradient(
                              colors: [Color(0xFF89216B), Color(0xFFDA4453)],
                            )
                          : null,
                      color: isTextFieldFilled ? null : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: isTextFieldFilled
                          ? () {
                              moveToNextStep();
                            }
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Save and Next',
                            style: TextStyle(
                              color: isTextFieldFilled
                                  ? Colors.white
                                  : Colors.black54,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            color: isTextFieldFilled
                                ? Colors.white
                                : Colors.black54,
                          ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.background,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/images/signup/name.png', width: 72, height: 72),
            SizedBox(height: 8),
            Text(
              'What is your name?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'e.g. Suvra Shaw',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
          ),
          onChanged: (value) {
            setState(() {
              name = value.trim();
              isTextFieldFilled = value.trim().isNotEmpty;
            });
          },
        ),
      ],
    );
  }

  Widget buildNumberStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset('assets/images/signup/name.png', width: 72, height: 72),
        SizedBox(height: 8),
        Text(
          "What is your phone number?",
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(height: 24),
        Row(
          children: [
            Container(
              height: 56,
              width: 96,
              child: GestureDetector(
                onTap: () => _showCountryPicker(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(selectedCountryCode,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black)),
                            Text(selectedCountryName,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  hintText: "Enter phone number",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red)),
                  errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red)),
                  focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red)),
                  errorStyle: TextStyle(color: Colors.red, fontSize: 14),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return "Please enter your phone number";
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (value) {
                  setState(() {
                    phone = value.trim();
                    phoneValidationMessage = null;
                    isPhoneValid = true;
                    isTextFieldFilled = value.trim().isNotEmpty;
                  });
                },
                enabled: !isNumberVerified,
              ),
            ),
          ],
        ),
        if (phoneValidationMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(phoneValidationMessage!,
                style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16.0),
          decoration: BoxDecoration(
            color: isOtpSent ? Colors.green[50] : Colors.orange[50],
            border: Border.all(
              color: isOtpSent ? Colors.green : Colors.orange,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isOtpSent ? Icons.check_circle_outline : Icons.info_outline,
                color: isOtpSent ? Colors.green : Colors.orange,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  isOtpSent
                      ? otpValidationMessage != null
                          ? otpValidationMessage!
                          : "please wait"
                      : "verify whatsapp number to get first free chat/Special offers",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isOtpSent ? Colors.green[800] : Colors.orange[800],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        // Custom Verify Button Style
        if (!isNumberVerified && !isOtpSent)
          Padding(
            padding: const EdgeInsets.all(0),
            child: Container(
              decoration: BoxDecoration(
                gradient: isTextFieldFilled
                    ? LinearGradient(
                        colors: [Color(0xFF89216B), Color(0xFFDA4453)],
                      )
                    : null,
                color: isTextFieldFilled ? null : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: sendOtp,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Verify',
                      style: TextStyle(
                        color:
                            isTextFieldFilled ? Colors.white : Colors.black54,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.check_circle,
                      color: isTextFieldFilled ? Colors.white : Colors.black54,
                    ),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        if (isOtpSent && !isNumberVerified)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Center(
                child: Pinput(
                  controller: otpController,
                  length: 4,
                  mainAxisAlignment: MainAxisAlignment.center,
                  defaultPinTheme: PinTheme(
                    width: 56,
                    height: 56,
                    textStyle: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  focusedPinTheme: PinTheme(
                    width: 56,
                    height: 56,
                    textStyle: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  submittedPinTheme: PinTheme(
                    width: 56,
                    height: 56,
                    textStyle: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  errorPinTheme: PinTheme(
                    width: 56,
                    height: 56,
                    textStyle: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onCompleted: (pin) {
                    verifyOtp();
                  },
                  enabled: !isVerifyingOtp,
                ),
              ),
              SizedBox(height: 12),
              // Custom Proceed Button Style
              Padding(
                padding: const EdgeInsets.all(0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: !isVerifyingOtp
                        ? LinearGradient(
                            colors: [Color(0xFF89216B), Color(0xFFDA4453)],
                          )
                        : null,
                    color: isVerifyingOtp ? Colors.grey[300] : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: isVerifyingOtp ? null : verifyOtp,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Proceed",
                          style: TextStyle(
                            color:
                                !isVerifyingOtp ? Colors.white : Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color:
                              !isVerifyingOtp ? Colors.white : Colors.black54,
                        ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: sendOtp,
                    child: Text(
                      "Resend OTP",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[900],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isOtpSent = false;
                        otpController.clear();
                      });
                    },
                    child: Text(
                      "Change Number",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[900],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  void _showCountryPicker(BuildContext context) {
    // Initialize filtered countries
    filteredCountries = List.from(countries);
    countrySearchController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Country',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  // Search field
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: countrySearchController,
                      decoration: InputDecoration(
                        hintText: 'Search country...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFFDA4453)),
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          if (value.isEmpty) {
                            filteredCountries = List.from(countries);
                          } else {
                            filteredCountries = countries
                                .where(
                                  (country) =>
                                      country['name']!.toLowerCase().contains(
                                            value.toLowerCase(),
                                          ) ||
                                      country['code']!.contains(value),
                                )
                                .toList();
                          }
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  // Countries list
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = filteredCountries[index];
                        final isSelected =
                            selectedCountryCode == country['code'];

                        return ListTile(
                          onTap: () {
                            setState(() {
                              selectedCountryCode = country['code']!;
                              selectedCountryName = country['name']!;
                              // Reset validation state when country code changes
                              phoneValidationMessage = null;
                              isPhoneValid = true;
                            });
                            Navigator.pop(context);
                          },
                          leading: Container(
                            width: 50,
                            height: 30,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(0xFFDA4453).withOpacity(0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? Color(0xFFDA4453)
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '+${country['code']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Color(0xFFDA4453)
                                      : Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            country['name']!,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color:
                                  isSelected ? Color(0xFFDA4453) : Colors.black,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: Color(0xFFDA4453),
                                  size: 20,
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/images/signup/name.png', width: 72, height: 72),
            SizedBox(height: 8),
            Text(
              'What is your email?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            // Only show basic validation errors, not the API validation errors
            if (value == null || value.trim().isEmpty) {
              return null;
            }
            String trimmedValue = value.trim();
            if (!_isValidEmail(trimmedValue)) {
              return 'Please enter a valid email address';
            }
            // Don't return emailValidationMessage here - it's handled separately
            return null;
          },
          decoration: InputDecoration(
            hintText: 'e.g., example@domain.com',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
            errorStyle: TextStyle(color: Colors.red, fontSize: 14),
          ),
          onChanged: (value) {
            setState(() {
              String trimmedValue = value.trim();
              email = trimmedValue;
              emailValidationMessage = null;
              isEmailValid = true;
              isTextFieldFilled =
                  trimmedValue.isEmpty || _isValidEmail(trimmedValue);
            });
          },
        ),
        // Only show this custom error message, not the validator one
        if (emailValidationMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              emailValidationMessage!,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  bool _isValidEmail(String email) {
    String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(email);
  }

  Widget buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/images/signup/name.png', width: 72, height: 72),
            SizedBox(height: 8),
            Text(
              'Create a password',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        TextFormField(
          controller: passwordController,
          obscureText: _obscureText,
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
            errorStyle: TextStyle(color: Colors.red, fontSize: 14),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return null; // Password is optional, no error for empty
            }
            return null;
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (value) {
            setState(() {
              password = value;
              isTextFieldFilled = true; // Password is optional
            });
          },
        ),
      ],
    );
  }

  Widget buildGenderStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/signup/gender.png',
              width: 72,
              height: 72,
            ),
            SizedBox(height: 8),
            Text(
              'What is your gender?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildGenderOption('male', 'assets/images/signup/male.png'),
            _buildGenderOption('female', 'assets/images/signup/female.png'),
            _buildGenderOption('other', 'assets/images/signup/other.png'),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String gender, String iconPath) {
    bool isSelected = selectedGender == gender;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGender = gender;
          isTextFieldFilled = true;
        });
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: isSelected
              ? Color.fromARGB(255, 255, 235, 238)
              : const Color.fromARGB(0, 255, 255, 255),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFFDA4453) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: FittedBox(fit: BoxFit.contain, child: Image.asset(iconPath)),
        ),
      ),
    );
  }

  Widget buildBirthplaceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/signup/birthplace.png',
              width: 72,
              height: 72,
            ),
            SizedBox(height: 8),
            Text(
              'What is your Birthplace?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        TextFormField(
          controller: placeOfBirthController,
          decoration: InputDecoration(
            hintText: 'e.g., New York, NY, USA',
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
            // Add a clear button when text is present
            suffixIcon: placeOfBirthController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[600]),
                    onPressed: () {
                      placeOfBirthController.clear();
                      setState(() {
                        placeOfBirth = '';
                        placeSuggestions = [];
                        lat = null;
                        long = null;
                        timezone = null; // Clear timezone when place is cleared
                        isTextFieldFilled = true;
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            _onPlaceInputChanged(value);

            setState(() {
              placeOfBirth = value.trim();
            });
          },
        ),
        if (placeSuggestions.isNotEmpty)
          Container(
            constraints: BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            margin: EdgeInsets.only(top: 8),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: placeSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = placeSuggestions[index];
                return ListTile(
                  title: Text(suggestion.description ?? ''),
                  onTap: () {
                    setState(() {
                      placeSuggestions = [];
                    });
                    _getPlaceDetails(suggestion.placeId!);
                  },
                );
              },
            ),
          ),
        // Optional: Show timezone info when available
        if (timezone != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFFDA4453).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(0xFFDA4453).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 16, color: Color(0xFFDA4453)),
                  SizedBox(width: 4),
                  Text(
                    'Timezone: UTC${timezone! >= 0 ? '+' : ''}${timezone!.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFDA4453),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget buildBirthdayStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/signup/birthday.png',
              width: 72,
              height: 72,
            ),
            SizedBox(height: 8),
            Text(
              'What is your Birthday?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            selectedDate != null
                ? '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}'
                : 'Select date',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        SizedBox(height: 24),
        EnhancedDatePicker(
          onDateSelected: (date) {
            setState(() {
              selectedDate = date;
              isTextFieldFilled = true;
            });
          },
        ),
      ],
    );
  }

  Widget buildBirthTimeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/signup/birthtime.png',
              width: 72,
              height: 72,
            ),
            SizedBox(height: 8),
            Text(
              'What is your Birthtime?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            selectedTime ?? 'Select time',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        SizedBox(height: 24),
        EnhancedTimePicker(
          onTimeSelected: (time, isValid) {
            setState(() {
              selectedTime = time;
              isTextFieldFilled = isValid;
            });
          },
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget buildReferralCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/signup/referral.png',
              width: 72,
              height: 72,
            ),
            SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unlock Rewards with a Referral Code!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '(if any)',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 24),
        TextFormField(
          controller: referralCodeController,
          decoration: InputDecoration(
            hintText: 'Enter 10 digit referral code',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
          ),
          onChanged: (value) {
            setState(() {
              referralCode = value.trim();
              isTextFieldFilled = true;
            });
          },
        ),
      ],
    );
  }
}

// Enhanced Date Picker with professional styling
class EnhancedDatePicker extends StatefulWidget {
  final Function(DateTime) onDateSelected;

  const EnhancedDatePicker({Key? key, required this.onDateSelected})
      : super(key: key);

  @override
  _EnhancedDatePickerState createState() => _EnhancedDatePickerState();
}

class _EnhancedDatePickerState extends State<EnhancedDatePicker> {
  late FixedExtentScrollController monthController;
  late FixedExtentScrollController yearController;
  late FixedExtentScrollController dayController;

  int selectedDay = DateTime.now().day;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    monthController = FixedExtentScrollController(
      initialItem: selectedMonth - 1,
    );
    yearController = FixedExtentScrollController(
      initialItem: selectedYear - 1900,
    );
    dayController = FixedExtentScrollController(initialItem: selectedDay - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          // Day Picker
          Expanded(
            child: Column(
              children: [
                Text(
                  'Day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: dayController,
                    itemExtent: 50,
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    physics: FixedExtentScrollPhysics(),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 31,
                      builder: (context, index) {
                        bool isSelected = selectedDay == index + 1;
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(0xFFDA4453).withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: isSelected ? 22 : 18,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Color(0xFFDA4453)
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedDay = index + 1;
                      });
                      updateSelectedDate();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Month Picker
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  'Month',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: monthController,
                    itemExtent: 50,
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    physics: FixedExtentScrollPhysics(),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 12,
                      builder: (context, index) {
                        bool isSelected = selectedMonth == index + 1;
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(0xFFDA4453).withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              months[index],
                              style: TextStyle(
                                fontSize: isSelected ? 18 : 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Color(0xFFDA4453)
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedMonth = index + 1;
                      });
                      updateSelectedDate();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Year Picker
          Expanded(
            child: Column(
              children: [
                Text(
                  'Year',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: yearController,
                    itemExtent: 50,
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    physics: FixedExtentScrollPhysics(),
                    childDelegate: ListWheelChildBuilderDelegate(
                      // Only allow years up to today
                      childCount: DateTime.now().year - 1900 + 1,
                      builder: (context, index) {
                        int year = 1900 + index;
                        bool isSelected = selectedYear == year;
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(0xFFDA4453).withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '$year',
                              style: TextStyle(
                                fontSize: isSelected ? 22 : 18,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Color(0xFFDA4453)
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedYear = 1900 + index;
                      });
                      updateSelectedDate();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void updateSelectedDate() {
    final selectedDate = DateTime(selectedYear, selectedMonth, selectedDay);
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    // Only allow past dates, not present or future
    if (selectedDate.isBefore(todayDateOnly)) {
      widget.onDateSelected(selectedDate);
    } else {
      // If selected date is today or in the future, reset to yesterday or closest past date
      final yesterday = todayDateOnly.subtract(Duration(days: 1));
      setState(() {
        selectedDay = yesterday.day;
        selectedMonth = yesterday.month;
        selectedYear = yesterday.year;
      });
      widget.onDateSelected(yesterday);
    }
  }

  @override
  void dispose() {
    monthController.dispose();
    yearController.dispose();
    dayController.dispose();
    super.dispose();
  }
}

// Enhanced Time Picker with professional styling
class EnhancedTimePicker extends StatefulWidget {
  final Function(String, bool) onTimeSelected;

  const EnhancedTimePicker({Key? key, required this.onTimeSelected})
      : super(key: key);

  @override
  _EnhancedTimePickerState createState() => _EnhancedTimePickerState();
}

class _EnhancedTimePickerState extends State<EnhancedTimePicker> {
  late FixedExtentScrollController hourController;
  late FixedExtentScrollController minuteController;
  late FixedExtentScrollController periodController;

  int selectedHour = 12;
  int selectedMinute = 0;
  int selectedPeriod = 0; // 0 for AM, 1 for PM

  @override
  void initState() {
    super.initState();
    hourController = FixedExtentScrollController(initialItem: selectedHour - 1);
    minuteController = FixedExtentScrollController(initialItem: selectedMinute);
    periodController = FixedExtentScrollController(initialItem: selectedPeriod);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hour Picker
          Expanded(
            child: Column(
              children: [
                Text(
                  'Hour',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: hourController,
                    itemExtent: 50,
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    physics: FixedExtentScrollPhysics(),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 12,
                      builder: (context, index) {
                        int hour = index + 1;
                        bool isSelected = selectedHour == hour;
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(0xFFDA4453).withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '$hour',
                              style: TextStyle(
                                fontSize: isSelected ? 22 : 18,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Color(0xFFDA4453)
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedHour = index + 1;
                      });
                      updateSelectedTime();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Separator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              ':',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFDA4453),
              ),
            ),
          ),

          // Minute Picker
          Expanded(
            child: Column(
              children: [
                Text(
                  'Minute',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: minuteController,
                    itemExtent: 50,
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    physics: FixedExtentScrollPhysics(),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 60,
                      builder: (context, index) {
                        bool isSelected = selectedMinute == index;
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(0xFFDA4453).withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: isSelected ? 22 : 18,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Color(0xFFDA4453)
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedMinute = index;
                      });
                      updateSelectedTime();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Period Picker (AM/PM)
          Expanded(
            child: Column(
              children: [
                Text(
                  'Period',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: periodController,
                    itemExtent: 50,
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    physics: FixedExtentScrollPhysics(),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 2,
                      builder: (context, index) {
                        String period = index == 0 ? 'AM' : 'PM';
                        bool isSelected = selectedPeriod == index;
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(0xFFDA4453).withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              period,
                              style: TextStyle(
                                fontSize: isSelected ? 22 : 18,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Color(0xFFDA4453)
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedPeriod = index;
                      });
                      updateSelectedTime();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void updateSelectedTime() {
    final period = selectedPeriod == 0 ? 'AM' : 'PM';
    final timeString =
        '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')} $period';
    widget.onTimeSelected(timeString, true);
  }

  @override
  void dispose() {
    hourController.dispose();
    minuteController.dispose();
    periodController.dispose();
    super.dispose();
  }
}
