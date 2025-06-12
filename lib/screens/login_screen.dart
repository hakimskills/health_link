import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboards/admin_dashboard.dart';
import 'dashboards/healthcare_dashboard.dart';
import 'dashboards/supplier_dashboard.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends HookWidget {
  LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Form controllers
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());

    // State hooks
    final isLoading = useState(false);
    final passwordVisible = useState(false);
    final loginError = useState<String?>(null);

    // Animation controller - simplified with no curve
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 1200),
    )..forward();

    // Theme
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF00857C);
    final secondaryColor = const Color(0xFF232F34);
    final bgColor = const Color(0xFFF8FAFC);
    Future<void> saveDeviceToken(String token) async {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      try {
        final response = await http.post(
          Uri.parse("http://192.168.1.8:8000/api/save-device-token"),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'device_token': fcmToken}),
        );

        if (response.statusCode == 200) {
          print("✅ FCM token saved to backend' " + response.body);
        } else {
          print("❌ Failed to save token: ${response.body}");
        }
      } catch (e) {
        print("❌ Error saving device token: $e");
      }
    }

    // Login function
    Future<void> login() async {
      if (!formKey.currentState!.validate()) return;

      loginError.value = null;
      isLoading.value = true;

      try {
        final response = await http.post(
          Uri.parse("http://192.168.1.8:8000/api/login"),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "email": emailController.text,
            "password": passwordController.text,
          }),
        );

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          final user = responseData['user'];

          if (user['banned'] == true) {
            loginError.value = "Your account has been banned.";
            isLoading.value = false;
            return;
          }

          String token = responseData['token'];
          String role = user['role'];
          String userId = user['id'].toString();
          String firstName = user['first_name'];
          String lastName = user['last_name'];

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("auth_token", token);
          await prefs.setString("user_role", role);
          await prefs.setString("user_id", userId);
          await prefs.setString("first_name", firstName);
          await prefs.setString("last_name", lastName);

          await saveDeviceToken(token); // 👈 Save FCM token to Laravel backend

          Widget nextScreen;
          if (role == "Dentist" ||
              role == "Doctor" ||
              role == "Labo" ||
              role == "Pharmacist") {
            nextScreen = HealthcareDashboard();
          } else if (role == "Supplier") {
            nextScreen = SupplierDashboard();
          } else if (role == "Admin") {
            nextScreen = AdminDashboard();
          } else {
            loginError.value = "Unknown role. Contact support.";
            isLoading.value = false;
            return;
          }

          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  nextScreen,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        } else {
          loginError.value = responseData['message'] ?? "Login failed.";
          isLoading.value = false;
        }
      } catch (e) {
        loginError.value = "Connection error. Please check your internet.";
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background design elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.08),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Main content
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        // Logo
                        // Logo
                        // Replace this section in your code (around line 180-220):

