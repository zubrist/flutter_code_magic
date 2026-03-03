import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar2.dart';
import 'package:saamay/pages/config.dart';
import 'package:saamay/pages/login.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'astrologerProfilePage.dart';

class ChatHistoryPage extends StatefulWidget {
  final int userId;
  final int consultantId;
  final String consultantName;
  final String? consultantImage;
  final String availability;
  final double rate;

  const ChatHistoryPage({
    Key? key,
    required this.userId,
    required this.consultantId,
    required this.consultantName,
    this.consultantImage,
    required this.availability,
    required this.rate,
  }) : super(key: key);

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchChatHistory();
  }

  Future<void> _fetchChatHistory() async {
    if (token == null || token == '') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      errorMessage = null;
    });

    final url = '$api/chats/${widget.userId}/${widget.consultantId}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success' && data['messages'] != null) {
          setState(() {
            _messages.clear();

            // Parse messages from API response
            List<dynamic> messages = data['messages'];

            // Reverse to show oldest first
            messages = messages.reversed.toList();

            String? lastDate;

            for (var message in messages) {
              final timestamp = double.parse(message['time'].toString());
              final messageDate = _convertTimeToDate(timestamp);
              final formattedDate = _formatMessageDate(messageDate);
              final formattedTime = _formatTime(messageDate);

              // Add date header if it's a new date
              if (lastDate != formattedDate) {
                _messages.add({
                  'type': 'date-header',
                  'date': formattedDate,
                });
                lastDate = formattedDate;
              }

              // Check if message is a file URL
              String messageText = message['msg'] ?? '';
              bool isFile = _isUrl(messageText);
              String? fileName;

              if (isFile) {
                fileName = _extractFileNameFromUrl(messageText);
              }

              // Add the message
              _messages.add({
                'uname': message['uname'],
                'msg': messageText,
                'time': formattedTime,
                'sentByCurrentUser': message['uname'] == 'u${widget.userId}',
                'date': formattedDate,
                'isFile': isFile,
                'fileName': fileName,
              });
            }
          });

          // Scroll to bottom after loading
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        } else {
          setState(() {
            errorMessage = 'No chat history found';
          });
        }
      } else if (response.statusCode == 401) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        throw Exception('Failed to load chat history');
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Failed to load chat history. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _fetchChatHistory();
  }

  DateTime _convertTimeToDate(dynamic time) {
    if (time is double) {
      time = time.floor();
    } else if (time is String) {
      time = double.parse(time).floor();
    }
    return DateTime.fromMillisecondsSinceEpoch(time * 1000);
  }

  String _formatMessageDate(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  bool _isUrl(String text) {
    final urlPattern = RegExp(r'^(https?:\/\/[^\s]+)', caseSensitive: false);
    return urlPattern.hasMatch(text);
  }

  String _extractFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments.last;
      }
    } catch (e) {
      // Continue to fallback
    }

    try {
      final lastSlashIndex = url.lastIndexOf('/');
      if (lastSlashIndex != -1 && lastSlashIndex < url.length - 1) {
        return url.substring(lastSlashIndex + 1);
      }
    } catch (e) {
      // Continue to fallback
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

  bool _isImageFile(String url) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    final lowerUrl = url.toLowerCase();
    return imageExtensions.any((ext) => lowerUrl.contains(ext));
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
      return null;
    }
  }

  String _generateFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments.last;
      }
    } catch (e) {
      // Continue to fallback
    }
    return 'downloaded_file_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _openFile(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        _showFileOpenOptions(filePath);
      }
    } catch (e) {
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

  void _handleBookNow() {
    // Check availability before booking
    if (widget.availability == 'A') {
      // Available - proceed with booking
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Book Appointment',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          content: Text(
            'Book an appointment with ${widget.consultantName}?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to booking page or implement booking logic
                // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => BookingPage(...)));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Booking feature coming soon!',
                        style: GoogleFonts.poppins()),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              child: Text(
                'Confirm',
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    } else if (widget.availability == 'B') {
      // Busy
      _showErrorDialog(
          '${widget.consultantName} is currently busy. Please try again later.');
    } else {
      // Offline
      _showErrorDialog(
          '${widget.consultantName} is currently offline. Please try again later.');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
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
              if (widget.consultantImage != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        widget.consultantImage!,
                        height: 40,
                        width: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                    // Availability badge on profile picture
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: widget.availability == 'A'
                              ? const Color(0xFF28A746) // Green for Available
                              : widget.availability == 'B'
                              ? const Color(0xFFDC3546) // Red for Busy
                              : Colors.grey, // Grey for Offline
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.consultantName,
                      style: GoogleFonts.lora(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    // ADD THIS ROW TO SHOW RATE
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '₹${widget.rate}/min',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Show Book Now button only if consultant is available
          actions: widget.availability == 'A'
              ? [
                  Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // Replace this section in the AppBar actions
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AstrologerProfilePage(
                                  consultantId: widget.consultantId,
                                  rate: widget.rate,
                                  availabilityServiceId:
                                      null, // Set to null or pass if available
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Color(0xFF89216B),
                          ),
                          label: Text(
                            'Book Now',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF89216B),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      )),
                ]
              : null, // Don't show button if not available
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.background,
        onRefresh: _onRefresh,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.button,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: _fetchChatHistory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              'Retry',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Chat history will appear here',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Info banner
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            color: Colors.blue.shade50,
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Viewing chat history (Read-only)',
                                  style: GoogleFonts.poppins(
                                    color: Colors.blue.shade700,
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 40),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];

                                // Date header
                                if (message['type'] == 'date-header') {
                                  return Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
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
                                final bool isSent =
                                    message['sentByCurrentUser'] ?? false;
                                final bool isFile = message['isFile'] ?? false;
                                final String messageText = message['msg'] ?? '';

                                return Align(
                                  alignment: isSent
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: GestureDetector(
                                    onLongPress: () {
                                      // Show copy option
                                      Clipboard.setData(
                                          ClipboardData(text: messageText));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isFile
                                                ? 'File link copied to clipboard'
                                                : 'Message copied to clipboard',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          backgroundColor: AppColors.primary,
                                          duration: const Duration(seconds: 2),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
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
                                            MediaQuery.of(context).size.width *
                                                0.75,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSent
                                            ? AppColors.primary
                                            : AppColors.textLight,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.15),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // File handling section
                                          if (isFile)
                                            InkWell(
                                              onTap: () => _handleFileOpen(
                                                messageText,
                                                message['fileName'],
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: isSent
                                                      ? Colors.white
                                                          .withOpacity(0.2)
                                                      : Colors.grey.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
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
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            message['fileName'] ??
                                                                _extractFileNameFromUrl(
                                                                  messageText,
                                                                ),
                                                            style: GoogleFonts
                                                                .poppins(
                                                              color: isSent
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black87,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                          Text(
                                                            'Tap to open',
                                                            style: GoogleFonts
                                                                .poppins(
                                                              color: isSent
                                                                  ? Colors
                                                                      .white70
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
                                              color: isSent
                                                  ? Colors.white70
                                                  : Colors.grey,
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
                        ],
                      ),
      ),
    );
  }
}
