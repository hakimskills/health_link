import 'package:flutter/material.dart';
import 'update_personal_info.dart';
import 'update_password.dart';
import 'update_email.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Color(0xFF60A499),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          ListTile(
            leading: Icon(Icons.person, color: Color(0xFF60A499)),
            title: Text("Personal Information"),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => UpdatePersonalInfoScreen()));
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.lock, color: Color(0xFF60A499)),
            title: Text("Change Password"),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => UpdatePasswordScreen()));
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.email, color: Color(0xFF60A499)),
            title: Text("Update Email"),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateEmailScreen()));
            },
          ),
        ],
      ),
    );
  }
}
