import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:saamay/pages/HomeScreen.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/config.dart';
import 'dart:convert';
import 'dart:async';
import 'package:saamay/pages/signup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:saamay/pages/forgot_password.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  // Remove this parameter
  // final VoidCallback? onLoginSuccess;

  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final GlobalKey<_OtpVerificationSheetState> _currentOtpSheetKey =
      GlobalKey<_OtpVerificationSheetState>();

  String? _errorMessage;
  bool _isFormValid = false;
  bool _isLoading = false;
  bool _isOtpLogin = false;
  bool _obscurePassword = true;
  bool _isOtpButtonDisabled = false;
  int _otpCountdownSeconds = 0;
  Timer? _otpCountdownTimer;
  bool _shouldNavigate = false;
  Widget? _nextScreen;

  int _failedAttempts = 0;
  bool _isLockedOut = false;
  int _lockoutSeconds = 0;
  Timer? _lockoutTimer;
  bool _requiresEmailChange = false;
  bool _requiresPasswordChange = false;
  bool _requiresMobileChange = false;
  String _lastFailedEmail = '';
  String _lastFailedPassword = '';
  String _lastFailedMobile = '';
  String selectedCountryCode = '91'; // Default to India
  String selectedCountryName = 'India';
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

  @override
  void initState() {
    super.initState();
    _setupFormListeners();
  }

  @override
  void dispose() {
    _cleanupResources();
    super.dispose();
  }

  void _setupFormListeners() {
    _usernameController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _mobileNumberController.addListener(_validateForm);
    _usernameController.addListener(_onEmailChanged);
    _passwordController.addListener(_onPasswordChanged);
    _mobileNumberController.addListener(_onMobileChanged);
  }

  void _cleanupResources() {
    _usernameController.removeListener(_validateForm);
    _passwordController.removeListener(_validateForm);
    _mobileNumberController.removeListener(_validateForm);
    _usernameController.removeListener(_onEmailChanged);
    _passwordController.removeListener(_onPasswordChanged);
    _mobileNumberController.removeListener(_onMobileChanged);
    _usernameController.dispose();
    _passwordController.dispose();
    _mobileNumberController.dispose();
    countrySearchController.dispose(); // Add this line
    _otpCountdownTimer?.cancel();
    _lockoutTimer?.cancel();
  }

  void _onEmailChanged() {
    if (_requiresEmailChange &&
        _usernameController.text.trim() != _lastFailedEmail) {
      setState(() {
        _requiresEmailChange = false;
        _errorMessage = null;
      });
    }
  }

  void _onPasswordChanged() {
    if (_requiresPasswordChange &&
        _passwordController.text.trim() != _lastFailedPassword) {
      setState(() {
        _requiresPasswordChange = false;
        _errorMessage = null;
      });
    }
  }

  void _onMobileChanged() {
    if (_requiresMobileChange &&
        _mobileNumberController.text.trim() != _lastFailedMobile) {
      setState(() {
        _requiresMobileChange = false;
        _errorMessage = null;
      });
    }
  }

  void _validateForm() {
    bool isValid = false;
    if (_isOtpLogin) {
      final mobileNumber = _mobileNumberController.text.trim();
      isValid = mobileNumber.isNotEmpty; // Removed length check
    } else {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();
      isValid = username.isNotEmpty && password.isNotEmpty;
    }
    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _incrementFailedAttempts() {
    _failedAttempts++;
    if (_failedAttempts >= 3) {
      _startLockout();
    }
  }

  void _startLockout() {
    setState(() {
      _isLockedOut = true;
      _lockoutSeconds = 30;
      _requiresEmailChange = false;
      _requiresPasswordChange = false;
      _requiresMobileChange = false;
    });
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_lockoutSeconds > 0) {
            _lockoutSeconds--;
          } else {
            _isLockedOut = false;
            _failedAttempts = 0;
            timer.cancel();
          }
        });
      }
    });
  }

  String get _formattedLockoutTime {
    int minutes = _lockoutSeconds ~/ 60;
    int seconds = _lockoutSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get _isButtonDisabled {
    if (_isLockedOut) return true;
    if (_isOtpLogin) {
      if (_requiresMobileChange) return true;
      return !_isFormValid || _isOtpButtonDisabled;
    } else {
      if (_requiresEmailChange || _requiresPasswordChange) return true;
      return !_isFormValid;
    }
  }

  void _startOtpCountdown() {
    setState(() {
      _isOtpButtonDisabled = true;
      _otpCountdownSeconds = 5;
    });
    _otpCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_otpCountdownSeconds > 0) {
            _otpCountdownSeconds--;
          } else {
            _isOtpButtonDisabled = false;
            timer.cancel();
          }
        });
      }
    });
  }

  String get _formattedCountdownTime {
    int minutes = _otpCountdownSeconds ~/ 60;
    int seconds = _otpCountdownSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _setLoadingState(bool isLoading) {
    if (mounted) {
      setState(() {
        _isLoading = isLoading;
        if (isLoading) _errorMessage = null;
      });
    }
  }

  void _setErrorMessage(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  void _showRateLimitSnackbar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Too Many Request-Please try after sometime'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (!_isFormValid || _isButtonDisabled) return;
    _setLoadingState(true);
    try {
      if (_isOtpLogin) {
        await _initiateOtpLogin();
      } else {
        await _performEmailLogin();
      }
    } catch (error) {
      _setErrorMessage("An unexpected error occurred. Please try again.");
      //print("Login error: $error");
    }
  }

  Future<void> _performEmailLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    try {
      final response = await _makeEmailLoginRequest(username, password);
      await _handleEmailLoginResponse(response, username, password);
    } catch (error) {
      _setErrorMessage("Network error. Please check your connection.");
      //print("Email login error: $error");
    }
  }

  Future<http.Response> _makeEmailLoginRequest(
    String username,
    String password,
  ) async {
    final url = Uri.parse("$api/login");
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );
  }

  Future<void> _handleEmailLoginResponse(
    http.Response response,
    String username,
    String password,
  ) async {
    if (response.statusCode == 201) {
      await _processSuccessfulLogin(response);
    } else if (response.statusCode == 429) {
      _setLoadingState(false);
      _showRateLimitSnackbar();
    } else {
      _processEmailLoginError(response, username, password);
    }
  }

  void _processEmailLoginError(
    http.Response response,
    String username,
    String password,
  ) {
    _incrementFailedAttempts();
    if (response.statusCode == 404) {
      _setErrorMessage('Not registered with Saamay? Register now!');
      setState(() {
        _requiresEmailChange = true;
        _lastFailedEmail = username;
      });
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['detail'] ??
            'Login failed. Please check your credentials.';
        _setErrorMessage(errorMessage);
        if (errorMessage.toLowerCase().contains('password') ||
            errorMessage.toLowerCase().contains('credential') ||
            errorMessage.toLowerCase().contains('invalid')) {
          setState(() {
            _requiresPasswordChange = true;
            _lastFailedPassword = password;
          });
        }
      } catch (e) {
        _setErrorMessage('Login failed. Please check your credentials.');
        setState(() {
          _requiresPasswordChange = true;
          _lastFailedPassword = password;
        });
      }
    }
    //print("Email login failed: ${response.body}");
  }

  Future<void> _initiateOtpLogin() async {
    final mobileNumber = _mobileNumberController.text.trim();
    final formattedNumber = _formatMobileNumber(mobileNumber);
    try {
      final response = await _sendOtpRequest(formattedNumber);
      await _handleOtpResponse(response, formattedNumber, mobileNumber);
    } catch (error) {
      _setErrorMessage("Network error. Please check your connection.");
      //print("OTP initiation error: $error");
    }
  }

  String _formatMobileNumber(String mobileNumber) {
    // Use selected country code instead of hardcoded 91
    return mobileNumber.startsWith(selectedCountryCode)
        ? mobileNumber
        : '$selectedCountryCode$mobileNumber';
  }

  Future<http.Response> _sendOtpRequest(String whatsappNumber) async {
    final url = Uri.parse("$api/generate_otp");
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"whatsapp_number": whatsappNumber, "username": null}),
    );
  }

  Future<void> _handleOtpResponse(
    http.Response response,
    String whatsappNumber,
    String originalMobile,
  ) async {
    _setLoadingState(false);
    if (response.statusCode == 200) {
      _startOtpCountdown();
      _showOtpVerificationSheet(whatsappNumber);
    } else if (response.statusCode == 429) {
      _showRateLimitSnackbar();
    } else if (response.statusCode == 404) {
      _handleUnregisteredUser(response, originalMobile);
    } else {
      _handleOtpError(response);
    }
  }

  void _handleUnregisteredUser(http.Response response, String originalMobile) {
    _incrementFailedAttempts();
    _setErrorMessage('Not registered with Saamay? Register now!');
    setState(() {
      _requiresMobileChange = true;
      _lastFailedMobile = originalMobile;
    });
    //print("Unregistered user: ${response.body}");
  }

  void _handleOtpError(http.Response response) {
    _incrementFailedAttempts();
    try {
      final errorData = jsonDecode(response.body);
      String message = 'Failed to send OTP. Please try again.';
      if (errorData['error']?['msg'] != null) {
        message = errorData['error']['msg'];
      } else if (errorData['detail'] != null) {
        message = errorData['detail'];
      }
      _setErrorMessage(message);
    } catch (e) {
      _setErrorMessage('Failed to send OTP. Please try again.');
    }
    //print("OTP error: ${response.body}");
  }

  Future<void> _verifyOtpCode(String whatsappNumber, String otp) async {
    _setLoadingState(true);
    try {
      final response = await _makeOtpVerificationRequest(whatsappNumber, otp);
      await _handleOtpVerificationResponse(response);
    } catch (error) {
      _setLoadingState(false);
      _showOtpSheetError("Network error. Please try again.");
      //print("OTP verification error: $error");
    }
  }

  Future<http.Response> _makeOtpVerificationRequest(
    String whatsappNumber,
    String otp,
  ) async {
    final url = Uri.parse("$api/login_otp");
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "whatsapp_number": whatsappNumber,
        "username": null,
        "otp": otp,
      }),
    );
  }

  Future<void> _handleOtpVerificationResponse(http.Response response) async {
    if (response.statusCode == 200) {
      await _processOtpVerificationSuccess(response);
    } else if (response.statusCode == 429) {
      _setLoadingState(false);
      _showRateLimitSnackbar();
    } else {
      _processOtpVerificationError(response);
    }
  }

  Future<void> _processOtpVerificationSuccess(http.Response response) async {
    try {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        final accessToken = responseData['access_token'];
        final refreshToken = responseData['refresh_token'];
        final user_first_time = responseData['user_data']['user_first_time'];
        responseList = responseData;
        token = accessToken;
        await FirebaseMessaging.instance.unsubscribeFromTopic('loggedout');
        await FirebaseMessaging.instance.unsubscribeFromTopic('installed');
        await FirebaseMessaging.instance.subscribeToTopic('loggedin');

        // Extract and save last spinner used time
        final lastSpinnerUsed = responseData['user_data']['last_spinner_used'];
        await _saveUserLoginData(
          accessToken,
          refreshToken,
          lastSpinnerUsed,
          user_first_time,
        );

        final userId = responseData['user_data']['user_id'].toString();
        await _handleFirebaseMessaging(userId);

        // Log Facebook 'loggedIn' event with method = 'mobile_otp'
        final now = DateTime.now();
        final currentTime = "${now.hour}:${now.minute}:${now.second}";
        final currentDate = "${now.year}-${now.month}-${now.day}";

        final facebookAppEvents = FacebookAppEvents();
        facebookAppEvents.logEvent(
          name: 'loggedIn',
          parameters: {
            'time': currentTime,
            'date': currentDate,
            'method': 'mobile_otp',
          },
        );

        _setLoadingState(false);
        Navigator.pop(context);
        _navigateToHomeScreen();
      } else {
        _processOtpVerificationFailure(responseData);
      }
    } catch (error) {
      _setLoadingState(false);
      _showOtpSheetError("Error processing verification. Please try again.");
      //print("OTP success processing error: $error");
    }
  }

  void _processOtpVerificationFailure(Map<String, dynamic> responseData) {
    _incrementFailedAttempts();
    _setLoadingState(false);
    final errorMsg = responseData['error']?['msg'] ??
        'OTP verification failed. Please try again.';
    _showOtpSheetError(errorMsg);
  }

  void _processOtpVerificationError(http.Response response) {
    _incrementFailedAttempts();
    _setLoadingState(false);
    if (response.statusCode == 404) {
      _showOtpSheetError('Not registered with Saamay? Register now!');
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error']?['msg'] ??
            'OTP verification failed. Please try again.';
        _showOtpSheetError(errorMsg);
      } catch (e) {
        _showOtpSheetError('OTP verification failed. Please try again.');
      }
    }
    //print("OTP verification failed: ${response.body}");
  }

  void _showOtpSheetError(String message) {
    if (_currentOtpSheetKey.currentState != null) {
      _currentOtpSheetKey.currentState!.showError(message);
    }
  }

  Future<void> _processSuccessfulLogin(http.Response response) async {
    try {
      final responseData = jsonDecode(response.body);
      final accessToken = responseData['access_token'];
      final refreshToken = responseData['user_data']['refresh_token'];
      final user_first_time = responseData['user_data']['user_first_time'];
      responseList = responseData;
      token = accessToken;

      await FirebaseMessaging.instance.unsubscribeFromTopic('installed');
      await FirebaseMessaging.instance.subscribeToTopic('loggedin');

      // Extract and save last spinner used time
      final lastSpinnerUsed = responseData['user_data']['last_spinner_used'];
      await _saveUserLoginData(
        accessToken,
        refreshToken,
        lastSpinnerUsed,
        user_first_time,
      );

      final userId = responseData['user_data']['user_id'].toString();
      await _handleFirebaseMessaging(userId);

      // Log Facebook 'loggedIn' event with main.dart date/time format
      final now = DateTime.now();
      final currentTime = "${now.hour}:${now.minute}:${now.second}";
      final currentDate = "${now.year}-${now.month}-${now.day}";

      final facebookAppEvents = FacebookAppEvents();
      facebookAppEvents.logEvent(
        name: 'loggedIn',
        parameters: {
          'time': currentTime,
          'date': currentDate,
          'method': 'credential',
        },
      );

      _setLoadingState(false);
      _navigateToHomeScreen();
    } catch (error) {
      _setErrorMessage(
        "Login successful but there was an error. Please try again.",
      );
      print("Login processing error: $error");
    }
  }

  Future<void> _saveUserLoginData(
    String accessToken,
    String refreshToken,
    String? lastSpinnerUsed,
    bool user_first_time,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString('auth_token', accessToken),
        prefs.setString('refresh_token', refreshToken),
        prefs.setBool('user_first_time', user_first_time),
        prefs.setBool('is_logged_in', true),
      ]);

      // Save last spinner used time if available
      if (lastSpinnerUsed != null) {
        await prefs.setString('last_spinner_used', lastSpinnerUsed);
      }

      //print('User login data saved successfully');
    } catch (error) {
      //print('Error saving login data: $error');
    }
  }

  Future<void> _handleFirebaseMessaging(String userId) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final fcmToken = await messaging.getToken();
      if (fcmToken != null) {
        //print("FCM Token generated: $fcmToken");
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', fcmToken);
        await _sendFCMTokenToServer(fcmToken, userId);
      } else {
        //print("Failed to generate FCM token");
      }
    } catch (error) {
      //print("Firebase messaging error: $error");
    }
  }

  Future<void> _sendFCMTokenToServer(String fcmToken, String userId) async {
    try {
      final url = Uri.parse("$api/fcm_token");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "user_id": userId,
          "fcm_token": fcmToken,
          "app_category": "Astrology",
          "user_type": "u",
        }),
      );
      if (response.statusCode == 200) {
        //print("FCM token sent to server successfully");
      } else {
        //print("FCM token response: ${response.body}");
      }
    } catch (error) {
      //print("Error sending FCM token: $error");
    }
  }

  void _toggleLoginMethod() {
    setState(() {
      _isOtpLogin = !_isOtpLogin;
      _isFormValid = false;
      _errorMessage = null;
      _isLoading = false;
      _isOtpButtonDisabled = false;
      _otpCountdownSeconds = 0;
      _otpCountdownTimer?.cancel();
      _requiresEmailChange = false;
      _requiresPasswordChange = false;
      _requiresMobileChange = false;
      _usernameController.clear();
      _passwordController.clear();
      _mobileNumberController.clear();
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _showOtpVerificationSheet(String mobileNumber) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => OtpVerificationSheet(
        key: _currentOtpSheetKey,
        mobileNumber: mobileNumber,
        onVerificationComplete: (String otp) =>
            _verifyOtpCode(mobileNumber, otp),
        onVerificationError: (String errorMessage) {},
        failedAttempts: _failedAttempts,
        isLockedOut: _isLockedOut,
        lockoutSeconds: _lockoutSeconds,
        onAttemptIncrement: () => _incrementFailedAttempts(),
      ),
    );
  }

  void _navigateToHomeScreen() {
    // Use the same state-based navigation pattern as Homepage
    _setNextScreen(const HomeScreen());
  }

  // Add this new method (same pattern as Homepage):
  void _setNextScreen(Widget screen) {
    if (mounted) {
      setState(() {
        _nextScreen = screen;
        _shouldNavigate = true;
      });
    }
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
    );
  }

  void _navigateToRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegistrationPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If we should navigate and have determined the next screen, show it
    if (_shouldNavigate && _nextScreen != null) {
      return _nextScreen!;
    }

    // Otherwise, show the login screen (your existing build method content)
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(children: [_buildBackground(), _buildMainContent()]),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(decoration: const BoxDecoration(color: Color(0xFFFCF7EF))),
        Positioned.fill(
          child: Image.asset(
            'assets/images/getstartedBG.png',
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildLogoSection(),
                _buildFormSection(),
                _buildFooterSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Image.asset(
          'assets/images/saamaywelcome.png',
          height: MediaQuery.of(context).size.height * 0.25,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFormSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInputFields(),
        const SizedBox(height: 10),
        _buildErrorDisplay(),
        _buildLoginButton(),
        const SizedBox(height: 10),
        _buildRegisterButton(),
        _buildDivider(),
        const SizedBox(height: 20),
        _buildToggleButton(),
      ],
    );
  }

  Widget _buildInputFields() {
    if (_isOtpLogin) {
      return _buildMobileNumberField();
    } else {
      return Column(
        children: [
          _buildEmailField(),
          const SizedBox(height: 20),
          _buildPasswordField(),
        ],
      );
    }
  }

  Widget _buildErrorDisplay() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildEmailField() {
    return _buildInputField(
      controller: _usernameController,
      hintText: 'Enter Email Address',
      iconName: 'sms',
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFF2E6E6), width: 1.5),
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        onChanged: (value) => _validateForm(),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.transparent,
          hintText: 'Enter Password',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 16.0,
          ),
          hintStyle: const TextStyle(
            color: Color.fromARGB(255, 107, 85, 5),
            fontSize: 20,
            fontWeight: FontWeight.w300,
          ),
          suffixIcon: GestureDetector(
            onTap: _togglePasswordVisibility,
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Image.asset(
                _obscurePassword
                    ? 'assets/images/eyeSlash.png'
                    : 'assets/images/view.png',
                width: 24,
                height: 24,
              ),
            ),
          ),
        ),
        style: const TextStyle(fontSize: 16, color: Colors.black),
        keyboardType: TextInputType.text,
      ),
    );
  }

  Widget _buildMobileNumberField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFF2E6E6), width: 1.5),
      ),
      child: Row(
        children: [_buildCountryCodeSection(), _buildMobileNumberInput()],
      ),
    );
  }

  Widget _buildCountryCodeSection() {
    return GestureDetector(
      onTap: () {
        _showCountryPicker(context);
      },
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            // Remove hardcoded India flag, use dynamic display
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '+$selectedCountryCode',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    selectedCountryName,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 20),
            const SizedBox(width: 4),
            Container(
              height: 24,
              width: 1,
              color: Colors.grey.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNumberInput() {
    return Expanded(
      child: TextFormField(
        controller: _mobileNumberController,
        onChanged: (value) {
          if (value.isNotEmpty) {
            String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
            // Removed 10 digit limit
            if (value != digitsOnly) {
              _mobileNumberController.value = TextEditingValue(
                text: digitsOnly,
                selection: TextSelection.collapsed(offset: digitsOnly.length),
              );
            }
          }
          _validateForm();
        },
        decoration: const InputDecoration(
          filled: true,
          fillColor: Colors.transparent,
          hintText: 'Enter Mobile Number',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 16.0,
          ),
          hintStyle: TextStyle(
            color: Color.fromARGB(255, 107, 85, 5),
            fontSize: 20,
            fontWeight: FontWeight.w300,
          ),
        ),
        style: const TextStyle(fontSize: 16, color: Colors.black),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          // Removed LengthLimitingTextInputFormatter(10)
        ],
      ),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required String iconName,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFF2E6E6), width: 1.5),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        onChanged: (value) => _validateForm(),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.transparent,
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 16.0,
          ),
          hintStyle: const TextStyle(
            color: Color.fromARGB(255, 107, 85, 5),
            fontSize: 20,
            fontWeight: FontWeight.w300,
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Image.asset(
              'assets/images/$iconName.png',
              width: 24,
              height: 24,
            ),
          ),
        ),
        style: const TextStyle(fontSize: 16, color: Colors.black),
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isButtonDisabled
              ? [const Color(0xFFABABAB), const Color(0xFFABABAB)]
              : [const Color(0xFF89216B), const Color(0xFFDA4453)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isButtonDisabled ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 50),
          disabledBackgroundColor: Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getLoginButtonText(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFF2E6E6),
                fontSize: 20,
              ),
            ),
            if (!_isLoading && !_isButtonDisabled) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Color(0xFFF2E6E6)),
            ],
          ],
        ),
      ),
    );
  }

  String _getLoginButtonText() {
    if (_isLoading) return 'Validating...';
    if (_isLockedOut) return 'Try again in $_formattedLockoutTime';
    if (_isOtpLogin) {
      if (_requiresMobileChange) return 'Change number to continue';
      return _isOtpButtonDisabled
          ? 'Resend OTP in $_formattedCountdownTime'
          : 'Send OTP via WhatsApp';
    } else {
      if (_requiresEmailChange) return 'Change email to continue';
      if (_requiresPasswordChange) return 'Change password to continue';
      return 'Continue to Home';
    }
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(
          child: Divider(color: Color(0xFFDFD1BA), thickness: 1, endIndent: 8),
        ),
        Text(
          'or',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        Expanded(
          child: Divider(color: Color(0xFFDFD1BA), thickness: 1, indent: 8),
        ),
      ],
    );
  }

  Widget _buildToggleButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromARGB(255, 137, 33, 107)),
      ),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _toggleLoginMethod,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 50),
        ),
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF89216B), Color(0xFFDA4453)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                _isOtpLogin
                    ? 'assets/images/sms.png'
                    : 'assets/images/phone.png',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _isOtpLogin ? 'Login with Email' : 'Login with OTP',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: _navigateToForgotPassword,
          child: Text(
            "Forgot Password?",
            style: TextStyle(color: AppColors.accent),
          ),
        ),
        TextButton(
          onPressed: _navigateToRegistration,
          child: Text(
            "Register Now",
            style: TextStyle(color: AppColors.accent),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterSection() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        'By continuing, I agree to Terms of Use & Privacy Policy',
        style: TextStyle(color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class OtpVerificationSheet extends StatefulWidget {
  final String mobileNumber;
  final Function(String) onVerificationComplete;
  final Function(String)? onVerificationError;
  final int failedAttempts;
  final bool isLockedOut;
  final int lockoutSeconds;
  final VoidCallback onAttemptIncrement;

  const OtpVerificationSheet({
    Key? key,
    required this.mobileNumber,
    required this.onVerificationComplete,
    this.onVerificationError,
    required this.failedAttempts,
    required this.isLockedOut,
    required this.lockoutSeconds,
    required this.onAttemptIncrement,
  }) : super(key: key);

  @override
  _OtpVerificationSheetState createState() => _OtpVerificationSheetState();
}

class _OtpVerificationSheetState extends State<OtpVerificationSheet> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  int _secondsRemaining = 40;
  Timer? _timer;
  String? _errorMessage;
  int _localFailedAttempts = 0;
  bool _localIsLockedOut = false;
  int _localLockoutSeconds = 0;
  Timer? _localLockoutTimer;

  @override
  void initState() {
    super.initState();
    _initializeResendTimer();
    _localFailedAttempts = widget.failedAttempts;
    _localIsLockedOut = widget.isLockedOut;
    _localLockoutSeconds = widget.lockoutSeconds;
    if (_localIsLockedOut) {
      _startLocalLockout();
    }
  }

  @override
  void dispose() {
    _cleanupResources();
    super.dispose();
  }

  void _initializeResendTimer() {
    _secondsRemaining = 5;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _timer?.cancel();
          }
        });
      }
    });
  }

  void _cleanupResources() {
    _timer?.cancel();
    _localLockoutTimer?.cancel();
    _otpController.dispose();
  }

  void _incrementLocalFailedAttempts() {
    _localFailedAttempts++;
    widget.onAttemptIncrement();
    if (_localFailedAttempts >= 3) {
      _startLocalLockout();
    }
  }

  void _startLocalLockout() {
    setState(() {
      _localIsLockedOut = true;
      _localLockoutSeconds = 30;
    });
    _localLockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_localLockoutSeconds > 0) {
            _localLockoutSeconds--;
          } else {
            _localIsLockedOut = false;
            _localFailedAttempts = 0;
            timer.cancel();
          }
        });
      }
    });
  }

  String get _formattedLocalLockoutTime {
    int minutes = _localLockoutSeconds ~/ 60;
    int seconds = _localLockoutSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void showError(String errorMessage) {
    if (mounted) {
      setState(() {
        _errorMessage = errorMessage;
        _isVerifying = false;
      });
    }
  }

  void _clearError() {
    if (mounted && _errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  void _initiateOtpVerification() {
    if (_localIsLockedOut) return;
    if (_otpController.text.length == 4) {
      setState(() {
        _isVerifying = true;
        _errorMessage = null;
      });
      widget.onVerificationComplete(_otpController.text);
    } else {
      showError("Please enter a valid 4-digit OTP");
      _incrementLocalFailedAttempts();
    }
  }

  Future<void> _resendOtpCode() async {
    if (_secondsRemaining > 0 || _localIsLockedOut) return;
    try {
      setState(() {
        _isVerifying = true;
        _errorMessage = null;
      });
      final response = await _makeResendOtpRequest();
      _handleResendOtpResponse(response);
    } catch (error) {
      _handleResendOtpError(error);
    }
  }

  Future<http.Response> _makeResendOtpRequest() async {
    final url = Uri.parse("$api/generate_otp");
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "whatsapp_number": widget.mobileNumber,
        "username": null,
      }),
    );
  }

  void _handleResendOtpResponse(http.Response response) {
    setState(() {
      _isVerifying = false;
    });
    if (response.statusCode == 200) {
      _initializeResendTimer();
      _showSuccessMessage();
    } else if (response.statusCode == 429) {
      _showRateLimitSnackbarInSheet();
    } else if (response.statusCode == 404) {
      showError('Not registered with Saamay? Register now!');
      _incrementLocalFailedAttempts();
    } else {
      _handleResendOtpApiError(response);
    }
  }

  void _showRateLimitSnackbarInSheet() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Too Many Request-Please try after sometime'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleResendOtpApiError(http.Response response) {
    _incrementLocalFailedAttempts();
    try {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['error']?['msg'] ?? 'Failed to resend OTP';
      showError(errorMessage);
    } catch (e) {
      showError('Failed to resend OTP');
    }
  }

  void _handleResendOtpError(dynamic error) {
    _incrementLocalFailedAttempts();
    setState(() {
      _isVerifying = false;
      _errorMessage = "Network error. Please try again.";
    });
    //print("Resend OTP error: $error");
  }

  void _showSuccessMessage() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP resent to your WhatsApp'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String get _formattedTime {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}s';
  }

  bool get _canResendOtp => _secondsRemaining <= 0 && !_localIsLockedOut;
  bool get _canVerify => !_localIsLockedOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      constraints: BoxConstraints(minHeight: _calculateMinHeight()),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildTitle(),
            _buildDescription(),
            _buildChangeNumberOption(),
            const SizedBox(height: 30),
            _buildOtpInput(),
            _buildErrorDisplay(),
            const SizedBox(height: 30),
            _buildVerifyButton(),
            const SizedBox(height: 20),
            _buildResendOption(),
            SizedBox(
              height: _isKeyboardOpen()
                  ? MediaQuery.of(context).viewInsets.bottom
                  : 20,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateMinHeight() {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;
    return isKeyboardOpen
        ? MediaQuery.of(context).size.height * 0.8
        : MediaQuery.of(context).size.height * 0.55;
  }

  bool _isKeyboardOpen() => MediaQuery.of(context).viewInsets.bottom > 0;

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Image.asset('assets/images/phone.png', width: 60, height: 60),
        const SizedBox(height: 20),
        const Text(
          'Verify mobile number',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Text(
        'Enter the OTP that we have sent to your WhatsApp number ${widget.mobileNumber}',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildChangeNumberOption() {
    return Column(
      children: [
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Change number',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.edit, size: 16, color: Colors.blue.shade800),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInput() {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
    );
    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: const Color(0xFF89216B), width: 2),
      borderRadius: BorderRadius.circular(8),
    );
    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF89216B)),
      ),
    );
    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: Colors.red, width: 1),
      ),
    );

    return Pinput(
      length: 4,
      controller: _otpController,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      submittedPinTheme:
          _errorMessage != null ? errorPinTheme : submittedPinTheme,
      errorPinTheme: errorPinTheme,
      onCompleted: (pin) => _initiateOtpVerification(),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      pinAnimationType: PinAnimationType.fade,
      onChanged: (_) => _clearError(),
      enabled: _canVerify,
    );
  }

  Widget _buildErrorDisplay() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            (!_canVerify || _isVerifying) ? null : _initiateOtpVerification,
        style: ElevatedButton.styleFrom(
          backgroundColor: _canVerify ? const Color(0xFF89216B) : Colors.grey,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isVerifying
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.0,
                ),
              )
            : Text(
                _localIsLockedOut
                    ? 'Try again in $_formattedLocalLockoutTime'
                    : 'Verify',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildResendOption() {
    return GestureDetector(
      onTap: _canResendOtp ? _resendOtpCode : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer,
            size: 16,
            color: _canResendOtp ? Colors.amber.shade800 : Colors.grey,
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Resend OTP ',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_localIsLockedOut) ...[
                  TextSpan(
                    text: 'in $_formattedLocalLockoutTime',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else if (!_canResendOtp) ...[
                  TextSpan(
                    text: 'in $_formattedTime',
                    style: TextStyle(
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else ...[
                  TextSpan(
                    text: 'now',
                    style: TextStyle(
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
