import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/config.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isCheckingEmail = false;
  bool _isFormValid = false;
  bool _emailExists = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateForm);
    _emailController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final email = _emailController.text.trim();
    bool isValid = email.isNotEmpty && _isValidEmail(email);

    setState(() {
      _isFormValid = isValid;
      _errorMessage = null;
      _successMessage = null;
    });

    // Check email existence when format is valid
    if (isValid) {
      _checkEmailExists(email);
    } else {
      setState(() {
        _emailExists = false;
      });
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _checkEmailExists(String email) async {
    setState(() {
      _isCheckingEmail = true;
      _emailExists = false; // Reset email exists state
      _errorMessage = null;
    });

    try {
      final response = await _makeCheckEmailRequest(email);
      await _handleCheckEmailResponse(response);
    } catch (error) {
      setState(() {
        _isCheckingEmail = false;
        _emailExists = false;
        _errorMessage = "Unable to verify email. Please check your connection.";
      });
      //print("Check email error: $error");
    }
  }

  Future<http.Response> _makeCheckEmailRequest(String email) async {
    final url = Uri.parse("$api/check_user_email/$email");
    return await http.get(url);
  }

  Future<void> _handleCheckEmailResponse(http.Response response) async {
    setState(() {
      _isCheckingEmail = false;
    });

    if (response.statusCode == 200) {
      try {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'exists') {
          setState(() {
            _emailExists = true;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _emailExists = false;
            _errorMessage =
                "This email address is not registered. Please check and try again.";
          });
        }
      } catch (e) {
        setState(() {
          _emailExists = false;
          _errorMessage = "Unable to verify email. Please try again.";
        });
      }
    } else {
      setState(() {
        _emailExists = false;
        _errorMessage =
            "This email address is not registered. Please check and try again.";
      });
    }
    //print("Check email response: ${response.body}");
  }

  void _setLoadingState(bool isLoading) {
    if (mounted) {
      setState(() {
        _isLoading = isLoading;
        if (isLoading) {
          _errorMessage = null;
          _successMessage = null;
        }
      });
    }
  }

  void _setErrorMessage(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _successMessage = null;
        _isLoading = false;
      });
    }
  }

  void _setSuccessMessage(String message) {
    if (mounted) {
      setState(() {
        _successMessage = message;
        _errorMessage = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendResetEmail() async {
    if (!_isFormValid || _isLoading || !_emailExists) return;

    _setLoadingState(true);

    try {
      final email = _emailController.text.trim();
      final response = await _makeForgetPasswordRequest(email);
      await _handleForgetPasswordResponse(response);
    } catch (error) {
      _setErrorMessage("Network error. Please check your connection.");
      //rint("Forget password error: $error");
    }
  }

  Future<http.Response> _makeForgetPasswordRequest(String email) async {
    final url = Uri.parse("$api/user_forget_password");
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
  }

  Future<void> _handleForgetPasswordResponse(http.Response response) async {
    if (response.statusCode == 200) {
      try {
        final responseData = jsonDecode(response.body);
        if (responseData['status_code'] == 200) {
          _setSuccessMessage(
            responseData['message'] ?? 'Email sent successfully',
          );
        } else {
          _setErrorMessage('Failed to send email. Please try again.');
        }
      } catch (e) {
        _setSuccessMessage('Email sent successfully');
      }
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ??
            errorData['detail'] ??
            'Failed to send email. Please try again.';
        _setErrorMessage(errorMessage);
      } catch (e) {
        _setErrorMessage('Failed to send email. Please try again.');
      }
    }
    print("Forget password response: ${response.body}");
  }

  @override
  Widget build(BuildContext context) {
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
                _buildHeaderSection(),
                _buildFormSection(),
                _buildFooterSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        const SizedBox(height: 20),
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
        const Text(
          'Forgot Password?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Enter your email address to receive a password',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        _buildEmailField(),
        const SizedBox(height: 10),
        _buildMessageDisplay(),
        const SizedBox(height: 20),
        _buildSendButton(),
        const SizedBox(height: 20),
        _buildSpamMessage(),
      ],
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _isFormValid && _emailExists
              ? Colors.green.shade300
              : _isFormValid && !_emailExists && _errorMessage != null
                  ? Colors.red.shade300
                  : const Color(0xFFF2E6E6),
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: _emailController,
        onChanged: (value) => _validateForm(),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.transparent,
          hintText: 'Enter Email Address',
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
            child: _isCheckingEmail
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey.shade600,
                      ),
                    ),
                  )
                : _isFormValid && _emailExists
                    ? Icon(Icons.check_circle, color: Colors.green, size: 24)
                    : _isFormValid && !_emailExists && _errorMessage != null
                        ? Icon(Icons.error, color: Colors.red, size: 24)
                        : Image.asset('assets/images/sms.png',
                            width: 24, height: 24),
          ),
        ),
        style: const TextStyle(fontSize: 16, color: Colors.black),
        keyboardType: TextInputType.emailAddress,
      ),
    );
  }

  Widget _buildMessageDisplay() {
    if (_errorMessage == null && _successMessage == null) {
      return const SizedBox.shrink();
    }

    final isError = _errorMessage != null;
    final message = isError ? _errorMessage! : _successMessage!;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isError ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isError ? Colors.red.shade200 : Colors.green.shade200,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? Colors.red : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: isError ? Colors.red : Colors.green.shade700,
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

  Widget _buildSendButton() {
    final isButtonEnabled = _isFormValid && _emailExists && !_isLoading;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: !isButtonEnabled
              ? [const Color(0xFFABABAB), const Color(0xFFABABAB)]
              : [const Color(0xFF89216B), const Color(0xFFDA4453)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: !isButtonEnabled ? null : _sendResetEmail,
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
            if (_isLoading) ...[
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.0,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Sending...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF2E6E6),
                  fontSize: 20,
                ),
              ),
            ] else ...[
              const Text(
                'Send Email',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF2E6E6),
                  fontSize: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Color(0xFFF2E6E6)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpamMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Please check the spam folder in your mail box for the E-mail',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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
