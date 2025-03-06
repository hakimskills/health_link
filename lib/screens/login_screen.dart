import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dashboard_screen.dart';
import 'dashboards/admin_dashboard.dart';
import 'dashboards/healthcare_dashboard.dart';
import 'dashboards/supplier_dashboard.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart'; // Import Forgot Password Screen

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _loginError;

  void _validateAndLogin() {
    setState(() {
      _emailError = _emailController.text.isEmpty ? "Email is required" : null;
      _passwordError = _passwordController.text.isEmpty ? "Password is required" : null;
      _loginError = null;
    });

    if (_emailError == null && _passwordError == null) {
      _login();
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8000/api/login"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": _emailController.text,
          "password": _passwordController.text,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        String token = responseData['token'];
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", token);

        String role = responseData['user']['role']; // Get role from API

        Widget nextScreen;
        if (role == "Healthcare Professional") {
          nextScreen = HealthcareDashboard();
        } else if (role == "Supplier") {
          nextScreen = SupplierDashboard();
        } else if (role == "Admin") {
          nextScreen = AdminDashboard();
        } else {
          setState(() {
            _loginError = "Unknown role. Contact support.";
          });
          return;
        }

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => nextScreen));
      } else {
        setState(() {
          _loginError = responseData['message'] ?? "Login failed.";
        });
      }
    } catch (e) {
      setState(() {
        _loginError = "An error occurred. Please try again.";
      });
    }

    setState(() => _isLoading = false);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset("assets/login_image.jpg", height: 150),
            SizedBox(height: 20),
            Text(
              "Login Page",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            if (_loginError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _loginError!,
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),

            _buildTextField(_emailController, "Email", errorText: _emailError),
            SizedBox(height: 15),
            _buildTextField(_passwordController, "Password",
                obscureText: !_passwordVisible, errorText: _passwordError, isPassword: true),

            // Forgot Password Text Button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ForgotPasswordScreen()), // Navigate to Forgot Password
                  );
                },
                child: Text(
                  "Forgot Password?",
                  style: TextStyle(color: Color(0xFF60A499), fontWeight: FontWeight.bold),
                ),
              ),
            ),

            SizedBox(height: 20),

            _buildButton("Login", _validateAndLogin, isLoading: _isLoading),
            SizedBox(height: 15),

            _buildNewClientButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false, String? errorText, bool isPassword = false}) {
    return Theme(
      data: ThemeData(
        primaryColor: Colors.grey,
        hintColor: Colors.grey,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFF60A499), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFF60A499), width: 2),
          ),
          errorText: errorText,
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, {bool isLoading = false}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF60A499),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text(text, style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }

  Widget _buildNewClientButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Color(0xFF60A499), width: 2),
          ),
        ),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen()));
        },
        child: Text(
          "New Client",
          style: TextStyle(fontSize: 18, color: Color(0xFF60A499)),
        ),
      ),
    );
  }
}
