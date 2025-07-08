import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UpdatePersonalInfoScreen extends StatefulWidget {
  @override
  _UpdatePersonalInfoScreenState createState() =>
      _UpdatePersonalInfoScreenState();
}

class _UpdatePersonalInfoScreenState extends State<UpdatePersonalInfoScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _wilayaController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");

    try {
      final response = await http.get(
        Uri.parse("http://192.168.43.101:8000/api/user"),
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
      } else {
        setState(() {
          _errorMessage = "Could not load user data. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Network error. Please check your connection.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^\d{9,}$'); // At least 9 digits
    return phoneRegex.hasMatch(phone);
  }

  Future<void> _updatePersonalInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _wilayaController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = "All fields are required.";
        _isLoading = false;
      });
      return;
    }

    if (!_isValidPhoneNumber(_phoneController.text)) {
      setState(() {
        _errorMessage = "Invalid phone number. It must be at least 9 digits.";
        _isLoading = false;
      });
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");

    try {
      final nameResponse = await http.put(
        Uri.parse("http://192.168.43.101:8000/api/user/update-name"),
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
        Uri.parse("http://192.168.43.101:8000/api/user/update-phone"),
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
        Uri.parse("http://192.168.43.101:8000/api/user/update-wilaya"),
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

      if (nameResponse.statusCode == 200 &&
          phoneResponse.statusCode == 200 &&
          wilayaResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Personal info updated successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(12),
          ),
        );
        Navigator.pop(context);
      } else {
        final nameError = jsonDecode(nameResponse.body);
        final phoneError = jsonDecode(phoneResponse.body);
        final wilayaError = jsonDecode(wilayaResponse.body);
        setState(() {
          _errorMessage = nameError['message'] ??
              phoneError['message'] ??
              wilayaError['message'] ??
              "Failed to update personal info.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Network error. Please check your connection.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 16,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Color(0xFF008080)),
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Color(0xFF008080), width: 1.5),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "PERSONAL INFORMATION",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading && _firstNameController.text.isEmpty
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF008080),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Text(
                        "Update your profile information",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 24),
                      _buildTextField(
                        _firstNameController,
                        "First Name",
                        Icons.person_outline,
                      ),
                      _buildTextField(
                        _lastNameController,
                        "Last Name",
                        Icons.person_outline,
                      ),
                      _buildTextField(
                        _phoneController,
                        "Phone Number",
                        Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField(
                        _wilayaController,
                        "Wilaya",
                        Icons.location_on_outlined,
                      ),
                      _buildTextField(
                        _passwordController,
                        "Enter Password",
                        Icons.lock_outline,
                        isPassword: true,
                      ),
                      if (_errorMessage != null)
                        Container(
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red.shade800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updatePersonalInfo,
                          child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  "UPDATE",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF008080),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
