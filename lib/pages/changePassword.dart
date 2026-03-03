import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar2.dart';
import 'package:saamay/pages/config.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({Key? key}) : super(key: key);

  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword>
    with TickerProviderStateMixin {
  // Constants
  static const int _minPasswordLength = 6;
  static const Duration _httpTimeout = Duration(seconds: 30);

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // State Variables
  String? _errorMessage;
  String? _successMessage;
  bool _isFormValid = false;
  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Lifecycle Methods
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeForm();
  }

  @override
  void dispose() {
    _cleanupResources();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Animation Initialization
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  // Initialization
  /// Initialize form listeners and fetch user data
  void _initializeForm() {
    _setupFormListeners();
    _fetchUserEmail();
  }

  /// Setup form validation listeners
  void _setupFormListeners() {
    _oldPasswordController.addListener(_validateForm);
    _newPasswordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  /// Clean up resources to prevent memory leaks
  void _cleanupResources() {
    // Remove listeners
    _oldPasswordController.removeListener(_validateForm);
    _newPasswordController.removeListener(_validateForm);
    _confirmPasswordController.removeListener(_validateForm);

    // Dispose controllers
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
  }

  // API Methods
  /// Fetch user email from the API
  Future<void> _fetchUserEmail() async {
    try {
      final response = await http
          .get(Uri.parse('$api/user/own'), headers: _buildAuthHeaders())
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final responseData = _parseJsonResponse(response.body);
        _updateEmailFromResponse(responseData as Map<String, dynamic>);
      }
    } catch (e) {
      //print('Error fetching user email: $e');
      // Silently fail - user can still change password if they know their email
    }
  }

  /// Parse JSON response safely
  dynamic _parseJsonResponse(String body) {
    try {
      return json.decode(body);
    } catch (e) {
      return {};
    }
  }


  /// Update email field from API response
  void _updateEmailFromResponse(Map<String, dynamic> responseData) {
    if (responseData.isNotEmpty &&
        responseData['data'] is Map<String, dynamic> &&
        responseData['data']['user_email'] != null) {
      setState(() {
        _emailController.text = responseData['data']['user_email'].toString();
      });
    }
  }

  /// Build authentication headers for API requests
  Map<String, String> _buildAuthHeaders({bool includeContentType = true}) {
    final headers = <String, String>{'Authorization': 'Bearer $token'};

    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }

  // Form Validation
  /// Validate the entire form and update state
  void _validateForm() {
    final formData = _getFormData();
    final isValid = _isFormDataValid(formData);

    if (isValid != _isFormValid) {
      _updateFormValidationState(isValid);
    }
  }

  /// Get current form data
  Map<String, String> _getFormData() {
    return {
      'oldPassword': _oldPasswordController.text.trim(),
      'newPassword': _newPasswordController.text.trim(),
      'confirmPassword': _confirmPasswordController.text.trim(),
    };
  }

  /// Check if form data is valid
  bool _isFormDataValid(Map<String, String> formData) {
    return formData['oldPassword']!.isNotEmpty &&
        formData['newPassword']!.isNotEmpty &&
        formData['confirmPassword']!.isNotEmpty &&
        formData['newPassword']!.length >= _minPasswordLength;
  }

  /// Update form validation state
  void _updateFormValidationState(bool isValid) {
    setState(() {
      _isFormValid = isValid;
      _clearMessages();
    });
  }

  // Password Change Logic
  /// Handle password change process
  Future<void> _handleChangePassword() async {
    if (!_isFormValid) return;

    final validationError = _validatePasswordChange();
    if (validationError != null) {
      _setErrorMessage(validationError);
      return;
    }

    await _performPasswordChange();
  }

  /// Validate password change requirements
  String? _validatePasswordChange() {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Check password match
    if (newPassword != confirmPassword) {
      return 'New password and confirm password do not match';
    }

    // Check password strength
    if (newPassword.length < _minPasswordLength) {
      return 'New password must be at least $_minPasswordLength characters long';
    }

    return null;
  }

  /// Perform the password change API call
  Future<void> _performPasswordChange() async {
    _setLoadingState(true);

    try {
      final response = await _makeChangePasswordRequest();
      await _handleChangePasswordResponse(response);
    } catch (error) {
      _setErrorMessage("Network error. Please check your connection.");
      //print("Change password error: $error");
    }
  }

  /// Make HTTP request to change password
  Future<http.Response> _makeChangePasswordRequest() async {
    final url = Uri.parse("$api/user_reset_password");
    final requestBody = _buildPasswordChangeRequestBody();

    return await http
        .post(url, headers: _buildAuthHeaders(), body: jsonEncode(requestBody))
        .timeout(_httpTimeout);
  }

  /// Build request body for password change
  Map<String, String> _buildPasswordChangeRequestBody() {
    return {
      "email": _emailController.text.trim(),
      "old_password": _oldPasswordController.text.trim(),
      "new_password": _newPasswordController.text.trim(),
      "confirm_password": _confirmPasswordController.text.trim(),
    };
  }

  /// Handle password change API response
  Future<void> _handleChangePasswordResponse(http.Response response) async {
    if (response.statusCode == 200) {
      await _handleSuccessResponse(response);
    } else {
      _processChangePasswordError(response);
    }
  }

  /// Handle successful password change response
  Future<void> _handleSuccessResponse(http.Response response) async {
    try {
      final responseData = jsonDecode(response.body);
      final message =
          responseData['message'] ?? 'Password updated successfully';
      _setSuccessMessage(message);
    } catch (error) {
      _setSuccessMessage('Password updated successfully');
    }

    _clearPasswordFields();
    _showSuccessDialog();
  }

  /// Clear password input fields after successful change
  void _clearPasswordFields() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  /// Process password change error response
  void _processChangePasswordError(http.Response response) {
    final errorMessage = _extractErrorMessage(response);
    _setErrorMessage(errorMessage);
    //print("Change password failed: ${response.body}");
  }

  /// Extract error message from response
  String _extractErrorMessage(http.Response response) {
    try {
      final errorData = jsonDecode(response.body);
      return _parseErrorData(errorData);
    } catch (e) {
      return _getDefaultErrorMessage(response.statusCode);
    }
  }

  /// Parse error data to extract meaningful message
  String _parseErrorData(Map<String, dynamic> errorData) {
    if (errorData['detail'] != null) {
      return errorData['detail'].toString();
    } else if (errorData['message'] != null) {
      return errorData['message'].toString();
    } else if (errorData['error'] != null) {
      final error = errorData['error'];
      if (error is String) {
        return error;
      } else if (error is Map && error['msg'] != null) {
        return error['msg'].toString();
      }
    }
    return 'Failed to change password. Please try again.';
  }

  /// Get default error message based on status code
  String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your inputs.';
      case 401:
        return 'Incorrect old password. Please try again.';
      case 404:
        return 'User not found. Please try again.';
      default:
        return 'Failed to change password. Please try again.';
    }
  }

  // State Management
  /// Set loading state
  void _setLoadingState(bool isLoading) {
    if (mounted) {
      setState(() {
        _isLoading = isLoading;
        if (isLoading) {
          _clearMessages();
        }
      });
    }
  }

  /// Set error message and clear success message
  void _setErrorMessage(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _successMessage = null;
        _isLoading = false;
      });
    }
  }

  /// Set success message and clear error message
  void _setSuccessMessage(String message) {
    if (mounted) {
      setState(() {
        _successMessage = message;
        _errorMessage = null;
        _isLoading = false;
      });
    }
  }

  /// Clear all messages
  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  // UI Helpers
  /// Show success dialog after password change
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _buildSuccessDialog(),
    );
  }

  /// Build success dialog widget
  Widget _buildSuccessDialog() {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      title: _buildDialogTitle(),
      content: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Your password has been changed successfully!',
          style: TextStyle(fontSize: 16),
        ),
      ),
      actions: [_buildDialogOkButton()],
    );
  }

  /// Build dialog title with icon
  Widget _buildDialogTitle() {
    return const Row(
      children: [
        Icon(Icons.check_circle, color: Colors.green, size: 28),
        SizedBox(width: 12),
        Text('Success', style: TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  /// Build dialog OK button
  Widget _buildDialogOkButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, right: 8),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pop(); // Go back to profile
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  /// Toggle password visibility for specified field
  void _togglePasswordVisibility(String field) {
    setState(() {
      switch (field) {
        case 'old':
          _obscureOldPassword = !_obscureOldPassword;
          break;
        case 'new':
          _obscureNewPassword = !_obscureNewPassword;
          break;
        case 'confirm':
          _obscureConfirmPassword = !_obscureConfirmPassword;
          break;
      }
    });
  }

  // UI Building Methods
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar2(title: "Change Password"),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),
                        _buildFormSection(),
                        const Spacer(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build the main form section
  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Account Information'),
          const SizedBox(height: 16),
          _buildEmailField(),
          const SizedBox(height: 24),
          _buildSectionTitle('Password Update'),
          const SizedBox(height: 10),
          _buildOldPasswordField(),
          const SizedBox(height: 10),
          _buildNewPasswordField(),
          const SizedBox(height: 10),
          _buildConfirmPasswordField(),
          const SizedBox(height: 24),
          _buildMessageDisplay(),
          _buildChangePasswordButton(),
        ],
      ),
    );
  }

  /// Build section title
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  /// Build email input field (disabled)
  Widget _buildEmailField() {
    return _buildStandardField(
      controller: _emailController,
      hintText: 'Email Address',
      isEnabled: false,
      backgroundColor: const Color(0xFFF8F9FA),
      borderColor: const Color(0xFFE9ECEF),
      textColor: Colors.grey.shade600,
      suffixIcon: _buildEmailIcon(),
    );
  }

  /// Build email icon
  Widget _buildEmailIcon() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Image.asset(
        'assets/images/sms.png',
        width: 20,
        height: 20,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.email, size: 20, color: Colors.grey.shade500),
      ),
    );
  }

  /// Build old password input field
  Widget _buildOldPasswordField() {
    return _buildPasswordField(
      controller: _oldPasswordController,
      hintText: 'Enter Current Password',
      obscureText: _obscureOldPassword,
      onToggleVisibility: () => _togglePasswordVisibility('old'),
    );
  }

  /// Build new password input field
  Widget _buildNewPasswordField() {
    return _buildPasswordField(
      controller: _newPasswordController,
      hintText: 'Enter New Password',
      obscureText: _obscureNewPassword,
      onToggleVisibility: () => _togglePasswordVisibility('new'),
    );
  }

  /// Build confirm password input field
  Widget _buildConfirmPasswordField() {
    return _buildPasswordField(
      controller: _confirmPasswordController,
      hintText: 'Confirm New Password',
      obscureText: _obscureConfirmPassword,
      onToggleVisibility: () => _togglePasswordVisibility('confirm'),
    );
  }

  /// Build a standard password field with visibility toggle
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return _buildStandardField(
      controller: controller,
      hintText: hintText,
      obscureText: obscureText,
      suffixIcon: _buildPasswordVisibilityToggle(
        obscureText,
        onToggleVisibility,
      ),
    );
  }

  /// Build password visibility toggle icon
  Widget _buildPasswordVisibilityToggle(bool obscureText, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Image.asset(
          obscureText ? 'assets/images/eyeSlash.png' : 'assets/images/view.png',
          width: 20,
          height: 20,
          errorBuilder: (context, error, stackTrace) => Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            size: 20,
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  /// Build a standard input field with consistent styling
  Widget _buildStandardField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    bool isEnabled = true,
    Color backgroundColor = const Color(0xFFFFFFFF),
    Color borderColor = const Color(0xFFF2E6E6),
    Color textColor = Colors.black,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: isEnabled,
        obscureText: obscureText,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.transparent,
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18.0,
            horizontal: 16.0,
          ),
          hintStyle: TextStyle(
            color: const Color.fromARGB(255, 107, 85, 5).withOpacity(0.7),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          suffixIcon: suffixIcon,
        ),
        style: TextStyle(
          fontSize: 16,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Build message display area for errors and success messages
  Widget _buildMessageDisplay() {
    if (_errorMessage == null && _successMessage == null) {
      return const SizedBox.shrink();
    }

    final isError = _errorMessage != null;
    final message = isError ? _errorMessage! : _successMessage!;
    final color = isError ? Colors.red.shade600 : Colors.green.shade600;
    final backgroundColor = isError ? Colors.red.shade50 : Colors.green.shade50;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Build the change password button
  Widget _buildChangePasswordButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getButtonGradientColors(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isFormValid
            ? [
                BoxShadow(
                  color: const Color(0xFF89216B).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isFormValid ? _handleChangePassword : null,
        style: _getButtonStyle(),
        child: _buildButtonContent(),
      ),
    );
  }

  /// Get button gradient colors based on form validity
  List<Color> _getButtonGradientColors() {
    return _isFormValid
        ? [const Color(0xFF89216B), const Color(0xFFDA4453)]
        : [const Color(0xFF9E9E9E), const Color(0xFF9E9E9E)];
  }

  /// Get button style
  ButtonStyle _getButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      minimumSize: const Size(double.infinity, 56),
      disabledBackgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  /// Build button content (text and loading indicator)
  Widget _buildButtonContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isLoading)
            ..._buildLoadingContent()
          else
            ..._buildNormalContent(),
        ],
      ),
    );
  }

  /// Build loading button content
  List<Widget> _buildLoadingContent() {
    return [
      const SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: 2.5,
        ),
      ),
      const SizedBox(width: 12),
      const Text(
        'Updating Password...',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    ];
  }

  /// Build normal button content
  List<Widget> _buildNormalContent() {
    return [
      const Text(
        'Change Password',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      if (_isFormValid) ...[
        const SizedBox(width: 8),
        const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
      ],
    ];
  }
}
