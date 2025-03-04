import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UpdatePersonalInfoScreen extends StatefulWidget {
  @override
  _UpdatePersonalInfoScreenState createState() => _UpdatePersonalInfoScreenState();
}

class _UpdatePersonalInfoScreenState extends State<UpdatePersonalInfoScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _wilayaController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
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
        _firstNameController.text = data['first_name'];
        _lastNameController.text = data['last_name'];
        _phoneController.text = data['phone_number'] ?? "";
        _wilayaController.text = data['wilaya'] ?? "";
      });
    }
  }

  Future<void> _updatePersonalInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");

    final nameResponse = await http.put(
      Uri.parse("http://10.0.2.2:8000/api/user/update-name"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "first_name": _firstNameController.text,
        "last_name": _lastNameController.text,
        "password": _passwordController.text,
      }),
    );

    final phoneResponse = await http.put(
      Uri.parse("http://10.0.2.2:8000/api/user/update-phone"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "phone_number": _phoneController.text,
        "current_password": _passwordController.text,
      }),
    );

    final wilayaResponse = await http.put(
      Uri.parse("http://10.0.2.2:8000/api/user/update-wilaya"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "wilaya": _wilayaController.text,
        "current_password": _passwordController.text,
      }),
    );

    if (nameResponse.statusCode == 200 && phoneResponse.statusCode == 200 && wilayaResponse.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Personal info updated successfully!",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF60A499), // Success message color
        ),
      );
      Navigator.pop(context);
    } else {
      final nameError = jsonDecode(nameResponse.body);
      final phoneError = jsonDecode(phoneResponse.body);
      final wilayaError = jsonDecode(wilayaResponse.body);
      setState(() {
        _errorMessage = nameError['message'] ?? phoneError['message'] ?? wilayaError['message'] ?? "Failed to update personal info.";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false, String? errorText, bool isPassword = false}) {
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
        errorText: errorText,
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => obscureText = !obscureText),
        )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update Personal Info"),
        backgroundColor: Color(0xFF60A499),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(_firstNameController, "First Name"),
            SizedBox(height: 16),
            _buildTextField(_lastNameController, "Last Name"),
            SizedBox(height: 16),
            _buildTextField(_phoneController, "Phone Number"),
            SizedBox(height: 16),
            _buildTextField(_wilayaController, "Wilaya"),
            SizedBox(height: 16),
            _buildTextField(_passwordController, "Enter Password", obscureText: true, isPassword: true),
            SizedBox(height: 20),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _updatePersonalInfo,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Update Info"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF60A499), // Purple button
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
