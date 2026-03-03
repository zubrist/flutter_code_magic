import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saamay/pages/HomeScreen.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar2.dart';
import 'package:saamay/pages/config.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'dart:async';
import 'package:pinput/pinput.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({Key? key}) : super(key: key);

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  bool isVerifyingOtp = false;
  bool isOtpSent = false;
  bool isNumberVerified = false;
  String? otpValidationMessage;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _whatsappVerified = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: gapi2);
  Timer? _debounce;
  List<Prediction> _placeSuggestions = [];
  double? _lat;
  double? _long;
  double? _timezone;
  String selectedCountryCode = '91';
  String selectedCountryName = 'India';
  String selectedWhatsAppCountryCode = '91'; // Separate for WhatsApp
  String selectedWhatsAppCountryName = 'India';
  List<Map<String, String>> filteredCountries = [];
  TextEditingController countrySearchController = TextEditingController();

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

  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _tobController = TextEditingController();
  final TextEditingController _pobController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _gender;
  String _profilePicture = '';
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$api/user/own'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = json.decode(response.body);

        if (userData.isNotEmpty) {
          final user = userData['data'];

          setState(() {
            _userId = user['user_id'];
            _nameController.text = user['user_fullname'] ?? "";
            _addressController.text = user['user_address'] ?? "";
            _dobController.text = user['user_DoB'] ?? "";
            _tobController.text = user['user_ToB'] ?? "";
            _pobController.text = user['user_PoB'] ?? "";
            _whatsappVerified = userData['whatsapp_verified'] ?? false;
            //_whatsappVerified = false;

            // Handle mobile number with dynamic country code detection
            String mobileNumber = user['user_mob'] ?? "";
            if (mobileNumber.isNotEmpty) {
              // Try to detect country code from stored number
              String detectedCode = _extractCountryCode(mobileNumber);
              selectedCountryCode = detectedCode;
              selectedCountryName = _getCountryNameByCode(detectedCode);

              // Remove the detected country code from display
              if (mobileNumber.startsWith(detectedCode)) {
                _mobileController.text = mobileNumber.substring(
                  detectedCode.length,
                );
              } else {
                _mobileController.text = mobileNumber;
              }
            }

            _districtController.text = user['user_district'] ?? "";
            _stateController.text = user['user_state'] ?? "";
            _zipController.text = user['user_zip'] ?? "";

            // Handle gender with proper null checking
            String? apiGender = user['user_gender'];
            if (apiGender != null && apiGender.isNotEmpty) {
              apiGender = apiGender.toLowerCase().trim();
              if (['male', 'female', 'other'].contains(apiGender)) {
                _gender = apiGender;
              } else {
                _gender = null;
              }
            } else {
              _gender = null;
            }

            _emailController.text = user['user_email'] ?? "";
            _profilePicture = user['user_profile_picture'] ?? "";

            // Load existing coordinates and timezone if available
            _lat = user['lat'] != null
                ? double.tryParse(user['lat'].toString())
                : null;
            _long = user['long'] != null
                ? double.tryParse(user['long'].toString())
                : null;
            _timezone = user['timezone'] != null
                ? double.tryParse(user['timezone'].toString())
                : 5.5;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load profile data. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while loading data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _extractCountryCode(String phoneNumber) {
    // Sort countries by code length (longest first) to match properly
    List<String> codes = countries.map((c) => c['code']!).toList();
    codes.sort((a, b) => b.length.compareTo(a.length));

    for (String code in codes) {
      if (phoneNumber.startsWith(code)) {
        return code;
      }
    }
    return '91'; // Default to India if no match
  }

  // Helper function to get country name by code
  String _getCountryNameByCode(String code) {
    try {
      return countries.firstWhere(
        (country) => country['code'] == code,
      )['name']!;
    } catch (e) {
      return 'India'; // Default
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_imageFile == null) return;

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$url:8002/s2/FileService/upload'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('files', _imageFile!.path),
      );

      request.fields['file_type'] = 'user_profile_pic';
      request.fields['user_id'] = _userId.toString();

      request.headers.addAll({'Authorization': 'Bearer $token'});

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['status'] == 'success' &&
            responseData['files'] != null &&
            responseData['files'].isNotEmpty) {
          setState(() {
            _profilePicture =
                responseData['files'][0]['file_url'] ?? _profilePicture;
          });
        } else {
          setState(() {
            _errorMessage =
                'Failed to upload profile image: Invalid response format';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to upload profile image. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while uploading image: $e';
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    if (_imageFile != null) {
      await _uploadProfileImage();
    }

    final Map<String, dynamic> payload = {
      "full_name": _nameController.text,
      "address": _addressController.text,
      "DoB": _dobController.text,
      "ToB": _tobController.text,
      "PoB": _pobController.text,
      "mob": _mobileController.text.isNotEmpty
          ? "$selectedCountryCode${_mobileController.text}"
          : "",
      "district": _districtController.text,
      "state": _stateController.text,
      "zip": _zipController.text,
      "gender": _gender ?? "",
      "email": _emailController.text,
      "profile_picture": _profilePicture,
      "lat": _lat,
      "long": _long,
      "timezone": _timezone ?? 0.0,
    };

    try {
      final response = await http.put(
        Uri.parse('$api/users/${_userId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        setState(() {
          _successMessage = 'Profile updated successfully!';
          _isLoading = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to update profile. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();

    if (_dobController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_dobController.text);
      } catch (e) {
        //print('Error parsing date: $e');
        initialDate = DateTime.now();
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
              surface: Colors.white,
              background: Colors.white,
            ),
            scaffoldBackgroundColor: Colors.white,
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay initialTime = TimeOfDay.now();

    if (_tobController.text.isNotEmpty) {
      try {
        String timeText = _tobController.text.toLowerCase();

        if (timeText.contains('am') || timeText.contains('pm')) {
          bool isPM = timeText.contains('pm');
          String cleanTime = timeText.replaceAll(RegExp(r'[ap]m'), '').trim();
          List<String> parts = cleanTime.split(':');

          if (parts.length >= 2) {
            int hour = int.parse(parts[0]);
            int minute = int.parse(parts[1]);

            if (isPM && hour != 12) {
              hour += 12;
            } else if (!isPM && hour == 12) {
              hour = 0;
            }

            initialTime = TimeOfDay(hour: hour, minute: minute);
          }
        } else {
          List<String> parts = timeText.split(':');
          if (parts.length >= 2) {
            int hour = int.parse(parts[0]);
            int minute = int.parse(parts[1]);
            initialTime = TimeOfDay(hour: hour, minute: minute);
          }
        }
      } catch (e) {
        //print('Error parsing time: $e');
        initialTime = TimeOfDay.now();
      }
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
              surface: Colors.white,
              background: Colors.white,
            ),
            scaffoldBackgroundColor: Colors.white,
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _tobController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  void _onPlaceInputChanged(String input) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (input.length > 2) {
        _getPlaceSuggestions(input);
      } else {
        setState(() {
          _placeSuggestions = [];
        });
      }
    });
  }

  Future<void> _getPlaceSuggestions(String input) async {
    try {
      final response = await _places.autocomplete(input, types: ['(cities)']);

      //print('Place suggestions response: ${response.status}, Predictions: ${response.predictions.length}');

      if (response.status == 'OK' && response.predictions.isNotEmpty) {
        setState(() {
          _placeSuggestions = response.predictions;
        });

        for (int i = 0; i < response.predictions.length && i < 3; i++) {
          //print('Suggestion ${i + 1}: ${response.predictions[i].description}');
        }
      } else {
        setState(() {
          _placeSuggestions = [];
        });
        //print('No suggestions found or API error: ${response.status}');
      }
    } catch (e) {
      //print('Error getting place suggestions: $e');
      setState(() {
        _placeSuggestions = [];
      });
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    try {
      //print('Getting details for place ID: $placeId');

      final response = await _places.getDetailsByPlaceId(placeId);
      if (response.status == 'OK' && response.result.geometry != null) {
        final location = response.result.geometry!.location;

        setState(() {
          _pobController.text = response.result.formattedAddress ?? '';
          _lat = location.lat;
          _long = location.lng;
          _placeSuggestions = [];
        });

        //print('Updated coordinates: Lat: ${location.lat}, Lng: ${location.lng}');
        //print('Selected place: ${response.result.formattedAddress}');

        await _getTimezone(location.lat, location.lng);
      } else {
        //print('Place details error: ${response.status}');
      }
    } catch (e) {
      //print('Error getting place details: $e');
    }
  }

  Future<void> _getTimezone(double lat, double lng) async {
    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/timezone/json?location=$lat,$lng&timestamp=$timestamp&key=$gapi2',
      );

      //print('Fetching timezone for coordinates: $lat, $lng');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'OK') {
          final rawOffset = jsonData['rawOffset'] as int;
          final dstOffset = jsonData['dstOffset'] as int;
          final offsetHours = (rawOffset + dstOffset) / 3600;

          setState(() {
            _timezone = offsetHours;
          });

          //print('Timezone details:');
          //print('Raw offset: $rawOffset seconds');
          //print('DST offset: $dstOffset seconds');
          //print('Total offset: $offsetHours hours');
          //print('Timezone ID: ${jsonData['timeZoneId']}');
        } else {
          //print('Timezone API error: ${jsonData['status']} - ${jsonData['errorMessage']}');
          setState(() {
            _timezone = 0.0;
          });
        }
      } else {
        //print('HTTP error getting timezone: ${response.statusCode}');
        setState(() {
          _timezone = 0.0;
        });
      }
    } catch (e) {
      //print('Error getting timezone: $e');
      setState(() {
        _timezone = 0.0;
      });
    }
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFDA4453),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!) as ImageProvider
                    : (_profilePicture.isNotEmpty
                            ? NetworkImage(_profilePicture)
                            : const AssetImage('assets/default_avatar.png'))
                        as ImageProvider,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.camera_alt, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _emailController.text.isNotEmpty ? _emailController.text : 'Email',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.red.shade100,
                  child: Icon(icon, color: Colors.red.shade800),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    Widget? suffix,
    int maxLines = 1,
    void Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          // Special handling for mobile and WhatsApp fields
          if (label == 'Contact Number' || label == 'WhatsApp Number')
            Row(
              children: [
                // Country code picker
                GestureDetector(
                  onTap: () {
                    //_showCountryPicker(context, label == 'WhatsApp Number');
                  },
                  child: Container(
                    height: 56,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '+${label == 'WhatsApp Number' ? selectedWhatsAppCountryCode : selectedCountryCode}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey[600],
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                // Phone number input
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    keyboardType: keyboardType,
                    validator: validator,
                    readOnly: readOnly,
                    maxLines: maxLines,
                    onChanged: onChanged,
                    inputFormatters: inputFormatters,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        borderSide: BorderSide(
                          color: Colors.red.shade300,
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1,
                        ),
                      ),
                      suffixIcon: suffix,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            // Regular text field for other inputs
            TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              readOnly: readOnly,
              maxLines: maxLines,
              onChanged: onChanged,
              inputFormatters: inputFormatters,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade300, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                suffixIcon: suffix,
                prefixIcon: label == 'Place of Birth'
                    ? Icon(Icons.search, color: Colors.grey[600])
                    : null,
                hintText: label == 'Place of Birth'
                    ? 'e.g., New York, USA or London, UK'
                    : null,
                hintStyle: label == 'Place of Birth'
                    ? TextStyle(color: Colors.grey[400])
                    : null,
              ),
            ),
          if (label == 'Place of Birth' && _placeSuggestions.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: _placeSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _placeSuggestions[index];
                  return ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    title: Text(
                      suggestion.description ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      _getPlaceDetails(suggestion.placeId!);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> sendOtp() async {
    setState(() {
      isVerifyingOtp = false;
      isOtpSent = false;
      otpValidationMessage = null;
    });

    final phone = _mobileController.text.trim();
    final fullPhone = selectedCountryCode + phone;
    final url = Uri.parse('$api/verify_whatsapp_send_otp');

    try {
      final response = await http.post(
        url,
        body: json.encode({"whatsapp_no": fullPhone}),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          isOtpSent = true;
          otpValidationMessage = "OTP sent! Please enter the PIN.";
        });
        // Show the OTP dialog
        _showOtpDialog();
      } else {
        setState(() {
          otpValidationMessage = "Failed to send OTP. Try again.";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(otpValidationMessage!)),
        );
      }
    } catch (e) {
      setState(() {
        otpValidationMessage = "Error sending OTP: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(otpValidationMessage!)),
      );
    }
  }
  void _showOtpDialog() {
    otpController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.verified_user, color: Color(0xFFDA4453)),
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
                    '+$selectedCountryCode ${_mobileController.text}',
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
                        border: Border.all(color: Color(0xFFDA4453), width: 2),
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
                        color: Color(0xFFDA4453).withOpacity(0.1),
                        border: Border.all(color: Color(0xFFDA4453)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                    showCursor: true,
                    onCompleted: (pin) {
                      setDialogState(() {
                        isVerifyingOtp = true;
                      });
                      setState(() {
                        isVerifyingOtp = true;
                      });
                      verifyOtp().then((_) {
                        setDialogState(() {});
                      });
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
                        color: Color(0xFFDA4453),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isVerifyingOtp
                      ? null
                      : () {
                    Navigator.of(context).pop();
                    otpController.clear();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isVerifyingOtp || otpController.text.length != 4
                      ? null
                      : () {
                    setDialogState(() {
                      isVerifyingOtp = true;
                    });
                    setState(() {
                      isVerifyingOtp = true;
                    });
                    verifyOtp().then((_) {
                      setDialogState(() {});
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFDA4453),
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

  Future<void> verifyOtp() async {
    setState(() {
      isVerifyingOtp = true;
      otpValidationMessage = null;
    });

    final phone = _mobileController.text.trim();
    final fullPhone = selectedCountryCode + phone;
    final url = Uri.parse('$api/verify_whatsapp_otp');

    try {
      final response = await http.post(
        url,
        body: json.encode({
          "whatsapp_no": fullPhone,
          "otp": otpController.text.trim()
        }),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['is_verified'] == true) {
          setState(() {
            isNumberVerified = true;
            _whatsappVerified = true;
            isVerifyingOtp = false;
            otpValidationMessage = "Number verified!";
          });
          Navigator.of(context).pop(); // Close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Number verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            isVerifyingOtp = false;
            otpValidationMessage = "Incorrect OTP. Try again.";
          });
        }
      } else {
        setState(() {
          isVerifyingOtp = false;
          otpValidationMessage = "Failed to verify. Try again.";
        });
      }
    } catch (e) {
      setState(() {
        isVerifyingOtp = false;
        otpValidationMessage = "Error verifying OTP: $e";
      });
    }
  }

  Widget _buildGenderSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gender',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.red.shade300, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            dropdownColor: Colors.white,
            items: const [
              DropdownMenuItem(
                value: 'male',
                child: Text('Male', style: TextStyle(color: Colors.black)),
              ),
              DropdownMenuItem(
                value: 'female',
                child: Text('Female', style: TextStyle(color: Colors.black)),
              ),
              DropdownMenuItem(
                value: 'other',
                child: Text('Other', style: TextStyle(color: Colors.black)),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _gender = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a gender';
              }
              return null;
            },
            hint: Text(
              'Select Gender',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _tobController.dispose();
    _pobController.dispose();
    _mobileController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _emailController.dispose();
    countrySearchController.dispose();
    otpController.dispose();
    phoneController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _nameController.text.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar2(title: "Edit Profile"),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSectionCard(
                      title: 'Personal Information',
                      icon: Icons.person,
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email address';
                            }
                            if (!RegExp(
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                            ).hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        _buildTextField(
                          controller: _mobileController,
                          label: 'Contact Number',
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            // Removed length restriction
                          ],
                          suffix: _whatsappVerified
                              ? Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 24,
                                )
                              : null,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your contact number';
                            }
                            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                              return 'Contact number must contain only digits';
                            }
                            return null;
                          },
                          readOnly: true,
                        ),
                        if (!_whatsappVerified)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: OutlinedButton(
                              onPressed: () {
                                sendOtp();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Color(0xFFDA4453),
                                side: BorderSide(color: Color(0xFFDA4453)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Verify Phone Number',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        _buildGenderSelector(),
                      ],
                    ),
                    _buildSectionCard(
                      title: 'Birth Details',
                      icon: Icons.cake,
                      children: [
                        _buildTextField(
                          controller: _dobController,
                          label: 'Date of Birth',
                          readOnly: true,
                          suffix: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context),
                          ),
                        ),
                        _buildTextField(
                          controller: _tobController,
                          label: 'Time of Birth',
                          readOnly: true,
                          suffix: IconButton(
                            icon: const Icon(Icons.access_time),
                            onPressed: () => _selectTime(context),
                          ),
                        ),
                        _buildTextField(
                          controller: _pobController,
                          label: 'Place of Birth',
                          onChanged: _onPlaceInputChanged,
                        ),
                      ],
                    ),
                    _buildSectionCard(
                      title: 'Address Information',
                      icon: Icons.location_on,
                      children: [
                        _buildTextField(
                          controller: _addressController,
                          label: 'Address',
                          maxLines: 2,
                        ),
                        _buildTextField(
                          controller: _districtController,
                          label: 'District',
                        ),
                        _buildTextField(
                          controller: _stateController,
                          label: 'State',
                        ),
                        _buildTextField(
                          controller: _zipController,
                          label: 'ZIP Code',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(7),
                          ],
                        ),
                      ],
                    ),
                    // Error message
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),

                    // Success message
                    if (_successMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _successMessage!,
                          style: TextStyle(color: Colors.green.shade800),
                        ),
                      ),

                    // Save button
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: AppColors.button,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
