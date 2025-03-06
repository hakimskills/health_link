import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:health_link/user_profile/profile_screen.dart';
import '../login_screen.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<dynamic> _registrationRequests = [];
  bool _isLoading = true;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _fetchRegistrationRequests();
  }

  Future<void> _fetchRegistrationRequests() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");

    final response = await http.get(
      Uri.parse("http://10.0.2.2:8000/api/admin/registration-requests"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    print(response.body); // Debugging step

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      setState(() {
        _registrationRequests = List<Map<String, dynamic>>.from(responseData['requests'] ?? []);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _approveRequest(int id) async {
    await _handleRequest(id, "approve");
  }

  Future<void> _rejectRequest(int id) async {
    await _handleRequest(id, "reject");
  }

  Future<void> _handleRequest(int id, String action) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");

    final response = await http.post(
      Uri.parse("http://10.0.2.2:8000/api/admin/${action}-request/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _registrationRequests.removeWhere((request) => request['id'] == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == "approve" ? "Request Approved" : "Request Rejected"),
          backgroundColor: action == "approve" ? Colors.green : Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to process request"), backgroundColor: Colors.red),
      );
    }
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Request Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Name: ${request['first_name']} ${request['last_name']}"),
              Text("Email: ${request['email']}"),
              Text("Phone: ${request['phone_number']}"),
              Text("Wilaya: ${request['wilaya']}"),
              Text("Role: ${request['role']}"),
              Text("Status: ${request['status']}"),
              Text("Requested On: ${request['created_at']}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                _approveRequest(request['id']);
                Navigator.pop(context);
              },
              child: Text("Approve", style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () {
                _rejectRequest(request['id']);
                Navigator.pop(context);
              },
              child: Text("Reject", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF60A499),
        title: Text("Admin Dashboard", style: TextStyle(color: Colors.white)),
      ),
      drawer: _buildDrawer(context),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF60A499)))
          : _isError
          ? Center(child: Text("Failed to load registration requests", style: TextStyle(color: Colors.red)))
          : _buildRequestsList(),
    );
  }

  Widget _buildRequestsList() {
    return ListView.builder(
      padding: EdgeInsets.all(10),
      itemCount: _registrationRequests.length,
      itemBuilder: (context, index) {
        final request = _registrationRequests[index];

        return Card(
          margin: EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            onTap: () => _showRequestDetails(request),
            child: ListTile(
              title: Text("${request['first_name']} ${request['last_name']}"),
              subtitle: Text("Email: ${request['email']}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () => _approveRequest(request['id']),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () => _rejectRequest(request['id']),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF60A499)),
            accountName: Text("Admin", style: TextStyle(color: Colors.white)),
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
