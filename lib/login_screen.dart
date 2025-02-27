import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString("saved_email");
    String? savedPassword = prefs.getString("saved_password");

    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse("http://10.0.2.2:8000/api/login");
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('token') && data['token'] != null) {
          await _saveSession(data['token']);
        } else {
          _showError("Invalid response from server: Missing token.");
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showError(errorData['message'] ?? "Login failed.");
      }
    } catch (e) {
      _showError("Error connecting to the server.");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveSession(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("auth_token", token);

    if (_rememberMe) {
      await prefs.setString("saved_email", _emailController.text);
      await prefs.setString("saved_password", _passwordController.text);
    } else {
      await prefs.remove("saved_email");
      await prefs.remove("saved_password");
    }

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen()));
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
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
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            SizedBox(height: 10),
            _buildTextField(_emailController, "Enter Email"),
            SizedBox(height: 15),
            _buildTextField(_passwordController, "Enter Password", obscureText: true),
            SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() => _rememberMe = value!);
                  },
                ),
                Text("Remember Me"),
                Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text("Forget Password", style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildButton("Login", _isLoading ? null : _login),
            SizedBox(height: 15),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen()));
              },
              child: Text("Don't have an account? Sign Up"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool obscureText = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 6,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onPressed,
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text(text, style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }
}
