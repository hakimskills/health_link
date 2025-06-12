import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:health_link/screens/reusable component/app_drawer.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<dynamic> _registrationRequests = [];
  bool _isLoading = true;
  bool _isError = false;
  final Color tealColor = Color(0xFF008080);

  @override
  void initState() {
    super.initState();
    _fetchRegistrationRequests();
  }

  Future<void> _fetchRegistrationRequests() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");

    final response = await http.get(
      Uri.parse("http://192.168.1.8:8000/api/admin/registration-requests"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      setState(() {
        _registrationRequests =
            List<Map<String, dynamic>>.from(responseData['requests'] ?? []);
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
      Uri.parse("http://192.168.1.8:8000/api/admin/${action}-request/$id"),
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
          content: Text(
            action == "approve" ? "Request Approved" : "Request Rejected",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: action == "approve" ? tealColor : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to process request"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
    }
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.person_outline, color: tealColor),
              SizedBox(width: 8),
              Text("Request Details",
                  style:
                      TextStyle(color: tealColor, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                    "Name", "${request['first_name']} ${request['last_name']}"),
                _buildDetailRow("Email", "${request['email']}"),
                _buildDetailRow("Phone", "${request['phone_number']}"),
                _buildDetailRow("Wilaya", "${request['wilaya']}"),
                _buildDetailRow("Role", "${request['role']}"),
                _buildDetailRow("Status", "${request['status']}"),
                _buildDetailRow("Requested On", "${request['created_at']}"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close", style: TextStyle(color: Colors.grey)),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.check, size: 18),
              label: Text("Approve"),
              onPressed: () {
                _approveRequest(request['id']);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: tealColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.close, size: 18),
              label: Text("Reject"),
              onPressed: () {
                _rejectRequest(request['id']);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: tealColor,
        elevation: 0,
        title: Text(
          "Admin Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _fetchRegistrationRequests();
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: tealColor))
          : _isError
              ? _buildErrorState()
              : _registrationRequests.isEmpty
                  ? _buildEmptyState()
                  : _buildRequestsList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
          SizedBox(height: 16),
          Text(
            "Failed to load registration requests",
            style: TextStyle(
              color: Colors.red[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text("Try Again"),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _fetchRegistrationRequests();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: tealColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline,
              size: 64, color: tealColor.withOpacity(0.7)),
          SizedBox(height: 16),
          Text(
            "No pending registration requests",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "All caught up! Check back later.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text("Refresh"),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _fetchRegistrationRequests();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: tealColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _registrationRequests.length,
      itemBuilder: (context, index) {
        final request = _registrationRequests[index];

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showRequestDetails(request),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: tealColor.withOpacity(0.1),
                        child: Text(
                          "${request['first_name'][0]}${request['last_name'][0]}",
                          style: TextStyle(
                            color: tealColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${request['first_name']} ${request['last_name']}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "${request['email']}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${request['role']}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Wilaya: ${request['wilaya']}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        "Phone: ${request['phone_number']}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          icon: Icon(Icons.check, size: 18),
                          label: Text("Approve"),
                          onPressed: () => _approveRequest(request['id']),
                          style: TextButton.styleFrom(
                            foregroundColor: tealColor,
                          ),
                        ),
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          icon: Icon(Icons.close, size: 18),
                          label: Text("Reject"),
                          onPressed: () => _rejectRequest(request['id']),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
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
  }

  Widget _buildDrawer(BuildContext context) {
    return AppDrawer();
  }

// Removed _logout method as it's handled by AppDrawer
}
