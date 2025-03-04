import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UpdateEmailScreen extends StatefulWidget {
  @override
  _UpdateEmailScreenState createState() => _UpdateEmailScreenState();
}

class _UpdateEmailScreenState extends State<UpdateEmailScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentEmail();
  }

  Future<void> _fetchCurrentEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");

    final response = await http.get(
      Uri.parse("http://10.0.2.2:8000/api/user"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _emailController.text = data['email'];
      });
    }
  }

  Future<void> _updateEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");

    final response = await http.put(
      Uri.parse("http://10.0.2.2:8000/api/user/update-email"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": _emailController.text,
        "current_password": _passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Email updated successfully!",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF60A499), // Success message color
        ),
      );
      Navigator.pop(context);
    } else {
      final errorData = jsonDecode(response.body);
      setState(() {
        _errorMessage = errorData['message'] ?? "Failed to update email.";
      });
    }

    setState(() {
      _isLoading = false;
    });
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
            icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility),
            onPressed: () =>
                setState(() => _passwordVisible = !_passwordVisible),
          )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update Email"),
        backgroundColor: Color(0xFF60A499),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(_emailController, "New Email"),
            SizedBox(height: 16),
            _buildTextField(_passwordController, "Enter Password",
                obscureText: !_passwordVisible, isPassword: true),
            SizedBox(height: 20),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateEmail,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Update Email"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF60A499), // Button color
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
