import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'update_personal_info.dart';
import 'update_password.dart';
import 'update_email.dart';

class AccountSettingsScreen extends StatelessWidget {
  final Color primaryColor = const Color(0xFF008080);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Account Settings",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildSectionTitle(context, "Account"),
              _buildSettingsCard(
                context,
                children: [
                  _buildProfileItem(
                    context,
                    iconPath: "assets/user.svg",
                    title: "Personal Information",
                    subtitle: "Name, date of birth, address",
                    onTap: () => _navigateWithAnimation(
                      context,
                      UpdatePersonalInfoScreen(),
                    ),
                  ),
                  _buildDivider(),
                  _buildProfileItem(
                    context,
                    iconPath: "assets/lock.svg",
                    title: "Change Password",
                    subtitle: "Update your security credentials",
                    onTap: () => _navigateWithAnimation(
                      context,
                      UpdatePasswordScreen(),
                    ),
                  ),
                  _buildDivider(),
                  _buildProfileItem(
                    context,
                    iconPath: "assets/email.svg",
                    title: "Update Email",
                    subtitle: "Change your contact email",
                    onTap: () => _navigateWithAnimation(
                      context,
                      UpdateEmailScreen(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(context, "Preferences"),
              _buildSettingsCard(
                context,
                children: [
                  _buildToggleItem(
                    context,
                    iconPath: "assets/notification.svg",
                    title: "Notifications",
                    subtitle: "Enable push notifications",
                    value: true,
                    onChanged: (value) {},
                  ),
                  _buildDivider(),
                  _buildToggleItem(
                    context,
                    iconPath: "assets/theme.svg",
                    title: "Dark Mode",
                    subtitle: "Switch between light and dark themes",
                    value: false,
                    onChanged: (value) {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(context, "Help & Support"),
              _buildSettingsCard(
                context,
                children: [
                  _buildProfileItem(
                    context,
                    iconPath: "assets/help.svg",
                    title: "Help Center",
                    subtitle: "Get help with Health Link",
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildProfileItem(
                    context,
                    iconPath: "assets/about.svg",
                    title: "About",
                    subtitle: "App version, terms & conditions",
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_rounded,
              color: primaryColor,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Account Security",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Your account is secure",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.security_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildProfileItem(
      BuildContext context, {
        required String iconPath,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SvgPicture.asset(
                iconPath,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(
                  primaryColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(
      BuildContext context, {
        required String iconPath,
        required String title,
        required String subtitle,
        required bool value,
        required ValueChanged<bool> onChanged,
      }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SvgPicture.asset(
              iconPath,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                primaryColor,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      endIndent: 16,
      color: Colors.grey.shade200,
    );
  }

  void _navigateWithAnimation(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }
}