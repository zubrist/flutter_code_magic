// notification_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:saamay/pages/chat/screens/chat_page.dart';
import 'package:saamay/pages/colors.dart';
import 'package:saamay/pages/config.dart';
import 'package:saamay/pages/call.dart';
import 'package:saamay/pages/videoCall.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Timer for checking upcoming notifications
  Timer? _checkTimer;

  // Map to store notification data that we've already alerted about
  final Map<String, bool> _alertedNotifications = {};

  // BuildContext for showing dialogs
  BuildContext? _context;

  // Stream controller to broadcast notification events to the app
  final _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStreamController.stream;

  // Start the notification service
  void initialize(BuildContext context) {
    _context = context;

    // Check for notifications every 15 seconds
    _checkTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      _checkUpcomingNotifications();
    });

    // Do an initial check immediately
    _checkUpcomingNotifications();
  }

  // Dispose resources
  void dispose() {
    _checkTimer?.cancel();
    _notificationStreamController.close();
  }

  // Set context from different parts of the app
  void updateContext(BuildContext context) {
    _context = context;
  }

  // Check for upcoming notifications that need alerts
  Future<void> _checkUpcomingNotifications() async {
    if (_context == null || !_context!.mounted) return;

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
        notificationcount = data['data'].length.toString();
        final List<dynamic> notifications = data['data'] ?? [];

        // Check each notification
        for (var notification in notifications) {
          final String orderId = notification['order_id'].toString();
          final String startTime = notification['start_time'].toString();

          // Check if it's time to join (exactly at or after start time)
          if (_isTimeToJoin(startTime)) {
            // Only alert if we haven't already alerted for this notification
            if (!_alertedNotifications.containsKey(orderId)) {
              _alertedNotifications[orderId] = true;

              // Broadcast notification to app
              _notificationStreamController.add(notification);

              // Show alert dialog
              _showNotificationDialog(_context!, notification);
            }
          }
        }
      } else {
        notificationcount = '';
      }
    } catch (e) {
      //print('Error checking notifications: $e');
    }
  }

  // Check if it's time to join (exactly at or after start time)
  bool _isTimeToJoin(String startTime) {
    DateTime parsedStartTime = DateTime.parse(startTime).toLocal();
    DateTime now = DateTime.now();
    return now.isAfter(parsedStartTime) ||
        now.isAtSameMomentAs(parsedStartTime);
  }

  // Show alert dialog for notification
  void _showNotificationDialog(
    BuildContext context,
    Map<String, dynamic> notification,
  ) {
    // Don't show if this context is no longer valid
    if (!context.mounted) {
      //print('Context not mounted, skipping dialog');
      return;
    }

    // Get the current widget type
    final currentWidgetType = context.widget.runtimeType;
    //print('Current widget: $currentWidgetType, Notification order_id: ${notification['order_id']}');

    // Define restricted pages
    final restrictedWidgets = [ChatPage, CallPage, VideoCallPage];

    // Check if the current widget is restricted
    final isOnRestrictedWidget = restrictedWidgets.contains(currentWidgetType);

    // Check if the notification is for the current session (same order_id)
    final routeArgs = ModalRoute.of(context)?.settings.arguments as Map?;
    final currentOrderId = routeArgs?['orderId']?.toString();
    final isSameSession = currentOrderId != null &&
        currentOrderId == notification['order_id'].toString();

    // Skip showing the dialog if the user is on a restricted page or it's the same session
    if (isOnRestrictedWidget || isSameSession) {
      //print('Skipping notification dialog: 'Restricted widget ($currentWidgetType) or same session (order_id: ${notification['order_id']})');
      return;
    }

    // Get the service type label
    String serviceType = 'Appointment';
    if (notification['service_id'] == 1) {
      serviceType = 'Chat';
    } else if (notification['service_id'] == 2) {
      serviceType = 'Call';
    } else if (notification['service_id'] == 3) {
      serviceType = 'Video Call';
    } else {
      serviceType = 'Class';
    }

    // Show the dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.orange),
              SizedBox(width: 10),
              Text('$serviceType Time!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your ${notification['con_category']} session with ${notification['consultant_name']} is starting now!',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'Would you like to join?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                'Later',
                style: TextStyle(color: AppColors.textLight),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: Text('Join Now'),
              onPressed: () {
                Navigator.of(dialogContext).pop();

                // Navigate based on service type
                int serviceId = notification['service_id'];
                if (serviceId == 1) {
                  // Chat service
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        userId: notification['user_id'],
                        consultantId: notification['consultant_id'],
                        orderId: notification['order_id'],
                        userFullname: notification['consultant_name'],
                      ),
                      settings: RouteSettings(
                        arguments: {'orderId': notification['order_id']},
                      ),
                    ),
                  );
                } else if (serviceId == 2) {
                  // Call service
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CallPage(
                        orderId: notification['order_id'],
                        userFullname: notification['consultant_name'],
                        userId: notification['consultant_id'],
                      ),
                      settings: RouteSettings(
                        arguments: {'orderId': notification['order_id']},
                      ),
                    ),
                  );
                } else if (serviceId == 3) {
                  // Video Call service
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoCallPage(
                        orderId: notification['order_id'],
                        userFullname: notification['consultant_name'],
                        userId: notification['consultant_id'],
                      ),
                      settings: RouteSettings(
                        arguments: {'orderId': notification['order_id']},
                      ),
                    ),
                  );
                } else {
                  // Handle other service types if needed
                  //print('Service type $serviceId not implemented yet');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}
