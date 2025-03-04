import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _selectedRole;
  String? _selectedWilaya;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;

  final List<String> _roles = ["Healthcare Professional", "Supplier"];
  final List<String> _wilayas = [
    "Adrar", "Chlef", "Laghouat", "Oum El Bouaghi", "Batna", "Béjaïa", "Biskra", "Béchar", "Blida", "Bouira",
    "Tamanrasset", "Tébessa", "Tlemcen", "Tiaret", "Tizi Ouzou", "Algiers", "Djelfa", "Jijel", "Sétif", "Saïda",
    "Skikda", "Sidi Bel Abbès", "Annaba", "Guelma", "Constantine", "Médéa", "Mostaganem", "M'Sila", "Mascara",
    "Ouargla", "Oran", "El Bayadh", "Illizi", "Bordj Bou Arréridj", "Boumerdès", "El Tarf", "Tindouf", "Tissemsilt",
    "El Oued", "Khenchela", "Souk Ahras", "Tipaza", "Mila", "Aïn Defla", "Naâma", "Aïn Témouchent", "Ghardaïa",
    "Relizane", "Timimoun", "Bordj Badji Mokhtar", "Ouled Djellal", "Béni Abbès", "In Salah", "In Guezzam",
    "Touggourt", "Djanet", "El M'Ghair", "El Menia"
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8000/api/register"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "first_name": _firstNameController.text,
          "last_name": _lastNameController.text,
          "email": _emailController.text,
          "phone_number": _phoneController.text,
          "wilaya": _selectedWilaya,
          "role": _selectedRole,
          "password": _passwordController.text,
          "password_confirmation": _confirmPasswordController.text,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        _showErrorDialog(responseData['message'] ?? "Registration failed.");
      }
    } catch (e) {
      _showErrorDialog("An error occurred. Please try again.");
    }

    setState(() => _isLoading = false);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("OK")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Sign Up", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),

              _buildTextField(_firstNameController, "First Name", isName: true),
              SizedBox(height: 15),

              _buildTextField(_lastNameController, "Last Name", isName: true),
              SizedBox(height: 15),

              _buildDropdownField("Role", _selectedRole, _roles, (value) => setState(() => _selectedRole = value)),
              SizedBox(height: 15),

              _buildTextField(_phoneController, "Phone Number", isPhoneNumber: true),
              SizedBox(height: 15),

              _buildTextField(_emailController, "Email", isEmail: true),
              SizedBox(height: 15),

              _buildTextField(_passwordController, "Password", obscureText: !_passwordVisible, isPassword: true),
              SizedBox(height: 15),

              _buildTextField(_confirmPasswordController, "Confirm Password", obscureText: !_confirmPasswordVisible, isConfirmPassword: true),
              SizedBox(height: 15),

              _buildDropdownField("Wilaya", _selectedWilaya, _wilayas, (value) => setState(() => _selectedWilaya = value)),
              SizedBox(height: 20),

              _buildButton("Sign Up", _register, isLoading: _isLoading),
              SizedBox(height: 15),

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false, bool isPassword = false, bool isConfirmPassword = false, bool isPhoneNumber = false, bool isEmail = false, bool isName = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: isPhoneNumber ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF60A499), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF60A499), width: 1.5),
        ),
        suffixIcon: isPassword || isConfirmPassword
            ? IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() {
            if (isPassword) _passwordVisible = !_passwordVisible;
            if (isConfirmPassword) _confirmPasswordVisible = !_confirmPasswordVisible;
          }),
        )
            : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "$label is required";
        }

        if (isName && !RegExp(r"^[a-zA-Z\s-]+$").hasMatch(value)) {
          return "Only letters, spaces, and hyphens are allowed";
        }

        if (isPhoneNumber && !RegExp(r'^\d+$').hasMatch(value)) {
          return "Enter a valid phone number";
        }

        if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return "Enter a valid email";
        }

        if (isConfirmPassword && value != _passwordController.text) {
          return "Passwords do not match";
        }

        return null;
      },
    );
  }

  Widget _buildDropdownField(String label, String? selectedValue, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
      onChanged: onChanged,
      validator: (value) => value == null ? "$label is required" : null,
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

}
