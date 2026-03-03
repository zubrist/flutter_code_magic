// spinner_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:saamay/pages/config.dart';
import 'package:saamay/pages/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// Data model for spinner information
class SpinnerData {
  final int spinId;
  final String spinType;
  final bool isActive;
  final String startDate;
  final String endDate;

  SpinnerData({
    required this.spinId,
    required this.spinType,
    required this.isActive,
    required this.startDate,
    required this.endDate,
  });

  factory SpinnerData.fromJson(Map<String, dynamic> json) {
    return SpinnerData(
      spinId: json['spin_id'],
      spinType: json['spin_type'],
      isActive: json['is_active'],
      startDate: json['start_date'],
      endDate: json['end_date'],
    );
  }
}

// Data model for reward information
class RewardData {
  final int? rewardId;
  final String rewardType;
  final String? rewardDesc;
  final String? rewardCode;
  final int rewardValue;
  final String message;

  RewardData({
    this.rewardId,
    required this.rewardType,
    this.rewardDesc,
    this.rewardCode,
    required this.rewardValue,
    required this.message,
  });

  factory RewardData.fromJson(Map<String, dynamic> json) {
    return RewardData(
      rewardId: json['reward_id'],
      rewardType: json['reward_type'],
      rewardDesc: json['reward_desc'],
      rewardCode: json['reward_code'],
      rewardValue: json['reward_value'],
      message: json['message'],
    );
  }
}

// Service class to handle API calls
class SpinnerService {
  // Get spinner status from API
  static Future<List<SpinnerData>> getSpinnerStatus() async {
    // TODO: Uncomment this section when real API is ready

    try {
      final response = await http.get(
        Uri.parse('$api/spinners'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) => SpinnerData.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load spinner status');
      }
    } catch (e) {
      throw Exception('Error fetching spinner status: $e');
    }

    // TEMPORARY RESPONSE - Replace this with actual API call later
    /*
    try {
      // Simulate network delay
      await Future.delayed(Duration(milliseconds: 500));

      // Temporary hardcoded response
      const String tempResponse = '''
      [
          {
              "spin_id": 1,
              "spin_type": "Weekly Reward",
              "is_active": false,
              "start_date": "2025-06-10",
              "end_date": "2025-06-30"
          }
      ]
      ''';

      List<dynamic> data = json.decode(tempResponse);
      return data.map((item) => SpinnerData.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Error with temporary spinner data: $e');
    }*/
  }

  // Get current user ID from API
  static Future<int> getUserId() async {
    try {
      final response = await http.get(
        Uri.parse('$api/user/own'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        return data['data']['user_id'];
      } else {
        throw Exception('Failed to get user data');
      }
    } catch (e) {
      throw Exception('Error fetching user data: $e');
    }
  }

  // Get spin reward from API
  static Future<RewardData> getSpinReward(
    int userId,
    int spinId,
    int numberOnWheel,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$api/spin/get-reward'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: json.encode({
          'user_id': userId,
          'spin_id': spinId,
          'number_on_wheel': numberOnWheel,
        }),
      );

      if (response.statusCode == 200) {
        // Decode response with UTF-8 encoding
        final responseBody = utf8.decode(response.bodyBytes);
        return RewardData.fromJson(json.decode(responseBody));
      } else {
        throw Exception('Failed to get reward');
      }
    } catch (e) {
      throw Exception('Error getting reward: $e');
    }
  }
}

