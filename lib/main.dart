import "package:flutter/material.dart";
import 'pages/DailyHoroscope.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:saamay/pages/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saamay/pages/splash_screen.dart';
import 'package:saamay/pages/DailyHoroscope.dart';
import 'package:saamay/pages/Kundlimatching.dart';
import 'package:saamay/pages/astrologers.dart';
import 'package:saamay/pages/bookPuja.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:facebook_app_events/facebook_app_events.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    //print('Firebase initialized successfully');
  } catch (e) {
    //print('Error initializing Firebase: $e');
    // Continue with app initialization even if Firebase fails
  }

  // Initialize app
  runApp(const MyApp());
}

// OLD COMPLEX GoRouter configuration - COMMENTED OUT
/*
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => InitialScreen(),
    ),
    GoRoute(
      path: '/daily-horoscope',
      builder: (context, state) => DailyHoroscope(),
    ),
    GoRoute(
      path: '/kundli-matching',
      builder: (context, state) => KundliMatching(),
    ),
    GoRoute(
      path: '/astrologer-listing',
      builder: (context, state) => AstrologersPage(title: "All"),
    ),
    GoRoute(
      path: '/book-puja',
      builder: (context, state) => BookPuja(),
    ),
  ],
  // Handle unknown routes - redirect to browser
  onException: (context, state, exception) {
    final uri = state.uri;
    if (uri.host == 'saamay.in' &&
        ![
          '/',
          '/daily-horoscope',
          '/kundli-matching',
          '/astrologer-listing',
          '/book-puja'
        ].contains(uri.path)) {
      _launchURL(uri.toString());
      return;
    }
  },
  redirect: (context, state) {
    final uri = state.uri;
    // If it's saamay.co but not one of our handled routes, redirect to browser
    if (uri.host == 'saamay.co' &&
        ![
          '/',
          '/daily-horoscope',
          '/kundli-matching',
          '/astrologer-listing',
          '/book-puja'
        ].contains(uri.path)) {
      _launchURL(uri.toString());
      return '/'; // Return to home after launching browser
    }
    return null; // No redirect needed
  },
);
*/

// NEW SIMPLIFIED GoRouter configuration
// Any saamay.in link will simply open the app at InitialScreen
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    // Catch-all route - matches any path and always opens InitialScreen
    GoRoute(path: '/:path(.*)', builder: (context, state) => InitialScreen()),
  ],
  redirect: (context, state) {
    final uri = state.uri;
    // If it's saamay.in domain, always redirect to home (InitialScreen)
    if (uri.host == 'saamay.in') {
      return '/';
    }
    return null; // No redirect needed for other cases
  },
);

// OLD Function to launch URL in browser - COMMENTED OUT (no longer needed)
/*
Future<void> _launchURL(String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
*/

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Saamay",
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      routerConfig: _router,
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({Key? key}) : super(key: key);

  @override
  _InitialScreenState createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  bool _isLoading = true;
  bool _isFirstLaunch = true;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunchAndPermissions();
  }

  Future _checkFirstLaunchAndPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstLaunch = prefs.getBool('first_launch') ?? true;

    await _requestPermissions();

    // Get current date and time
    final now = DateTime.now();
    final currentTime = "${now.hour}:${now.minute}:${now.second}";
    final currentDate = "${now.year}-${now.month}-${now.day}";

    // Log app_opened event to Facebook Analytics
    final facebookAppEvents = FacebookAppEvents();
    facebookAppEvents.logEvent(
      name: 'app_opened',
      parameters: {
        'time': currentTime,
        'date': currentDate,
        'is_first_launch': isFirstLaunch,
      },
    );

    if (isFirstLaunch) {
      // Subscribe to "installed" topic on first ever launch
      await FirebaseMessaging.instance.subscribeToTopic('installed');
      await prefs.setBool('first_launch', false);

      setState(() {
        _isFirstLaunch = isFirstLaunch;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isFirstLaunch = false;
        _isLoading = false;
      });
    }
  }

  // Request all necessary permissions
  Future<void> _requestPermissions() async {
    // Request permissions
    List<Permission> permissions = [
      Permission.microphone,
      Permission.phone,
      Permission.bluetooth,
      Permission.camera,
      Permission.notification,
    ];

    // Add storage permissions based on Android version
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt <= 32) {
        // For Android 12 and below
        permissions.addAll([Permission.storage]);
      } else {
        // For Android 13 and above
        permissions.addAll([
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ]);
      }
    }

    // For iOS, add photo library permission
    if (Platform.isIOS) {
      permissions.add(Permission.photos);
    }

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    // Check if all permissions are granted
    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (status != PermissionStatus.granted &&
          status != PermissionStatus.limited) {
        allGranted = false;
        //print('Permission ${permission.toString()} status: ${status.toString()}');
      }
    });

    // FIXED: Corrected setState syntax
    setState(() {
      _permissionsGranted = allGranted;
    });
  }

  // Show the permission dialog if some permissions were denied
  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          title: Text(
            'Permissions Required',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF89216B),
            ),
          ),
          content: Text(
            'This app requires certain permissions to function properly. Please grant the necessary permissions in the app settings.',
            style: GoogleFonts.poppins(color: Colors.grey[700]),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF89216B),
              ),
              child: Text(
                'Open Settings',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF89216B),
              ),
              child: Text(
                'Continue Anyway',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show loading indicator while checking preferences
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/saamaywelcome.png', height: 200),
              const SizedBox(height: 30),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF89216B)),
              ),
              const SizedBox(height: 20),
              Text(
                'Initializing...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Check if permissions need to be shown again
      if (!_permissionsGranted) {
        // Use a post-frame callback to show the dialog after the build is complete
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPermissionDialog();
        });
      }

      // If it's not the first launch, show the splash screen
      return const SplashScreen();
    }
  }
}
