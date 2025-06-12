import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:health_link/user_profile/account_settings_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../login_screen.dart';

class AppDrawer extends StatefulWidget {
  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with SingleTickerProviderStateMixin {
  String userName = "Loading...";
  String userRole = "Loading...";
  String? profileImageUrl;
  bool isLoading = false;
  bool isDataLoading = true;
  late AnimationController _animationController;

  final Color primaryColor = const Color(0xFF008080);
  final String baseUrl = 'http://192.168.1.8:8000';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    String? userId = prefs.getString('user_id');

    if (token != null && userId != null) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/api/users/$userId/public'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final userData = json.decode(response.body);
          print(response.body);
          setState(() {
            userName = '${userData['first_name']} ${userData['last_name']}';
            userRole = _formatRole(userData['role']);
            profileImageUrl = userData['profile_image'];
            print(userName);
            print(userRole);
            print(userName);
            print(userName);

            isDataLoading = false;
          });
        } else {
          // Fallback to stored preferences if API call fails
          await _loadUserNameFromPrefs();
        }
      } catch (e) {
        print('Error loading user data: $e');
        // Fallback to stored preferences if API call fails
        await _loadUserNameFromPrefs();
      }
    } else {
      await _loadUserNameFromPrefs();
    }
  }

  Future<void> _loadUserNameFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? firstName = prefs.getString('first_name');
    String? lastName = prefs.getString('last_name');
    String? role = prefs.getString('role');

    setState(() {
      userName = firstName != null && lastName != null
          ? '$firstName $lastName'
          : 'User';
      userRole = role != null ? _formatRole(role) : 'Health Link User';
      isDataLoading = false;
    });
  }

  String _formatRole(String role) {
    switch (role.toLowerCase()) {
      case 'patient':
        return 'Patient';
      case 'doctor':
        return 'Doctor';
      case 'admin':
        return 'Administrator';
      default:
        return 'Health Link User';
    }
  }

  Future<void> _logout(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token != null) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/api/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          await prefs.clear();
          _navigateToLogin(context);
        } else {
          _showErrorSnackbar(context, "Logout failed. Please try again.");
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        _showErrorSnackbar(
            context, "Network error. Please check your connection.");
        setState(() {
          isLoading = false;
        });
      }
    } else {
      await prefs.clear();
      _navigateToLogin(context);
    }
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.white,
      ),
      child: Drawer(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.5, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutCubic,
            )),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildMenuItem(
                  icon: Icons.home_rounded,
                  title: "Home",
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildMenuItem(
                  icon: Icons.settings_rounded,
                  title: "Account Settings",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AccountSettingsScreen()),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.notifications_rounded,
                  title: "Notifications",
                  onTap: () {
                    Navigator.pop(context);
                    // Add your notifications screen navigation here
                  },
                ),
                _buildMenuItem(
                  icon: Icons.help_rounded,
                  title: "Help & Support",
                  onTap: () {
                    Navigator.pop(context);
                    // Add your help screen navigation here
                  },
                ),
                const Spacer(),
                _buildLogoutButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: profileImageUrl != null
                    ? Image.network(
                        profileImageUrl!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, _, __) => Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: primaryColor,
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 64,
                            height: 64,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: primaryColor,
                                strokeWidth: 2,
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      )
                    : Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: primaryColor,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isDataLoading
                    ? Container(
                        height: 20,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    : Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                const SizedBox(height: 4),
                isDataLoading
                    ? Container(
                        height: 14,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    : Text(
                        userRole,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: isLoading ? null : () => _logout(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red.shade700,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.red.shade300),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    "Logout",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
