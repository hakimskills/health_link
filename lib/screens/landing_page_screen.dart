import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'register_screen.dart';
import 'login_screen.dart';

class RoleOption {
  final String name;
  final String svgAsset;

  RoleOption({required this.name, required this.svgAsset});
}

class LandingPageScreen extends StatefulWidget {
  const LandingPageScreen({Key? key}) : super(key: key);

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  // Define our primary teal color
  final Color primaryColor = Color(0xFF008080);

  final List<RoleOption> roles = [
    RoleOption(
      name: "Doctor",
      svgAsset: "assets/doctor.svg",
    ),
    RoleOption(
      name: "Dentist",
      svgAsset: "assets/dentist.svg",
    ),
    RoleOption(
      name: "Labo",
      svgAsset: "assets/labo.svg",
    ),
    RoleOption(
      name: "Supplier",
      svgAsset: "assets/supplier.svg",
    ),
    RoleOption(
      name: "Pharmacie",
      svgAsset: "assets/pharmacy.svg",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF5F5F5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: size.height * 0.05),

              // Logo and App Name
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.2),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.medical_services_outlined,
                      size: 60,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "HealthLink",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Connect with healthcare professionals",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.06),

              // Role Selection Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Select your profession to get started",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 30),

              // Role Options Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: roles.length,
                    itemBuilder: (context, index) {
                      return _buildRoleCard(roles[index]);
                    },
                  ),
                ),
              ),

              // Already have an account section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 15,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginScreen()),
                        );
                      },
                      child: Text(
                        "Log In",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(RoleOption role) {
    return GestureDetector(
      onTap: () {
        // Navigate to register screen with selected role
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterScreen(selectedRole: role.name),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                role.svgAsset,
                height: 40,
                width: 40,
                colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
                // If SVG fails to load, show a fallback icon
                placeholderBuilder: (BuildContext context) => Icon(
                  Icons.person,
                  size: 40,
                  color: primaryColor,
                ),
              ),
            ),
            SizedBox(height: 15),
            Text(
              role.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}