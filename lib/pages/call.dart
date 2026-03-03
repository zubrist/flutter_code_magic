import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart'; // Added for permissions
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/homescreen.dart'; // Import HomeScreen
import 'dart:convert';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:saamay/pages/config.dart';
import 'package:saamay/pages/notificationService.dart';
//import 'package:saamay/pages/feedbackPopup.dart';
import 'package:saamay/pages/recharge.dart';

class VoiceCallService {
  // Singleton instance
  static final VoiceCallService _instance = VoiceCallService._internal();
  factory VoiceCallService() => _instance;
  VoiceCallService._internal();

  // Agora SDK variables
  late RtcEngine _engine;
  String? _token;
  String? _channelName;
  int? _userName;
  bool _isInitialized = false;
  bool _isJoined = false;
  int? _remoteUid;

  // Callback handlers
  Function(bool)? onCallStatusChanged;
  Function(int?)? onRemoteUserJoined;
  Function(String)? onError;
  Function(int)? onRemoteUserLeft;

  // Initialize Agora RTC SDK
  Future<void> initializeAgoraSDK() async {
    if (_isInitialized) return;

    try {
      // Create RTC Engine instance
      _engine = createAgoraRtcEngine();

      // Initialize the RTC engine
      await _engine.initialize(
        RtcEngineContext(
          appId: agoraAppId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      // Set audio profile and scenario
      await _engine.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );

      // Set client role
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // Register event handlers
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            //print("Local user joined: ${connection.channelId}");
            _isJoined = true;
            //print("sahel");
            if (onCallStatusChanged != null) onCallStatusChanged!(true);
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            //print("Remote user joined: $remoteUid");
            _remoteUid = remoteUid;
            if (onRemoteUserJoined != null) onRemoteUserJoined!(remoteUid);
          },
          onUserOffline: (
            RtcConnection connection,
            int remoteUid,
            UserOfflineReasonType reason,
          ) {
            //print("Remote user offline: $remoteUid reason: $reason");
            _remoteUid = null;
            if (onRemoteUserLeft != null) onRemoteUserLeft!(remoteUid);
          },
          onError: (ErrorCodeType err, String msg) {
            //print('Error: $err, $msg');
            if (onError != null) onError!(msg);
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            //print('Left channel with stats: ${stats.duration}');
            _isJoined = false;
            if (onCallStatusChanged != null) onCallStatusChanged!(false);
          },
        ),
      );

      _isInitialized = true;
    } catch (e) {
      //print('Error initializing Agora SDK: $e');
      if (onError != null) onError!('Error initializing call service: $e');
    }
  }

  // Get call token from API
  Future<bool> getCallToken(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$api/token_for_user/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      //print('API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['Status'] == 'Success') {
          _token = data['token'];
          _channelName = data['data']['channel_name'];
          _userName = int.parse(data['data']['user_name']);
          return true;
        } else {
          if (onError != null) onError!('Failed to retrieve call details');
          return false;
        }
      } else {
        //print('API Error: ${response.statusCode}, ${response.body}');
        if (onError != null) onError!('Error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      //print('Exception: $e');
      if (onError != null) onError!('Error connecting to call: $e');
      return false;
    }
  }

  // Join call channel
  Future<bool> joinCall() async {
    if (!_isInitialized) {
      await initializeAgoraSDK();
    }

    if (_token == null || _channelName == null || _userName == null) {
      if (onError != null) onError!('Call details not available');
      return false;
    }

    try {
      // Enable audio
      await _engine.enableAudio();

      // Join the channel
      await _engine.joinChannel(
        token: _token!,
        channelId: _channelName!,
        uid: _userName!,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      return true;
    } catch (e) {
      //print('Error joining call: $e');
      if (onError != null) onError!('Error joining call: $e');
      return false;
    }
  }

  // Leave call channel
  Future<void> leaveCall() async {
    if (!_isInitialized || !_isJoined) return;

    try {
      await _engine.leaveChannel();
      _isJoined = false;
      _remoteUid = null;
    } catch (e) {
      //print('Error leaving channel: $e');
      if (onError != null) onError!('Error disconnecting call: $e');
    }
  }

  // Call control methods
  Future<void> toggleMute(bool mute) async {
    if (!_isInitialized || !_isJoined) return;
    await _engine.muteLocalAudioStream(mute);
  }

  Future<void> toggleSpeaker(bool enableSpeaker) async {
    if (!_isInitialized || !_isJoined) return;
    await _engine.setEnableSpeakerphone(enableSpeaker);
  }

  // Dispose resources
  Future<void> dispose() async {
    if (_isJoined) {
      await leaveCall();
    }

    if (_isInitialized) {
      await _engine.release();
      _isInitialized = false;
    }
  }

  // Getters
  bool get isCallActive => _isJoined;
  int? get remoteUserId => _remoteUid;
}

