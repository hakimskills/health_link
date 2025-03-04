import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UpdatePasswordScreen extends StatefulWidget {
  @override
  _UpdatePasswordScreenState createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _passwordVisible1 = false;
  bool _passwordVisible2 = false;
  bool _passwordVisible3 = false;

  Future<void> _updatePassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "New password and confirmation do not match.";
        _isLoading = false;
      });
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");

    final response = await http.put(
      Uri.parse("http://10.0.2.2:8000/api/user/update-password"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "current_password": _currentPasswordController.text,
        "new_password": _newPasswordController.text,
        "new_password_confirmation": _confirmPasswordController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Password updated successfully!",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF60A499), // Success message color
        ),
      );
      Navigator.pop(context);
    } else {
      final errorData = jsonDecode(response.body);
      setState(() {
        _errorMessage = errorData['message'] ?? "Failed to update password.";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        bool obscureText = false,
        bool isPassword = false,
        required VoidCallback toggleVisibility,
      }) {
    return TextFormField(
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
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: toggleVisibility,
        )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update Password"),
        backgroundColor: Color(0xFF60A499),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(
              _currentPasswordController,
              "Current Password",
              obscureText: !_passwordVisible1,
              isPassword: true,
              toggleVisibility: () => setState(() => _passwordVisible1 = !_passwordVisible1),
            ),
            SizedBox(height: 16),
            _buildTextField(
              _newPasswordController,
              "New Password",
              obscureText: !_passwordVisible2,
              isPassword: true,
              toggleVisibility: () => setState(() => _passwordVisible2 = !_passwordVisible2),
            ),
            SizedBox(height: 16),
            _buildTextField(
              _confirmPasswordController,
              "Confirm New Password",
              obscureText: !_passwordVisible3,
              isPassword: true,
              toggleVisibility: () => setState(() => _passwordVisible3 = !_passwordVisible3),
            ),
            SizedBox(height: 20),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _updatePassword,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Update Password"),
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