// Extension button widget that appears on the side of the screen
class SpinnerExtensionButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;

  const SpinnerExtensionButton({
    Key? key,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  State<SpinnerExtensionButton> createState() => _SpinnerExtensionButtonState();
}

class _SpinnerExtensionButtonState extends State<SpinnerExtensionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize shake animation controller
    _shakeController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    // Create shake animation with oscillating values
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticInOut),
    );

    // Start animation if initially active
    if (widget.isActive) {
      _startShakeAnimation();
    }
  }

  @override
  void didUpdateWidget(SpinnerExtensionButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start or stop animation based on active state change
    if (widget.isActive && !oldWidget.isActive) {
      _startShakeAnimation();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopShakeAnimation();
    }
  }

  void _startShakeAnimation() {
    _shakeController.repeat(reverse: true);
  }

  void _stopShakeAnimation() {
    _shakeController.stop();
    _shakeController.reset();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: MediaQuery.of(context).size.height * 0.24,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 55,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF460000), Color(0xFF8B0000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Roulette icon with rotation shake animation when active
              Center(
                child: Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: widget.isActive
                      ? AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: sin(_shakeAnimation.value * 2 * pi) *
                                  0.3, // Rotation shake
                              child: Image.asset(
                                'assets/images/roulette.png',
                                width: 40,
                                height: 40,
                              ),
                            );
                          },
                        )
                      : Image.asset(
                          'assets/images/roulette.png',
                          width: 40,
                          height: 40,
                        ),
                ),
              ),
              // Active indicator dot
              if (widget.isActive)
                Positioned(
                  top: 5,
                  right: 8,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Main spinner modal widget
class SpinnerModal extends StatefulWidget {
  final SpinnerData spinnerData;
  final VoidCallback? onSpinComplete;

  const SpinnerModal({Key? key, required this.spinnerData, this.onSpinComplete})
      : super(key: key);

  @override
  State<SpinnerModal> createState() => _SpinnerModalState();
}

class _SpinnerModalState extends State<SpinnerModal>
    with TickerProviderStateMixin {
  // Animation controller for spinning wheel
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  // State variables
  bool _isSpinning = false;
  bool _showResult = false;
  RewardData? _rewardData;
  int? _selectedNumber;

  @override
  void initState() {
    super.initState();
    // Initialize spin animation controller
    _spinController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );
    _spinAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.decelerate),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  // Handle wheel spin functionality
  Future<void> _spinWheel() async {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _showResult = false;
    });

    // Generate random number between 1-8 for wheel segments
    final random = Random();
    _selectedNumber = random.nextInt(8) + 1;

    // Start spinning animation
    await _spinController.forward();

    // Get user ID and call reward API
    try {
      final userId = responseList == null
          ? await SpinnerService.getUserId()
          : responseList['user_data']['user_id'];
      final reward = await SpinnerService.getSpinReward(
        userId,
        widget.spinnerData.spinId,
        _selectedNumber!,
      );

      // Update last spinner used time in SharedPreferences
      await _updateLastSpinnerUsedTime();

      setState(() {
        _rewardData = reward;
        _showResult = true;
        _isSpinning = false;
      });

      // Notify parent that spin is complete
      if (widget.onSpinComplete != null) {
        widget.onSpinComplete!();
      }
    } catch (e) {
      setState(() {
        _isSpinning = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _updateLastSpinnerUsedTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentTime = DateTime.now().toIso8601String();
      await prefs.setString('last_spinner_used', currentTime);
    } catch (e) {
      //print('Error updating last spinner used time: $e');
    }
  }

  // Copy reward code to clipboard
  Future<void> _copyRewardCode() async {
    if (_rewardData?.rewardCode != null) {
      await Clipboard.setData(ClipboardData(text: _rewardData!.rewardCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reward code copied to clipboard!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Close modal dialog
  void _closeModal() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 1,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content area - now takes full height
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 20,
                    ), // Add some top padding to avoid close button overlap
                    // Title section
                    Text(
                      widget.spinnerData.spinType,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF460000),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),

                    // Subtitle section
                    Text(
                      'Spin the wheel to win exciting rewards!',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.lightText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30),

                    // Spinner wheel container
                    Container(
                      width: 250,
                      height: 250,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Animated spinning wheel
                          AnimatedBuilder(
                            animation: _spinAnimation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _spinAnimation.value * 10 * 2 * pi +
                                    0.5 +
                                    (_selectedNumber != null
                                        ? (_selectedNumber! - 2) * (2 * pi / 8)
                                        : 0),
                                child: CustomPaint(
                                  size: Size(220, 220),
                                  painter: SpinnerWheelPainter(
                                    selectedNumber:
                                        _showResult ? _selectedNumber : null,
                                  ),
                                ),
                              );
                            },
                          ),

                          // Center circle of the wheel
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(0xFF460000),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),

                          // Wheel pointer indicator
                          Positioned(
                            top: 10,
                            child: Container(
                              width: 0,
                              height: 0,
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.transparent,
                                    width: 10,
                                  ),
                                  right: BorderSide(
                                    color: Colors.transparent,
                                    width: 10,
                                  ),
                                  bottom: BorderSide(
                                    color: Color(0xFF460000),
                                    width: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 30),

                    // Result display section
                    if (_showResult && _rewardData != null) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _rewardData!.rewardType != 'none'
                                ? [
                                    Colors.green.withOpacity(0.1),
                                    Colors.green.withOpacity(0.05),
                                  ]
                                : [
                                    Colors.orange.withOpacity(0.1),
                                    Colors.orange.withOpacity(0.05),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _rewardData!.rewardType != 'none'
                                ? Colors.green
                                : Colors.orange,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Success icon only if reward is available
                            if (_rewardData!.rewardType != 'none') ...[
                              Icon(
                                Icons.celebration,
                                size: 50,
                                color: Colors.green,
                              ),
                              SizedBox(height: 15),
                            ],

                            // Result title
                            Text(
                              _rewardData!.rewardType != 'none'
                                  ? 'Congratulations!'
                                  : 'Better luck next time!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _rewardData!.rewardType != 'none'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 10),

                            // Success message
                            Text(
                              _rewardData!.message,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            /*
                            // Reward description if available
                            if (_rewardData!.rewardDesc != null) ...[
                              SizedBox(height: 10),
                              Text(
                                _rewardData!.rewardDesc!,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
*/
                            // Reward code display if available
                            if (_rewardData!.rewardCode != null) ...[
                              SizedBox(height: 15),
                              GestureDetector(
                                onTap: _copyRewardCode,
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Reward Code',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.lightText,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _rewardData!.rewardCode!,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF460000),
                                              letterSpacing: 1,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Icon(
                                            Icons.copy,
                                            size: 18,
                                            color: Color(0xFF460000),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],

                    // Spin button (shown when not showing result)
                    if (!_showResult)
                      ElevatedButton(
                        onPressed: _isSpinning ? null : _spinWheel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF460000),
                          padding: EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: _isSpinning
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Loading indicator while spinning
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'SPINNING...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Spin now button text
                                  Text(
                                    'SPIN NOW!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),

                    SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
            ),

            // Floating close button positioned at top-right
            Positioned(
              top: 15,
              right: 15,
              child: GestureDetector(
                onTap: _closeModal,
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.close, size: 22, color: Colors.grey[700]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for drawing the spinner wheel
class SpinnerWheelPainter extends CustomPainter {
  final int? selectedNumber;

  SpinnerWheelPainter({this.selectedNumber});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double sectionAngle = 2 * pi / 8; // 8 sections in the wheel

    // Define vibrant colors for each wheel section
    final List<Color> colors = [
      Color(0xFF89216b), // Purple
      Color(0xFFda4453), // Red
      Color(0xFF89216b), // Purple
      Color(0xFFda4453), // Red
      Color(0xFF89216b), // Purple
      Color(0xFFda4453), // Red
      Color(0xFF89216b), // Purple
      Color(0xFFda4453), // Red
    ];

    // Draw outer ring for better visual appeal
    paint.color = Color(0xFF460000);
    canvas.drawCircle(center, radius + 5, paint);

    // Draw each wheel section
    for (int i = 0; i < 8; i++) {
      final double startAngle = i * sectionAngle - pi / 2;

      // Highlight selected section if result is shown
      paint.color = selectedNumber != null && selectedNumber == i + 1
          ? colors[i]
          : colors[i].withOpacity(0.9);

      // Draw filled section
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sectionAngle,
        true,
        paint,
      );

      // Draw section borders in white
      paint.color = Colors.white;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sectionAngle,
        true,
        paint,
      );
      paint.style = PaintingStyle.fill;

      // Draw section numbers
      final double textAngle = startAngle + sectionAngle / 2;
      final double textRadius = radius * 0.75;
      final double textX = center.dx + textRadius * cos(textAngle);
      final double textY = center.dy + textRadius * sin(textAngle);

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.5),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
      );
    }

    // Draw inner decorative ring
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawCircle(center, radius * 0.4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
