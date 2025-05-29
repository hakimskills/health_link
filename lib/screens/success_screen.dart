import 'package:flutter/material.dart';
import 'login_screen.dart';

class SuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Color tealColor = Color(0xFF008080);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Custom success icon with animation
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: tealColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            size: 80,
                            color: tealColor,
                          ),
                        ),
                        SizedBox(height: 32),

                        // Title with the primary teal color
                        Text(
                          "Registration Submitted!",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: tealColor,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 16),

                        // Message with slightly improved typography
                        Text(
                          "Your registration request has been submitted successfully. You will receive an email once an admin reviews and approves it.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 48),

                        // Modern elevated button with teal color
                        Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tealColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => LoginScreen())
                              );
                            },
                            child: Text(
                              "Go to Login",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                        // Secondary action
                        TextButton(
                          onPressed: () {
                            // Handle contact support
                          },
                          child: Text(
                            "Need help?",
                            style: TextStyle(
                              color: tealColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Subtle footer
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  "Thank you for registering",
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}