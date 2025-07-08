import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RatingPopup {
  static Future<void> show(BuildContext context, int productId,
      Color primaryColor, VoidCallback onSuccess) async {
    int rating = 0;
    final reviewController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                constraints: const BoxConstraints(maxWidth: 380),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.star_rounded,
                          color: primaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        'Rate This Product',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'Your feedback helps others make better decisions',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Star Rating
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            final isSelected = index < rating;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  rating = index + 1;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.star_rounded,
                                  color: isSelected
                                      ? Colors.amber
                                      : Colors.grey[400],
                                  size: 28,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      if (rating > 0) ...[
                        const SizedBox(height: 24),

                        // Review Text Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: TextField(
                            controller: reviewController,
                            decoration: InputDecoration(
                              hintText: 'Share your thoughts... (optional)',
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(20),
                            ),
                            maxLines: 4,
                            minLines: 3,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey[600],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: rating == 0
                                    ? LinearGradient(
                                        colors: [
                                          Colors.grey[400]!,
                                          Colors.grey[400]!
                                        ],
                                      )
                                    : LinearGradient(
                                        colors: [
                                          primaryColor,
                                          primaryColor.withOpacity(0.8)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                boxShadow: rating == 0
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                              ),
                              child: ElevatedButton(
                                onPressed: rating == 0
                                    ? null
                                    : () async {
                                        try {
                                          final prefs = await SharedPreferences
                                              .getInstance();
                                          final token =
                                              prefs.getString('auth_token');
                                          final response = await http.post(
                                            Uri.parse(
                                                'http://192.168.43.101:8000/api/ratings'),
                                            headers: {
                                              'Accept': 'application/json',
                                              'Content-Type':
                                                  'application/json',
                                              'Authorization': 'Bearer $token',
                                            },
                                            body: json.encode({
                                              'product_id': productId,
                                              'rating': rating,
                                              'review':
                                                  reviewController.text.isEmpty
                                                      ? null
                                                      : reviewController.text,
                                            }),
                                          );

                                          if (response.statusCode == 201) {
                                            Navigator.pop(context);
                                            onSuccess();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .check_circle_rounded,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    const Text(
                                                      'Rating submitted successfully!',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                backgroundColor: primaryColor,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                margin:
                                                    const EdgeInsets.all(16),
                                                duration:
                                                    const Duration(seconds: 3),
                                              ),
                                            );
                                          } else {
                                            final errorData =
                                                json.decode(response.body);
                                            throw Exception(
                                                errorData['message'] ??
                                                    'Failed to submit rating');
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.error_outline_rounded,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      'Error: $e',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: Colors.red[600],
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              margin: const EdgeInsets.all(16),
                                              duration:
                                                  const Duration(seconds: 4),
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Submit Rating',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