class CallPage extends StatefulWidget {
  final int userId;
  final int orderId;
  final String userFullname;
  final String? packName;

  const CallPage({
    Key? key,
    required this.userId,
    required this.orderId,
    required this.userFullname,
    this.packName,
  }) : super(key: key);

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> with TickerProviderStateMixin {
  final VoiceCallService _callService = VoiceCallService();

  // UI state variables
  bool _isConnecting = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isCallActive = false;
  bool _showWarningMessage = false;

  bool _hasShownRechargeSheet = false;

  // Countdown timer variables
  Timer? _countdownTimer;
  int _countdown = 0; // Countdown in seconds

  // Animation controller for pulsing effect
  late AnimationController _pulseController;

  // Theme colors
  final Color primaryColor = Colors.red[900]!;
  final Color backgroundColor = const Color(0xFFFCF7EF);
  final Color cardColor = Colors.white;
  final Color gradientStart = const Color(0xFFF9C702);
  final Color gradientEnd = const Color(0xFFAE0074);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().updateContext(context);
    });
    // Set up pulse animation for avatar rings during active call
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Initialize call service event handlers
    _setupCallEventHandlers();

    // Request permissions and initialize call
    _requestPermissionsAndInitialize();
  }

  @override
  void dispose() {
    if (!mounted) return;
    _pulseController.dispose();
    _countdownTimer?.cancel();
    _callService.dispose();
    super.dispose();
  }

  // Navigate to HomeScreen and clear navigation stack
  void _navigateToHomeScreen() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    _callService.dispose();
    // Navigate to HomeScreen and clear all previous routes
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _showRechargeBottomSheet() {
    if (!mounted || _hasShownRechargeSheet) return;

    setState(() {
      _hasShownRechargeSheet = true;
    });

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Recharge now to continue chat',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _updateBilling();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => RechargePage()),
                      (Route<dynamic> route) => false,
                    ).then((_) {
                      // Resources will be disposed automatically by the dispose() method
                      // when the route is removed
                    });
                  },
                  child: Text(
                    'Recharge Now',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _hasShownRechargeSheet = false;
        });
      }
    });
  }

  Future<void> _requestPermissionsAndInitialize() async {
    // Request microphone permission
    final microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus.isGranted) {
      // Initialize Agora SDK and auto-join call
      await _initializeCall();
    } else {
      // Handle permission denied
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required for voice calls.'),
          ),
        );
        // Navigate back after a delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _navigateToHomeScreen(); // Navigate to HomeScreen instead of Navigator.pop()
        }
      }
    }
  }

  void _setupCallEventHandlers() {
    _callService.onCallStatusChanged = (isActive) {
      setState(() {
        _isCallActive = isActive;
        _isConnecting = false;
      });

      if (isActive) {
        // (No need to call _createBilling() or _fetchTimerInfo() here anymore)
        // Only handle any UI changes or call start logic if needed
      } else {
        _stopCountdown();
        // Update billing when call ends
        _updateBilling();
      }
    };

    _callService.onRemoteUserJoined = (uid) {
      setState(() {});
      // Start countdown when remote user joins
      if (_countdown > 0) {
        _startCountdown();
      }
    };

    _callService.onRemoteUserLeft = (uid) {
      setState(() {});
      // Handle remote user disconnection
      _handleRemoteUserDisconnect();
    };

    _callService.onError = (errorMsg) {
      setState(() {
        _isConnecting = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMsg)));
    };
  }

  Future<void> _initializeCall() async {
    await _callService.initializeAgoraSDK();
    // Auto-join call
    _connectToCall();
  }

  // Connect to call
  Future<void> _connectToCall() async {
    setState(() {
      _isConnecting = true;
    });

    // 1. Fetch timer info first
    await _fetchTimerInfo();

    // 2. Create billing record next
    await _createBilling();

    // 3. Then get token and join call
    final tokenSuccess = await _callService.getCallToken(widget.orderId);

    if (tokenSuccess) {
      await _callService.joinCall();
    } else {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  // Leave call
  Future<void> _leaveCall() async {
    await _callService.leaveCall();
    _stopCountdown();
    _updateBilling();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Call ended. Please provide feedback')),
      );
      Future.delayed(const Duration(milliseconds: 10), () {
        if (mounted) {
          _navigateToHomeScreen(); // Navigate to HomeScreen instead of Navigator.pop()
        }
      });
    }
  }

  // Create billing record API call
  Future<void> _createBilling() async {
    try {
      final response = await http.post(
        Uri.parse('$api/billings/U'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'order_id': widget.orderId}),
      );

      //print('Create Billing Response: ${response.body}');

      if (response.statusCode != 200) {
        //print('API Error: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      //print('Exception creating billing: $e');
    }
  }

  // Update billing record API call
  Future<void> _updateBilling() async {
    try {
      final response = await http.put(
        Uri.parse('$api/billing/U'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'order_id': widget.orderId}),
      );

      //print('Update Billing Response: ${response.body}');
    } catch (e) {
      //print('Exception updating billing: $e');
    }
  }

  // Fetch timer information from API
  Future<void> _fetchTimerInfo() async {
    try {
      final response = await http.post(
        Uri.parse('$api/timer'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'order_id': widget.orderId}),
      );

      //print('Timer API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['service_duration'] != null) {
          int duration = _parseDuration(data['service_duration']);
          //int duration = 10;
          if (duration <= 0) {
            _showInsufficientBalanceDialog();
            return;
          }

          setState(() {
            _countdown = duration;
          });

          // Start countdown if remote user is already joined
          if (_callService.remoteUserId != null) {
            _startCountdown();
          }
        } else {
          // Set default countdown
          setState(() {
            _countdown = 15 * 60; // 15 minutes
          });

          if (_callService.remoteUserId != null) {
            _startCountdown();
          }
        }
      } else {
        // Set default countdown
        setState(() {
          _countdown = 15 * 60; // 15 minutes
        });

        if (_callService.remoteUserId != null) {
          _startCountdown();
        }
      }
    } catch (e) {
      //print('Exception fetching timer info: $e');
      // Set default countdown
      setState(() {
        _countdown = 15 * 60; // 15 minutes
      });

      if (_callService.remoteUserId != null) {
        _startCountdown();
      }
    }
  }

  // Parse duration string to seconds
  int _parseDuration(dynamic serviceDuration) {
    if (serviceDuration is String) {
      final regex = RegExp(r'(\d+)m(?::(\d+))?s?');
      final match = regex.firstMatch(serviceDuration);
      if (match != null) {
        final minutes = int.parse(match.group(1) ?? '0');
        final seconds = match.group(2) != null ? int.parse(match.group(2)!) : 0;
        return minutes * 60 + seconds;
      }
    } else if (serviceDuration is int) {
      return serviceDuration;
    }
    //print('Unable to parse service_duration: $serviceDuration. Defaulting to 0.');
    return 0;
  }

  // Start countdown timer
  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });

        // Show warning message when 1 minute remaining
        if (_countdown == 60) {
          setState(() {
            _showWarningMessage = true;
          });
        }

        // Show recharge bottom sheet when 5 seconds remaining
        if (_countdown == 5) {
          _showRechargeBottomSheet();
        }
      } else {
        timer.cancel();
        if (_isCallActive) {
          _leaveCall();
        } else if (mounted) {
          _navigateToHomeScreen();
        }
      }
    });
  }

  // Stop countdown timer
  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  // Format countdown to mm:ss
  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Handle remote user disconnection
  void _handleRemoteUserDisconnect() {
    if (_isCallActive && _callService.remoteUserId == null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: backgroundColor,
          title: Text('Call Ended', style: TextStyle(color: primaryColor)),
          content: const Text(
            'Astrologer has disconnected from the call. Please provide feedback',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateBilling();
                _navigateToHomeScreen(); // Navigate to HomeScreen instead of Navigator.pop()
              },
              child: Text('OK', style: TextStyle(color: primaryColor)),
            ),
          ],
        ),
      );
    }
  }

  // Toggle mute state
  void _toggleMute() async {
    if (!_isCallActive) return;

    setState(() {
      _isMuted = !_isMuted;
    });

    await _callService.toggleMute(_isMuted);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isMuted ? 'Muted' : 'Unmuted'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // Toggle speaker state
  void _toggleSpeaker() async {
    if (!_isCallActive) return;

    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });

    await _callService.toggleSpeaker(_isSpeakerOn);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSpeakerOn ? 'Speaker on' : 'Speaker off'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // Toggle call state (start/end)
  void _toggleCall() async {
    if (_isCallActive) {
      final shouldEnd = await _showEndCallConfirmation();
      if (shouldEnd == true && mounted) {
        _leaveCall();
      }
    } else {
      await _connectToCall();
    }
  }

  // Show confirmation dialog before ending call
  Future<bool?> _showEndCallConfirmation() {
    if (!mounted) return Future.value(false);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text('End Call', style: TextStyle(color: primaryColor)),
        content: const Text(
          'Are you sure you want to end the call? Please provide feedback',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              _leaveCall();
            },
            child: Text('End Call', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  // Handle back button with WillPopScope
  Future<bool> _onWillPop() async {
    if (_isCallActive) {
      final shouldPop = await _showEndCallConfirmation();
      return shouldPop ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: Stack(
            children: [
              // Gradient background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF89216B), Color(0xFFDA4453)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ),
              // Overlay PNG image on top of gradient
              Positioned.fill(
                child: Image.asset('assets/images/BG.png', fit: BoxFit.cover),
              ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  widget.packName != null
                      ? '${widget.userFullname} - ${widget.packName}'
                      : widget.userFullname,
                  style: GoogleFonts.lora(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _callService.remoteUserId != null
                      ? Colors.green.withOpacity(0.2)
                      : (_isConnecting
                          ? Colors.amber.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isConnecting
                          ? Icons.sync
                          : (_callService.remoteUserId != null
                              ? Icons.person
                              : Icons.person_off),
                      size: 14,
                      color: _isConnecting
                          ? Colors.amber
                          : (_callService.remoteUserId != null
                              ? Colors.green
                              : Colors.red),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isConnecting
                          ? 'Connecting...'
                          : (_callService.remoteUserId != null
                              ? 'Connected'
                              : 'Not connected'),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () async {
                if (_isCallActive) {
                  final shouldClose = await _showEndCallConfirmation();
                  if (shouldClose == true && mounted) {
                    _updateBilling();
                    _navigateToHomeScreen(); // Navigate to HomeScreen instead of Navigator.pop()
                  }
                } else {
                  _navigateToHomeScreen(); // Navigate to HomeScreen instead of Navigator.pop()
                }
              },
            ),
          ],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        body: Column(
          children: [
            // Warning message
            if (_showWarningMessage)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                color: Colors.red.shade100,
                width: double.infinity,
                child: Text(
                  'Call will end in next 1 min',
                  style: GoogleFonts.poppins(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Connection status
            if (_isConnecting)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                color: Colors.amber.shade100,
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.amber.shade800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Connecting to call...',
                      style: GoogleFonts.poppins(
                        color: Colors.amber.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Waiting for user message
            if (_callService.remoteUserId == null &&
                !_isConnecting &&
                _isCallActive)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                color: Colors.blue.shade100,
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue.shade800,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Waiting for consultant to connect...',
                      style: GoogleFonts.poppins(
                        color: Colors.blue.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Timer display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.grey.shade100,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, size: 18, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text(
                    _isCallActive
                        ? 'Call ends in: ${_formatCountdown(_countdown)}'
                        : 'Call time: ${_formatCountdown(_countdown)}',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Voice Call UI
            Expanded(
              child: VoiceCallUI(
                userFullname: widget.userFullname,
                isCallActive: _isCallActive,
                isConnecting: _isConnecting,
                isMuted: _isMuted,
                isSpeakerOn: _isSpeakerOn,
                callDuration: _formatCountdown(_countdown),
                onCallToggle: _toggleCall,
                onMuteToggle: _toggleMute,
                onSpeakerToggle: _toggleSpeaker,
                pulseController: _pulseController,
                primaryColor: primaryColor,
                backgroundColor: backgroundColor,
                cardColor: cardColor,
                gradientStart: gradientStart,
                gradientEnd: gradientEnd,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInsufficientBalanceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Cannot dismiss by tapping outside
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevents Android/iOS system back pop
        child: AlertDialog(
          title: Text(
            'Insufficient Balance',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          content: Text(
            'You do not have enough balance in your wallet to start the chat.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _navigateToHomeScreen(); // Navigate to home screen
              },
              child: Text(
                'OK',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
      ),
    );
  }
}

class VoiceCallUI extends StatelessWidget {
  final String userFullname;
  final bool isCallActive;
  final bool isConnecting;
  final bool isMuted;
  final bool isSpeakerOn;
  final String callDuration;
  final VoidCallback onCallToggle;
  final VoidCallback onMuteToggle;
  final VoidCallback onSpeakerToggle;
  final AnimationController pulseController;
  final Color primaryColor;
  final Color backgroundColor;
  final Color cardColor;
  final Color gradientStart;
  final Color gradientEnd;

  const VoiceCallUI({
    Key? key,
    required this.userFullname,
    required this.isCallActive,
    required this.isConnecting,
    required this.isMuted,
    required this.isSpeakerOn,
    required this.callDuration,
    required this.onCallToggle,
    required this.onMuteToggle,
    required this.onSpeakerToggle,
    required this.pulseController,
    required this.primaryColor,
    required this.backgroundColor,
    required this.cardColor,
    required this.gradientStart,
    required this.gradientEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // User info card
          //_buildUserInfoCard(),

          // Call area
          Expanded(child: _buildCallArea()),

          // Call controls
          _buildCallControls(),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: AppColors.button,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // User avatar
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.transparent,
                child: Text(
                  userFullname.isNotEmpty ? userFullname[0].toUpperCase() : '?',
                  style: GoogleFonts.lora(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // User name
            Expanded(
              child: Text(
                userFullname,
                style: GoogleFonts.lora(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Call status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCallActive
                    ? Colors.green.withOpacity(0.2)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCallActive
                      ? Colors.green.shade300
                      : Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                isCallActive ? callDuration : 'Not connected',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Status text
        Container(
          width: double.infinity,
          height: 24,
          margin: const EdgeInsets.only(bottom: 40),
          alignment: Alignment.center,
          child: Text(
            isConnecting
                ? 'Connecting...'
                : (isCallActive ? 'Call in progress' : 'Ready to start call'),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isConnecting
                  ? Colors.orange[700]
                  : (isCallActive ? primaryColor : Colors.grey[700]),
            ),
          ),
        ),

        // Avatar with pulse animation
        Container(
          height: 180,
          width: 180,
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Pulsing rings (only shown when call is active)
              if (isCallActive) ..._buildPulsingRings(),

              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCallActive ? primaryColor : Colors.grey.shade300,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isCallActive ? primaryColor : Colors.grey.shade400)
                              .withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  child: Text(
                    userFullname.isNotEmpty
                        ? userFullname[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.lora(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: isCallActive ? primaryColor : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 60),
      ],
    );
  }

  List<Widget> _buildPulsingRings() {
    return List.generate(3, (index) {
      return AnimatedBuilder(
        animation: pulseController,
        builder: (context, child) {
          final double scale = 1.0 + (index + 1) * 0.2 * pulseController.value;
          final double opacity =
              (1.0 - pulseController.value) * (0.4 - index * 0.1);

          return Opacity(
            opacity: opacity,
            child: Container(
              width: 120 * scale,
              height: 120 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor, width: 1.5),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildCallControls() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: isMuted ? 'Unmute' : 'Mute',
            isEnabled: isCallActive,
            isActive: isMuted,
            activeColor: Colors.red,
            onTap: onMuteToggle,
          ),

          // Call button
          _buildCallButton(),

          // Speaker button
          _buildControlButton(
            icon: isSpeakerOn
                ? Icons.volume_up_rounded
                : Icons.volume_down_rounded,
            label: 'Speaker',
            isEnabled: isCallActive,
            isActive: isSpeakerOn,
            activeColor: primaryColor,
            onTap: onSpeakerToggle,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isEnabled,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    final Color color = isActive ? activeColor : Colors.grey[700]!;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive ? color.withOpacity(0.1) : Colors.grey[100],
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? color.withOpacity(0.5) : Colors.grey.shade300,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: Icon(
                  icon,
                  color: isEnabled ? color : Colors.grey,
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 65,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isEnabled ? color : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton() {
    final List<Color> gradientColors = isCallActive
        ? [Colors.red.shade400, Colors.red.shade800]
        : [const Color(0xFF4CAF50), const Color(0xFF2E7D32)];

    return GestureDetector(
      onTap: isConnecting ? null : onCallToggle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isCallActive
                          ? Colors.red.shade400
                          : Colors.green.shade400)
                      .withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: isConnecting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Icon(
                      isCallActive
                          ? Icons.call_end_rounded
                          : Icons.call_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              isConnecting
                  ? 'Connect'
                  : (isCallActive ? 'End Call' : 'Start Call'),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isConnecting
                    ? Colors.grey
                    : (isCallActive
                        ? Colors.red.shade700
                        : Colors.green.shade700),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
