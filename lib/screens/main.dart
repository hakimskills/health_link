import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboards/admin_dashboard.dart';
import 'dashboards/healthcare_dashboard.dart';
import 'dashboards/supplier_dashboard.dart';
import 'landing_page_screen.dart';

// Background message handler (must be top-level or static)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAzYAALkNoZY6w1TMO_ZqfEXcscLH8B6_U",
      appId: "1:250155480589:android:d3a5991dcf9c9bcba40744",
      messagingSenderId: "250155480589",
      projectId: "healthlinkdz",
      storageBucket: "healthlinkdz.firebasestorage.app",
    ),
  );
  print('Handling background message: ${message.notification?.title}');
  // Add logic to process background notifications (e.g., save to local storage)
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAzYAALkNoZY6w1TMO_ZqfEXcscLH8B6_U",
      appId: "1:250155480589:android:d3a5991dcf9c9bcba40744",
      messagingSenderId: "250155480589",
      projectId: "healthlinkdz",
      storageBucket: "healthlinkdz.firebasestorage.app",
    ),
  );

  // Set up FCM background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request notification permissions
  await setupFCM();

  // Get initial screen based on auth state
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token');
  String? role = prefs.getString('user_role');

  // Save device token after getting auth token
  if (token != null) {
    await saveDeviceToken(token);
  }

  Widget initialScreen = getInitialScreen(token, role);

  runApp(MyApp(initialScreen: initialScreen));
}

// Request FCM permissions
Future<void> setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission (required for iOS, optional for Android)
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted notification permission');
  } else {
    print('User declined or has not accepted permission');
  }

  // Handle iOS APNs token
  await messaging.getAPNSToken();
}

// Save device token to Laravel backend
Future<void> saveDeviceToken(String authToken) async {
  try {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      final response = await http.post(
        Uri.parse(
            'https://192.168.43.101/api/device-token'), // Replace with your API URL
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'device_token': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        print('Device token saved successfully');
      } else {
        print('Failed to save device token: ${response.body}');
      }
    }
  } catch (e) {
    print('Error saving device token: $e');
  }
}

// Handle token refresh
void setupTokenRefresh(String authToken) {
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    await saveDeviceToken(authToken);
    print('FCM token refreshed: $newToken');
  });
}

Widget getInitialScreen(String? token, String? role) {
  if (token != null && role != null) {
    switch (role) {
      case "Dentist":
      case "Doctor":
      case "Pharmacist":
        return HealthcareDashboard();
      case "Supplier":
        return SupplierDashboard();
      case "Admin":
        return AdminDashboard();
      default:
        return LandingPageScreen();
    }
  }
  return LandingPageScreen();
}

class MyApp extends StatefulWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Handle foreground and opened notifications
    setupNotificationHandlers();
  }

  void setupNotificationHandlers() {
    // Foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground notification: ${message.notification?.title}');
      if (message.notification != null) {
        // Show a snackbar or dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${message.notification?.title}: ${message.notification?.body}',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });

    // Handle notifications when app is opened from background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from notification: ${message.notification?.title}');
      // Navigate to relevant screen (e.g., order details)
      if (message.data['order_id'] != null) {
        Navigator.pushNamed(
          context,
          '/order-details', // Define this route in MaterialApp
          arguments: message.data['order_id'],
        );
      }
    });

    // Handle notifications when app is opened from terminated state
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        print(
            'App opened from terminated state: ${message.notification?.title}');
        if (message.data['order_id'] != null) {
          Navigator.pushNamed(
            context,
            '/order-details',
            arguments: message.data['order_id'],
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HealthLink',
      theme: ThemeData(
        primarySwatch: MaterialColor(
          0xFF008080,
          <int, Color>{
            50: Color(0xFFE0F2F2),
            100: Color(0xFFB3E0E0),
            200: Color(0xFF80CDCD),
            300: Color(0xFF4DBABA),
            400: Color(0xFF26ACAC),
            500: Color(0xFF008080),
            600: Color(0xFF007878),
            700: Color(0xFF006D6D),
            800: Color(0xFF006363),
            900: Color(0xFF005050),
          },
        ),
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Color(0xFF008080)),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 5,
            padding: EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      // Define routes for navigation
      routes: {
        '/order-details': (context) => OrderDetailsScreen(
              orderId: ModalRoute.of(context)!.settings.arguments as String,
            ),
      },
      home: widget.initialScreen,
    );
  }
}

// Placeholder for OrderDetailsScreen (implement based on your app)
class OrderDetailsScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order #$orderId')),
      body: Center(child: Text('Details for Order #$orderId')),
    );
  }
}
