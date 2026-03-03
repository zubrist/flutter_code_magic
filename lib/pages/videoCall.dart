import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:async';
import 'package:saamay/pages/config.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/notificationService.dart';
import 'package:google_fonts/google_fonts.dart';

class VideoCallService {
  // Singleton instance
  static final VideoCallService _instance = VideoCallService._internal();
  factory VideoCallService() => _instance;
  VideoCallService._internal();

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
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      // Enable video
      await _engine.enableVideo();

      // Set client role
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // Register event handlers
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            //print("Local user joined: ${connection.channelId}");
            _isJoined = true;
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
        Uri.parse('$api/token_for_user_puja/$orderId'),
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
      // Join the channel
      await _engine.joinChannel(
        token: _token!,
        channelId: _channelName!,
        uid: _userName!,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
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

  Future<void> toggleVideo(bool enable) async {
    if (!_isInitialized || !_isJoined) return;
    await _engine.muteLocalVideoStream(!enable);
  }

  Future<void> toggleSpeaker(bool enableSpeaker) async {
    if (!_isInitialized || !_isJoined) return;
    await _engine.setEnableSpeakerphone(enableSpeaker);
  }

  Future<void> switchCamera() async {
    if (!_isInitialized || !_isJoined) return;
    await _engine.switchCamera();
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

class VideoCallPage extends StatefulWidget {
  final int userId;
  final int orderId;
  final String userFullname;

  const VideoCallPage({
    Key? key,
    required this.userId,
    required this.orderId,
    required this.userFullname,
  }) : super(key: key);

  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage>
    with TickerProviderStateMixin {
  final VideoCallService _callService = VideoCallService();

  // UI state variables
  bool _isConnecting = false;
  bool _isMuted = false;
  bool _isVideoOn = true;
  bool _isSpeakerOn = true;
  bool _isFrontCamera = true;
  bool _isCallActive = false;
  bool _showWarningMessage = false;

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
    // Set preferred orientation to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

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
    _pulseController.dispose();
    _countdownTimer?.cancel();
    _callService.dispose();

    // Reset orientation settings
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _requestPermissionsAndInitialize() async {
    // Request camera and microphone permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted) {
      // Initialize Agora SDK and auto-join call
      await _initializeCall();
    } else {
      // Handle permission denied
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Camera and microphone permissions are required for video calls.',
            ),
          ),
        );
        // Navigate back after a delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop();
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
        // Create billing record when call starts
        _createBilling();
        // Fetch timer info when call starts
        _fetchTimerInfo();
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

    // Get call token
    final tokenSuccess = await _callService.getCallToken(widget.orderId);

    if (tokenSuccess) {
      // Join call
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Call ended')));
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  // Create billing record API call
  Future<void> _createBilling() async {
    try {
      final response = await http.post(
        Uri.parse('$api/puja_billings/U'),
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
        Uri.parse('$api/puja_billing/U'),
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
            // 15 minutes
            _countdown = 15 * 60;
          });

          if (_callService.remoteUserId != null) {
            _startCountdown();
          }
        }
      } else {
        // Set default countdown
        setState(() {
          // 15 minutes
          _countdown = 15 * 60;
        });

        if (_callService.remoteUserId != null) {
          _startCountdown();
        }
      }
    } catch (e) {
      //print('Exception fetching timer info: $e');
      // Set default countdown
      setState(() {
        // 15 minutes
        _countdown = 15 * 60;
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
      } else {
        timer.cancel();
        if (_isCallActive) {
          _leaveCall();
        } else if (mounted) {
          Navigator.of(context).pop();
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
          content: const Text('The consultant has disconnected from the call.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateBilling();
                if (mounted) {
                  Navigator.of(context).pop();
                }
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

  // Toggle video state
  void _toggleVideo() async {
    if (!_isCallActive) return;

    setState(() {
      _isVideoOn = !_isVideoOn;
    });

    await _callService.toggleVideo(_isVideoOn);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isVideoOn ? 'Video on' : 'Video off'),
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

  // Switch camera
  void _switchCamera() async {
    if (!_isCallActive || !_isVideoOn) return;

    await _callService.switchCamera();

    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFrontCamera ? 'Front camera' : 'Rear camera'),
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
        content: const Text('Are you sure you want to end the call?'),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isCallActive) {
          final shouldPop = await _showEndCallConfirmation();
          return shouldPop ?? false;
        }
        return true;
      },
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
                  'Video Call with ${widget.userFullname}',
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

            // Video Call UI
            Expanded(
              child: VideoCallUI(
                userFullname: widget.userFullname,
                isCallActive: _isCallActive,
                isConnecting: _isConnecting,
                isMuted: _isMuted,
                isVideoOn: _isVideoOn,
                isSpeakerOn: _isSpeakerOn,
                isFrontCamera: _isFrontCamera,
                callDuration: _formatCountdown(_countdown),
                onCallToggle: _toggleCall,
                onMuteToggle: _toggleMute,
                onVideoToggle: _toggleVideo,
                onSpeakerToggle: _toggleSpeaker,
                onSwitchCamera: _switchCamera,
                pulseController: _pulseController,
                primaryColor: primaryColor,
                backgroundColor: backgroundColor,
                cardColor: cardColor,
                gradientStart: gradientStart,
                gradientEnd: gradientEnd,
                callService: _callService,
                channelName: _callService._channelName ?? '',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoCallUI extends StatelessWidget {
  final String userFullname;
  final bool isCallActive;
  final bool isConnecting;
  final bool isMuted;
  final bool isVideoOn;
  final bool isSpeakerOn;
  final bool isFrontCamera;
  final String callDuration;
  final VoidCallback onCallToggle;
  final VoidCallback onMuteToggle;
  final VoidCallback onVideoToggle;
  final VoidCallback onSpeakerToggle;
  final VoidCallback onSwitchCamera;
  final AnimationController pulseController;
  final Color primaryColor;
  final Color backgroundColor;
  final Color cardColor;
  final Color gradientStart;
  final Color gradientEnd;
  final VideoCallService callService;
  final String channelName;

  const VideoCallUI({
    Key? key,
    required this.userFullname,
    required this.isCallActive,
    required this.isConnecting,
    required this.isMuted,
    required this.isVideoOn,
    required this.isSpeakerOn,
    required this.isFrontCamera,
    required this.callDuration,
    required this.onCallToggle,
    required this.onMuteToggle,
    required this.onVideoToggle,
    required this.onSpeakerToggle,
    required this.onSwitchCamera,
    required this.pulseController,
    required this.primaryColor,
    required this.backgroundColor,
    required this.cardColor,
    required this.gradientStart,
    required this.gradientEnd,
    required this.callService,
    required this.channelName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // User info card
          //_buildUserInfoCard(),

          // Video area
          Expanded(child: _buildVideoArea(context)),

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

  Widget _buildVideoArea(BuildContext context) {
    return Stack(
      children: [
        // Remote video view
        if (isCallActive && callService.remoteUserId != null)
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: callService._engine,
              canvas: VideoCanvas(uid: callService.remoteUserId),
              connection: RtcConnection(channelId: channelName),
            ),
          ),

        // Placeholder when no remote video
        if (isCallActive && callService.remoteUserId == null)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Waiting for consultant...",
                  style: GoogleFonts.poppins(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

        // Local video view
        if (isCallActive && isVideoOn)
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              width: 100,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              clipBehavior: Clip.hardEdge,
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: callService._engine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              ),
            ),
          ),
      ],
    );
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

          // Video button
          _buildControlButton(
            icon:
                isVideoOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
            label: isVideoOn ? 'Video Off' : 'Video On',
            isEnabled: isCallActive,
            isActive: isVideoOn,
            activeColor: primaryColor,
            onTap: onVideoToggle,
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

          // Switch camera button
          _buildControlButton(
            icon: isFrontCamera
                ? Icons.flip_camera_ios_rounded
                : Icons.flip_camera_android_rounded,
            label: 'Switch',
            isEnabled: isCallActive && isVideoOn,
            isActive: isFrontCamera,
            activeColor: primaryColor,
            onTap: onSwitchCamera,
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