// Logo with reduced spacing
                        Hero(
                          tag: 'app_logo',
                          child: Image.asset(
                            "assets/healthlink_logo.png",
                            height: 200, // Reduced from 280 to 200
                            width: 250, // Reduced from 280 to 200
                            fit: BoxFit.cover, // Ensure proper scaling
                          ),
                        )
                            .animate()
                            .fade(
                              duration: 800.ms,
                              delay: 300.ms,
                            )
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1.0, 1.0),
                              duration: 800.ms,
                              delay: 300.ms,
                            ),

                        Column(
                          children: [
                            Text(
                              "Welcome Back",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: secondaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Sign in to your account",
                              style: TextStyle(
                                fontSize: 16,
                                color: secondaryColor.withOpacity(0.6),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fade(
                              duration: 800.ms,
                              delay: 400.ms,
                            )
                            .slideY(
                              begin: 1,
                              end: 0,
                              duration: 800.ms,
                              delay: 400.ms,
                            ),

// You can also reduce this spacing if needed
                        const SizedBox(height: 30), // Reduced from 40 to 30
                        // Form
                        Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Error message
                              if (loginError.value != null)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  margin: const EdgeInsets.only(bottom: 20),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border:
                                        Border.all(color: Colors.red.shade200),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.06),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline,
                                          color: Colors.red[700], size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          loginError.value!,
                                          style: TextStyle(
                                            color: Colors.red[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(Icons.close,
                                            color: Colors.red[300], size: 18),
                                        onPressed: () =>
                                            loginError.value = null,
                                      ),
                                    ],
                                  ),
                                )
                                    .animate()
                                    .fade(
                                      duration: 400.ms,
                                    )
                                    .slideY(
                                      begin: -0.5,
                                      end: 0,
                                      duration: 400.ms,
                                    ),

                              // Email
                              _buildTextField(
                                controller: emailController,
                                label: "Email Address",
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return "Email is required";
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                      .hasMatch(value))
                                    return "Enter a valid email";
                                  return null;
                                },
                              )
                                  .animate()
                                  .fade(
                                    duration: 800.ms,
                                    delay: 500.ms,
                                  )
                                  .slideY(
                                    begin: 1,
                                    end: 0,
                                    duration: 800.ms,
                                    delay: 500.ms,
                                  ),

                              const SizedBox(height: 16),

                              // Password
                              _buildTextField(
                                controller: passwordController,
                                label: "Password",
                                prefixIcon: Icons.lock_outline,
                                obscureText: !passwordVisible.value,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    passwordVisible.value
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                  onPressed: () => passwordVisible.value =
                                      !passwordVisible.value,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return "Password is required";
                                  return null;
                                },
                              )
                                  .animate()
                                  .fade(
                                    duration: 800.ms,
                                    delay: 600.ms,
                                  )
                                  .slideY(
                                    begin: 1,
                                    end: 0,
                                    duration: 800.ms,
                                    delay: 600.ms,
                                  ),

                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation,
                                                secondaryAnimation) =>
                                            ForgotPasswordScreen(),
                                        transitionsBuilder: (context, animation,
                                            secondaryAnimation, child) {
                                          return FadeTransition(
                                              opacity: animation, child: child);
                                        },
                                        transitionDuration:
                                            const Duration(milliseconds: 400),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    textStyle: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  child: const Text("Forgot Password?"),
                                ),
                              ).animate().fade(
                                    duration: 800.ms,
                                    delay: 700.ms,
                                  ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: isLoading.value ? 0 : 4,
                              shadowColor: primaryColor.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: isLoading.value ? null : login,
                            child: isLoading.value
                                ? Container(
                                    height: 24,
                                    width: 24,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Sign In",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                          ),
                        )
                            .animate()
                            .fade(
                              duration: 800.ms,
                              delay: 800.ms,
                            )
                            .slideY(
                              begin: 1,
                              end: 0,
                              duration: 800.ms,
                              delay: 800.ms,
                            ),

                        const SizedBox(height: 24),

                        // Or divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "OR",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                          ],
                        ).animate().fade(
                              duration: 800.ms,
                              delay: 900.ms,
                            ),

                        const SizedBox(height: 24),

                        // Sign up button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              side: BorderSide(color: primaryColor, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      RegisterScreen(),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    return FadeTransition(
                                        opacity: animation, child: child);
                                  },
                                  transitionDuration:
                                      const Duration(milliseconds: 400),
                                ),
                              );
                            },
                            child: Text(
                              "Create New Account",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fade(
                              duration: 800.ms,
                              delay: 1000.ms,
                            )
                            .slideY(
                              begin: 1,
                              end: 0,
                              duration: 800.ms,
                              delay: 1000.ms,
                            ),

                        const Spacer(),

                        // Footer
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "© 2025 HealthLink",
                                style: TextStyle(
                                  color: secondaryColor.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fade(
                              duration: 800.ms,
                              delay: 1100.ms,
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required FormFieldValidator<String> validator,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 15,
        color: const Color(0xFF232F34),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                size: 20,
                color: const Color(0xFF00857C),
              )
            : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF00857C), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorStyle: TextStyle(
          fontSize: 12,
          color: Colors.red[700],
        ),
      ),
    );
  }
}
