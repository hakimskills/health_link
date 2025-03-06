import 'package:flutter/material.dart';
import 'package:health_link/user_profile/profile_screen.dart';
import '../login_screen.dart';

class HealthcareDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF60A499),
        title: Text("Healthcare Dashboard", style: TextStyle(color: Colors.white)),
      ),
      drawer: _buildDrawer(context),
      body: Center(
        child: Text(
          "Welcome to the Healthcare Dashboard!",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF60A499)),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF60A499)),
            accountName: Text("Healthcare Professional", style: TextStyle(color: Colors.white)),
            accountEmail: null,
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Color(0xFF60A499)),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person, color: Color(0xFF60A499)),
            title: Text("Profile"),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
            },
          ),
        ],
      ),
    );
  }
}
