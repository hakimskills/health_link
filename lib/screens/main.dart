import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'landing_page_screen.dart';
import 'dashboards/admin_dashboard.dart';
import 'dashboards/healthcare_dashboard.dart';
import 'dashboards/supplier_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String? token = prefs.getString('auth_token');
  String? role = prefs.getString('user_role');





  Widget initialScreen;
  if (token != null && role != null) {
    if (role == "Dentist" || role == "Doctor" || role == "Labo" || role == "Pharmacist") {
      initialScreen = HealthcareDashboard();
    } else if (role == "Supplier") {
      initialScreen = SupplierDashboard();
    } else if (role == "Admin") {
      initialScreen = AdminDashboard();
    } else {
      initialScreen = LandingPageScreen();
    }
  }
  else {
    initialScreen = LandingPageScreen();
  }

  runApp(MyApp(initialScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;
  MyApp({required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedConnect',
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
        appBarTheme: AppBarTheme(
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
      home: initialScreen,
    );
  }
}