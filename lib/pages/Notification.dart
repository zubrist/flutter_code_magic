import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:saamay/pages/call.dart';
import 'package:saamay/pages/chat/screens/chat_page.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/commonWidget/appBar2.dart';
import 'package:saamay/pages/config.dart';
import 'package:saamay/pages/notificationService.dart';
import 'package:saamay/pages/videoCall.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<dynamic> notifications = [];
  bool isLoading = true;
  bool isRefreshing = false; // Track refresh state
  String errorMessage = '';

  // Timer for refreshing notifications data from API
  Timer? _apiRefreshTimer;

  // Timer for updating the countdown on UI
  Timer? _countdownTimer;

  // Map to store remaining seconds for each notification
  Map<String, int> remainingSeconds = {};

  // Reference to the notification service
  final NotificationService _notificationService = NotificationService();

  // Subscription to notification updates
  late StreamSubscription _notificationSubscription;

  // Global key for refresh indicator
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    // Initial fetch
    fetchNotifications();

    // Set up timers
    _startApiRefreshTimer();
    _startCountdownTimer();

    // Update notification service context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationService.updateContext(context);
    });

    // Listen to notification stream to refresh our list when alerts happen
    _notificationSubscription = _notificationService.notificationStream.listen((
      notification,
    ) {
      // Refresh our list when a notification alert happens
      fetchNotifications();
    });
  }

  @override
  void dispose() {
    // Cancel timers when widget is disposed
    _apiRefreshTimer?.cancel();
    _countdownTimer?.cancel();
    _notificationSubscription.cancel();
    super.dispose();
  }

  // Timer to fetch new data from API every 30 seconds
  void _startApiRefreshTimer() {
    _apiRefreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted && !isRefreshing) {
        fetchNotifications();
      }
    });
  }

  // Timer to update countdown every second
  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // This will update the UI with new countdown values every second
          _updateRemainingTimes();
        });
      }
    });
  }

  // Update remaining time calculations
  void _updateRemainingTimes() {
    for (var notification in notifications) {
      final String orderId = notification['order_id'].toString();
      DateTime parsedStartTime = DateTime.parse(notification['start_time']);
      DateTime now = DateTime.now();
      Duration difference = parsedStartTime.difference(now);

      // Store remaining seconds for each notification
      remainingSeconds[orderId] =
          difference.inSeconds > 0 ? difference.inSeconds : 0;
    }
  }

  // Enhanced fetch notifications with refresh state management
  Future<void> fetchNotifications({bool isManualRefresh = false}) async {
    if (isManualRefresh) {
      setState(() {
        isRefreshing = true;
        errorMessage = ''; // Clear any previous errors
      });
    }

    final url = Uri.parse('$api/send_notifications');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ////print("notified");
        if (mounted) {
          setState(() {
            notifications = data['data'];
            isLoading = false;
            isRefreshing = false;
            errorMessage = ''; // Clear error message on success

            // Initialize remaining seconds for new notifications
            _updateRemainingTimes();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
            isRefreshing = false;
            // Optionally set error message for debugging
            // errorMessage = 'Failed to load notifications. Status code: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
          errorMessage = 'Error: $e';
        });
      }

      // Show error message for manual refresh
      if (isManualRefresh && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error. Please try again.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to handle pull-to-refresh
  Future<void> _handleRefresh() async {
    await fetchNotifications(isManualRefresh: true);
  }

  // Method to manually trigger refresh (can be called from elsewhere)
  void triggerRefresh() {
    _refreshIndicatorKey.currentState?.show();
  }

  String formatDate(String startTime) {
    DateTime parsedDate = DateTime.parse(startTime);
    return DateFormat('dd MMM yyyy, hh:mm a').format(parsedDate);
  }

  // Check if the start time has been reached
  bool isTimeToJoin(String startTime) {
    DateTime parsedStartTime = DateTime.parse(startTime);
    DateTime now = DateTime.now();
    return now.isAfter(parsedStartTime) ||
        now.isAtSameMomentAs(parsedStartTime);
  }

  // Get formatted remaining time string
  String getFormattedRemainingTime(int seconds) {
    if (seconds <= 0) {
      return "Now";
    }

    int days = seconds ~/ 86400;
    int hours = (seconds % 86400) ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSecs = seconds % 60;

    if (days > 0) {
      return "${days}d ${hours}h remaining";
    } else if (hours > 0) {
      return "${hours}h ${minutes}m remaining";
    } else if (minutes > 0) {
      return "${minutes}m ${remainingSecs}s remaining";
    } else {
      return "${remainingSecs}s remaining";
    }
  }

  Widget _buildEmptyNotificationsView() {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 74, 74, 74),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'No upcoming orders found within the next 15 minutes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 74, 74, 74),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => fetchNotifications(isManualRefresh: true),
                  icon: Icon(Icons.refresh),
                  label: Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Or pull down to refresh',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar2(
        title: "Notification",
        // Optional: Add refresh action in app bar
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: isRefreshing ? Colors.grey : null),
            onPressed: isRefreshing ? null : () => triggerRefresh(),
            tooltip: 'Refresh notifications',
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading notifications...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : errorMessage.isNotEmpty
              ? _buildErrorView()
              : notifications.isEmpty
                  ? _buildEmptyNotificationsView()
                  : RefreshIndicator(
                      key: _refreshIndicatorKey,
                      onRefresh: _handleRefresh,
                      color: AppColors
                          .primary, // Customize refresh indicator color
                      backgroundColor: Colors.white,
                      strokeWidth: 2.5,
                      displacement: 40.0, // Distance from top
                      child: ListView.builder(
                        physics:
                            AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh even with few items
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          final String orderId =
                              notification['order_id'].toString();
                          final bool canJoin =
                              isTimeToJoin(notification['start_time']);

                          // Get seconds remaining from our map or calculate if not present
                          final int secondsRemaining =
                              remainingSeconds[orderId] ?? 0;
                          final String remainingTime =
                              getFormattedRemainingTime(
                            secondsRemaining,
                          );

                          return Card(
                            elevation: 4,
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notification['con_category'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person,
                                              size: 16,
                                              color: Colors.grey[700],
                                            ),
                                            SizedBox(width: 5),
                                            Flexible(
                                              child: Text(
                                                notification['consultant_name'],
                                                style: TextStyle(fontSize: 13),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: Colors.grey[700],
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              formatDate(
                                                  notification['start_time']),
                                              style: TextStyle(fontSize: 13),
                                            ),
                                          ],
                                        ),
                                        if (!canJoin)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 5),
                                            child: AnimatedContainer(
                                              duration:
                                                  Duration(milliseconds: 500),
                                              padding: EdgeInsets.symmetric(
                                                vertical: 4,
                                                horizontal: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: secondsRemaining < 25
                                                    ? Colors.red
                                                        .withOpacity(0.1)
                                                    : Colors.orange
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.timer_outlined,
                                                    size: 14,
                                                    color: secondsRemaining < 25
                                                        ? Colors.red
                                                        : Colors.orange,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    remainingTime,
                                                    style: TextStyle(
                                                      color:
                                                          secondsRemaining < 25
                                                              ? Colors.red
                                                              : Colors.orange,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Center(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: canJoin
                                            ? AppColors.button
                                            : LinearGradient(
                                                colors: [
                                                  Colors.grey[400]!,
                                                  Colors.grey[500]!,
                                                ],
                                              ),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: canJoin
                                            ? () {
                                                // Route based on service type
                                                if (notification[
                                                        'service_id'] ==
                                                    1) {
                                                  // Chat service
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          ChatPage(
                                                        userId: notification[
                                                            'user_id'],
                                                        consultantId:
                                                            notification[
                                                                'consultant_id'],
                                                        orderId: notification[
                                                            'order_id'],
                                                        userFullname: notification[
                                                            'consultant_name'],
                                                        packName: notification[
                                                            'pack_name'],
                                                      ),
                                                    ),
                                                  );
                                                } else if (notification[
                                                        'service_id'] ==
                                                    2) {
                                                  // Call service
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          CallPage(
                                                        orderId: notification[
                                                            'order_id'],
                                                        userFullname: notification[
                                                            'consultant_name'],
                                                        userId: notification[
                                                            'consultant_id'],
                                                        packName: notification[
                                                            'pack_name'],
                                                      ),
                                                    ),
                                                  );
                                                } else if (notification[
                                                        'service_id'] ==
                                                    3) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          VideoCallPage(
                                                        orderId: notification[
                                                            'order_id'],
                                                        userFullname: notification[
                                                            'consultant_name'],
                                                        userId: notification[
                                                            'consultant_id'],
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  // For other services (like join class)
                                                  // Implement other navigation logic here
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'This feature is coming soon!',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            : null, // Button disabled if not time yet
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          shadowColor: Colors.transparent,
                                          disabledBackgroundColor:
                                              Colors.transparent,
                                          disabledForegroundColor:
                                              Colors.white70,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 15,
                                            vertical: 10,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              notification['service_id'] == 1
                                                  ? Icons.chat
                                                  : notification[
                                                              'service_id'] ==
                                                          2
                                                      ? Icons.call
                                                      : Icons.school,
                                              size: 16,
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              canJoin
                                                  ? (notification[
                                                              'service_id'] ==
                                                          1
                                                      ? 'Chat Now'
                                                      : notification[
                                                                  'service_id'] ==
                                                              2
                                                          ? 'Call Now'
                                                          : notification[
                                                                      'service_id'] ==
                                                                  3
                                                              ? 'Join Puja'
                                                              : 'Join Class')
                                                  : 'Wait',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
