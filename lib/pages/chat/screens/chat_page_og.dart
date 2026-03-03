// chat_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar2.dart';
import 'package:saamay/pages/config.dart';
//import 'package:saamay/pages/feedbackPopup.dart';
import 'package:saamay/pages/notificationService.dart';
import 'package:saamay/pages/homescreen.dart'; // Import HomeScreen
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatPage extends StatefulWidget {
  final int userId;
  final int consultantId;
  final int orderId;
  final String userFullname;

  const ChatPage({
    Key? key,
    required this.userId,
    required this.consultantId,
    required this.orderId,
    required this.userFullname,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // Chat state variables
  final TextEditingController _messageController = TextEditingController();
  final List<dynamic> _messages = [];
  final ScrollController _scrollController = ScrollController();
  WebSocketChannel? _channel;
  bool _isConnecting = false;
  StreamSubscription? _wsSubscription;

  // Timer related variables
  int _countdown = 0; // Countdown in seconds
  Timer? _countdownTimer;
  bool _showWarningMessage = false;
  bool _timerStarted = false;

  // User connection status
  bool _isUserConnected = false;
  bool _hasUserEverConnected = false;
  Timer? _disconnectionTimer;

  // File upload variables
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  final int _maxFileSize = 5 * 1024 * 1024; // 5MB
  final List<String> _allowedFileTypes = [
    '.jpg',
    '.jpeg',
    '.png',
    '.pdf',
    '.doc',
    '.docx',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().updateContext(context);
    });
    _initialize();
  }

  // Initialize chat features
  Future<void> _initialize() async {
    try {
      // Fetch countdown timer
      await _fetchTimer();
      // Connect to WebSocket with a small delay
      await Future.delayed(const Duration(milliseconds: 500));
      _connectWebSocket();
      // Create billing
      await _createBilling();
      // Load chat history
      await _loadChatHistory();
    } catch (e) {
      //print('Error initializing chat: $e');
    }
  }

  // Handle back button with WillPopScope
  Future<bool> _onWillPop() async {
    return await _showExitConfirmationDialog() ?? false;
  }

  // Show confirmation dialog when trying to exit
  Future<bool?> _showExitConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Exit Chat',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        content: Text(
          'Are you sure you want to exit this chat session? Please provide your feedback',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Stay',
              style: GoogleFonts.poppins(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              _updateBilling();
              Navigator.of(context).pop(true); // Close the dialog
              _navigateToHomeScreen(); // Navigate to HomeScreen
            },
            child: Text(
              'Exit',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
    );
  }

  // Navigate to HomeScreen and clear navigation stack
  void _navigateToHomeScreen() {
    // Navigate to HomeScreen and clear all previous routes
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _loadChatHistory() async {}

  // Fetch timer duration from server
  Future<void> _fetchTimer() async {
    if (!mounted) return;

    final url = Uri.parse("$api/timer");

    try {
      //print("Fetching timer from: $url");
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"order_id": widget.orderId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['service_duration'] != null && mounted) {
          final duration = _parseDuration(data['service_duration']);
          //final duration = 0;
          setState(() {
            _countdown = duration;
          });
          //print('Timer fetched successfully: $duration seconds');
        } else {
          //print('Invalid API response: $data');
        }
      } else {
        //print('Failed to fetch timer: ${response.statusCode}');
      }
    } catch (error) {
      //print('Error fetching timer: $error');
    }
  }

  int _parseDuration(dynamic serviceDuration) {
    if (serviceDuration is String) {
      final regex = RegExp(r'(\d+)m(?::(\d+))?');
      final match = regex.firstMatch(serviceDuration);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = match.group(2) != null ? int.parse(match.group(2)!) : 0;
        return minutes * 60 + seconds;
      }
    } else if (serviceDuration is int) {
      return serviceDuration;
    }

    //print('Unable to parse service_duration: $serviceDuration. Defaulting to 0.');
    return 0;
  }

  void _startCountdown() {
    if (!mounted) return;

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

        if (_countdown == 60) {
          setState(() {
            _showWarningMessage = true;
          });
        }
      } else {
        timer.cancel();
        _updateBilling();
        _navigateToHomeScreen();
      }
    });
  }

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _connectWebSocket() {
    if (!mounted || _isConnecting) {
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    try {
      // Clean up any existing connection first
      _closeWebSocketConnection();

      // Prepare query parameters using the format from your example
      final queryParams = {
        'user_id': 'u${widget.userId}',
        'room': 'chat:u${widget.userId}:c${widget.consultantId}',
        'token': 'Bearer ${token}',
        'type': 'u',
        'order_id': widget.orderId.toString(),
      };

      // Create WebSocket URL with query parameters
      var wsUrl = Uri.parse("$ws/ws").replace(queryParameters: queryParams);
      //print("Connecting to WebSocket: $wsUrl");

      _channel = WebSocketChannel.connect(wsUrl);
      _setupWebSocketListeners();
    } catch (e) {
      //print('Error connecting to WebSocket: $e');
      _retryConnection();
    }
  }

  void _setupWebSocketListeners() {
    if (_channel == null) return;

    // Cancel any existing subscription first
    _wsSubscription?.cancel();

    // Set up new subscription
    _wsSubscription = _channel!.stream.listen(
      (dynamic message) {
        // Process incoming message
        _processWebSocketMessage(message);
      },
      onError: (error) {
        //print('WebSocket error: $error');
        if (mounted) {
          setState(() {
            _isConnecting = true;
          });
          _retryConnection();
        }
      },
      onDone: () {
        //print('WebSocket connection closed');
        if (mounted) {
          setState(() {
            _isConnecting = true;
          });
          _retryConnection();
        }
      },
    );
  }

  void _processWebSocketMessage(dynamic message) {
    try {
      final jsonMessage = jsonDecode(message.toString());
      //print('Received message: $jsonMessage');

      // Update connection status for any message type
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }

      // Handle announcement messages
      if (jsonMessage['type'] == 'announcement') {
        // Handle user connection status
        if (jsonMessage['action'] == 'connected' &&
            jsonMessage['msg'].contains('c${widget.consultantId} connected')) {
          if (mounted) {
            setState(() {
              _isUserConnected = true;
              _hasUserEverConnected = true;

              // Cancel any pending disconnection timer
              _disconnectionTimer?.cancel();
              _disconnectionTimer = null;

              // Start countdown timer only if not already started
              // and we have a user connected
              if (!_timerStarted && _countdown > 0) {
                _timerStarted = true;
                _startCountdown();
              }
            });
          }
        } else if (jsonMessage['action'] == 'disconnected' &&
            jsonMessage['msg'].contains(
              'c${widget.consultantId} disconnected',
            )) {
          if (mounted) {
            setState(() {
              _isUserConnected = false;

              // Only show disconnection dialog if user was previously connected
              if (_hasUserEverConnected) {
                // Start disconnection timer - close the page after 2 seconds
                _disconnectionTimer?.cancel();
                _disconnectionTimer = Timer(const Duration(seconds: 2), () {
                  _showDisconnectionDialog();
                });
              }
            });
          }
        }

        //print('Announcement: ${jsonMessage['msg']}');
      }
      // Handle regular chat messages
      else if (jsonMessage['type'] == 'comment') {
        final timestamp = jsonMessage['time'] ??
            DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final messageDate = _convertTimeToDate(timestamp);
        final formattedDate = _formatMessageDate(messageDate);
        final formattedTime = _formatTime(messageDate);

        if (mounted) {
          setState(() {
            // Add date header if it's a new date
            if (_messages.isEmpty ||
                (_messages.isNotEmpty &&
                    _messages[_messages.length - 1]['date'] != formattedDate &&
                    _messages[_messages.length - 1]['type'] != 'date-header')) {
              _messages.add({'type': 'date-header', 'date': formattedDate});
            }

            // Check if message is a file URL and extract filename if not provided
            String? fileName = jsonMessage['fileName'];
            bool isFile = jsonMessage['isFile'] ?? false;
            String messageText = jsonMessage['msg'] ?? '';

            // If no fileName is provided but the message looks like a file URL, extract it
            if (fileName == null && _isUrl(messageText)) {
              fileName = _extractFileNameFromUrl(messageText);
              isFile = true;
            }

            // Add the message
            _messages.add({
              ...jsonMessage,
              'time': formattedTime,
              'sentByCurrentUser': jsonMessage['uname'] == "u${widget.userId}",
              'date': formattedDate,
              'isFile': isFile,
              'fileName': fileName,
            });
          });

          // Scroll to bottom
          _scrollToBottom();
        }
      }
    } catch (e) {
      //print('Error processing WebSocket message: $e');
    }
  }

  void _showDisconnectionDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Consultant Disconnected',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        content: Text(
          'The consultant has disconnected from the chat session. Please provide your feedback',
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
              _updateBilling();
              _navigateToHomeScreen(); // Navigate to HomeScreen
            },
            child: Text(
              'Close',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
    );
  }

  void _retryConnection() {
    if (!mounted) return;

    // Wait a bit before retrying
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _connectWebSocket();
      }
    });
  }

  void _closeWebSocketConnection() {
    try {
      // Cancel the stream subscription
      _wsSubscription?.cancel();
      _wsSubscription = null;

      // Close the channel
      if (_channel != null) {
        _channel!.sink.close();
        _channel = null;
      }
    } catch (e) {
      //print('Error closing WebSocket: $e');
    }
  }

  DateTime _convertTimeToDate(dynamic time) {
    if (time is double) {
      time = time.floor();
    }
    return DateTime.fromMillisecondsSinceEpoch(time * 1000);
  }

  String _formatMessageDate(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  // Billing functionality
  Future<void> _createBilling() async {
    if (!mounted) return;

    final url = Uri.parse("$api/billings/U");

    try {
      //print("Creating billing: $url");
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"order_id": widget.orderId}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        //print('Failed to create billing: ${response.statusCode}');
      } else {
        //print('Billing created successfully: ${response.statusCode}');
      }
    } catch (error) {
      //print('Error creating billing: $error');
    }
  }

  Future<void> _updateBilling() async {
    if (!mounted) return;

    final url = Uri.parse("$api/billing/U");

    try {
      //print("Updating billing: $url");
      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"order_id": widget.orderId}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        //print('Failed to update billing: ${response.statusCode}');
      } else {
        //print('Billing updated successfully: ${response.statusCode}');
      }
    } catch (error) {
      //print('Error updating billing: $error');
    }
  }

  // File attachment functionality
  Future<void> _handleFileUpload() async {
    _showAttachmentOptions();
  }

  void _showAttachmentOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Source',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primary),
                title: Text('Camera', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primary),
                title: Text('Gallery', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Icon(Icons.folder, color: AppColors.primary),
                title: Text('Files', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickFromStorage();
                },
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        final file = File(image.path);
        final fileName = image.name;
        final fileSize = await file.length();

        if (fileSize > _maxFileSize) {
          _showErrorDialog('Image size should not exceed 5MB');
          return;
        }

        if (mounted) {
          setState(() {
            _isUploading = true;
            _uploadProgress = 0.0;
          });
        }

        await _uploadFile(file, fileName);
      }
    } catch (e) {
      //print('Error picking image from camera: $e');
      _showErrorDialog('Failed to capture image. Please try again.');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        final file = File(image.path);
        final fileName = image.name;
        final fileExtension = path.extension(fileName).toLowerCase();

        if (!['.jpg', '.jpeg', '.png'].contains(fileExtension)) {
          _showErrorDialog('Please select a valid image file (JPG, JPEG, PNG)');
          return;
        }

        final fileSize = await file.length();
        if (fileSize > _maxFileSize) {
          _showErrorDialog('Image size should not exceed 5MB');
          return;
        }

        if (mounted) {
          setState(() {
            _isUploading = true;
            _uploadProgress = 0.0;
          });
        }

        await _uploadFile(file, fileName);
      }
    } catch (e) {
      //print('Error picking image from gallery: $e');
      _showErrorDialog('Failed to pick image. Please try again.');
    }
  }

  Future<void> _pickFromStorage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileExtension = path.extension(fileName).toLowerCase();

        if (!_allowedFileTypes.contains(fileExtension)) {
          _showErrorDialog(
            'Invalid file type. Allowed types: ${_allowedFileTypes.join(', ')}',
          );
          return;
        }

        final fileSize = await file.length();
        if (fileSize > _maxFileSize) {
          _showErrorDialog('File size should not exceed 5MB');
          return;
        }

        if (mounted) {
          setState(() {
            _isUploading = true;
            _uploadProgress = 0.0;
          });
        }

        await _uploadFile(file, fileName);
      }
    } catch (e) {
      //print('Error picking file from storage: $e');
      _showErrorDialog('Failed to pick file. Please try again.');
    }
  }

  Future<void> _uploadFile(File file, String fileName) async {
    try {
      final uri = Uri.parse("$chatFileUploadUrl/upload");
      final request = http.MultipartRequest('POST', uri);

      // Add file to request
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      // Add headers if needed
      request.headers['Authorization'] = 'Bearer $token';

      // Send request and track progress
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['url'] != null) {
          final fileUrl = responseData['url'];

          // Send file message through websocket
          _sendFileMessage("$chatFileUploadUrl$fileUrl", fileName);
        }
      } else {
        _showErrorDialog('Failed to upload file. Please try again.');
      }
    } catch (e) {
      //print('Error uploading file: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
      _showErrorDialog('Failed to upload file. Please try again.');
    }
  }

  void _sendFileMessage(String fileUrl, String fileName) {
    if (!mounted || _channel == null) return;

    try {
      final messageData = {
        'uname': "u${widget.userId}",
        'msg': fileUrl,
        'type': 'comment',
        'room': "chat:u${widget.userId}:c${widget.consultantId}",
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'isFile': true,
        'fileName': fileName,
      };

      //print('Sending file message: $messageData');
      _channel!.sink.add(jsonEncode(messageData));
    } catch (e) {
      //print('Error sending file message: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Error',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _handleFileOpen(String fileUrl, String? fileName) async {
    try {
      _showLoadingDialog();

      if (_isImageFile(fileUrl)) {
        Navigator.of(context).pop();
        _showImageViewer(fileUrl);
        return;
      }

      final file = await _downloadFile(fileUrl, fileName);
      Navigator.of(context).pop();

      if (file != null) {
        await _openFile(file.path);
      }
    } catch (e) {
      Navigator.of(context).pop();
      //print('Error opening file: $e');
      _showErrorDialog('Failed to open file. Please try again.');
    }
  }

  Future<File?> _downloadFile(String url, String? fileName) async {
    try {
      Directory downloadDir;
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          downloadDir = await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory();
        }
      } else {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      final String finalFileName = fileName ?? _generateFileNameFromUrl(url);
      final String filePath = '${downloadDir.path}/$finalFileName';

      final file = File(filePath);
      if (await file.exists()) {
        return file;
      }

      final dio = Dio();
      await dio.download(url, filePath);
      return file;
    } catch (e) {
      //print('Error downloading file: $e');
      return null;
    }
  }

  Future<void> _openFile(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        _showFileOpenOptions(filePath);
      }
    } catch (e) {
      //print('Error opening file: $e');
      _showErrorDialog('No app found to open this file type.');
    }
  }

  void _showImageViewer(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.error, color: Colors.white, size: 50),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final file = await _downloadFile(imageUrl, null);
                    if (file != null) {
                      _showSuccessDialog('Image saved to ${file.path}');
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: Text('Download', style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Opening file...', style: GoogleFonts.poppins()),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Success',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFileOpenOptions(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Open File',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        content: Text(
          'No default app found to open this file. You can find the downloaded file at:\n\n$filePath',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Clipboard.setData(ClipboardData(text: filePath));
              _showSuccessDialog('Path copied to clipboard');
            },
            child: Text(
              'Copy Path',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // Utility functions
  bool _isImageFile(String url) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    final lowerUrl = url.toLowerCase();
    return imageExtensions.any((ext) => lowerUrl.contains(ext));
  }

  bool _isUrl(String text) {
    final urlPattern = RegExp(r'^(https?:\/\/[^\s]+)', caseSensitive: false);
    return urlPattern.hasMatch(text);
  }

  String _generateFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments.last;
      }
    } catch (e) {
      //print('Error parsing URL: $e');
    }
    return 'downloaded_file_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _extractFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments.last;
      }
    } catch (e) {
      //print('Error parsing URL for filename: $e');
    }

    try {
      final lastSlashIndex = url.lastIndexOf('/');
      if (lastSlashIndex != -1 && lastSlashIndex < url.length - 1) {
        return url.substring(lastSlashIndex + 1);
      }
    } catch (e) {
      //print('Error extracting filename from URL: $e');
    }

    return 'Unknown file';
  }

  IconData _getFileIcon(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('.pdf')) return Icons.picture_as_pdf;
    if (lowerUrl.contains('.doc') || lowerUrl.contains('.docx'))
      return Icons.description;
    if (lowerUrl.contains('.jpg') ||
        lowerUrl.contains('.jpeg') ||
        lowerUrl.contains('.png') ||
        lowerUrl.contains('.gif')) return Icons.image;
    return Icons.insert_drive_file;
  }

  void _sendMessage() {
    if (!mounted) return;

    final message = _messageController.text.trim();
    if (message.isEmpty || _channel == null) return;

    try {
      final messageData = {
        'uname': "u${widget.userId}",
        'msg': message,
        'type': 'comment',
        'room': "chat:u${widget.userId}:c${widget.consultantId}",
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      //print('Sending message: $messageData');
      _channel!.sink.add(jsonEncode(messageData));
      _messageController.clear();
    } catch (e) {
      //print('Error sending message: $e');
      // Attempt to reconnect if sending fails
      if (mounted) {
        setState(() {
          _isConnecting = true;
        });
        //_retryConnection();
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && mounted) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients && mounted) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _updateBilling();
    _countdownTimer?.cancel();
    _disconnectionTimer?.cancel();
    _closeWebSocketConnection();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(
            centerTitle: false,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side - Text chat with consultant name
                Expanded(
                  child: Text(
                    'Chat with ${widget.userFullname}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Right side - Close button
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () async {
                    final shouldClose = await _showExitConfirmationDialog();
                    if (shouldClose == true) {
                      _updateBilling();
                      _navigateToHomeScreen(); // Navigate to HomeScreen instead of Navigator.of(context).pop()
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Timer display with countdown
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  color: Colors.grey.shade100,
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer, size: 18, color: Colors.grey[700]),
                      const SizedBox(width: 4),
                      Text(
                        _timerStarted
                            ? 'Chat closes in: ${_formatCountdown(_countdown)}'
                            : 'Chat time: ${_formatCountdown(_countdown)}',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Warning message - shown when countdown is less than 1 minute
                if (_showWarningMessage)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    color: Colors.red.shade100,
                    width: double.infinity,
                    child: Text(
                      'Chat Session will end in next 1 min',
                      style: GoogleFonts.poppins(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Connection status - shown when trying to connect to WebSocket
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
                          'Connecting to chat...',
                          style: GoogleFonts.poppins(
                            color: Colors.amber.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                // User Connection Status Indicator
                if (_hasUserEverConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 16,
                    ),
                    color: _isUserConnected
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isUserConnected ? Icons.person : Icons.person_off,
                          size: 16,
                          color: _isUserConnected
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isUserConnected
                              ? 'Consultant Connected'
                              : 'Consultant Disconnected',
                          style: GoogleFonts.poppins(
                            color: _isUserConnected
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Waiting for user message - shown when not yet connected
                if (!_hasUserEverConnected && !_isConnecting)
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

                // Chat messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];

                      // Date header
                      if (message['type'] == 'date-header') {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              message['date'],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        );
                      }

                      // Regular message
                      final bool isSent = message['sentByCurrentUser'] ?? false;
                      final bool isFile = message['isFile'] ?? false;
                      final String messageText = message['msg'] ?? '';
                      final bool isUrl = _isUrl(messageText);

                      return Align(
                        alignment: isSent
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: GestureDetector(
                          onLongPress: () {
                            // Show copy option
                            Clipboard.setData(ClipboardData(text: messageText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isFile || isUrl
                                      ? 'File link copied to clipboard'
                                      : 'Message copied to clipboard',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: AppColors.primary,
                                duration: const Duration(seconds: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isSent
                                  ? AppColors.primary
                                  : AppColors.textLight,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // File handling section
                                if (isUrl)
                                  InkWell(
                                    onTap: () => _handleFileOpen(
                                      messageText,
                                      message['fileName'],
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isSent
                                            ? Colors.white.withOpacity(0.2)
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getFileIcon(messageText),
                                            color: isSent
                                                ? Colors.white
                                                : AppColors.primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  message['fileName'] ??
                                                      _extractFileNameFromUrl(
                                                        messageText,
                                                      ),
                                                  style: GoogleFonts.poppins(
                                                    color: isSent
                                                        ? Colors.white
                                                        : Colors.black87,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  'Tap to open',
                                                  style: GoogleFonts.poppins(
                                                    color: isSent
                                                        ? Colors.white70
                                                        : Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.open_in_new,
                                            color: isSent
                                                ? Colors.white70
                                                : Colors.grey,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    messageText,
                                    style: GoogleFonts.poppins(
                                      color: isSent
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  message['time'] ?? '',
                                  style: GoogleFonts.poppins(
                                    color:
                                        isSent ? Colors.white70 : Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Message input field
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textLight,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, -1),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Upload progress indicator
                      if (_isUploading)
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              LinearProgressIndicator(
                                value: _uploadProgress / 100,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Uploading... ${_uploadProgress.toInt()}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Message input row
                      Row(
                        children: [
                          // Attachment button
                          Material(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(24),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: _isUploading ? null : _handleFileUpload,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  Icons.attach_file,
                                  color: _isUploading
                                      ? Colors.grey
                                      : AppColors.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Text input
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade500,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Send button
                          Material(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(24),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: _sendMessage,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: (MediaQuery.of(context).viewInsets.bottom > 0)
                      ? 0
                      : MediaQuery.of(context).padding.bottom,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
