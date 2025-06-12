import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddStorePage extends StatefulWidget {
  @override
  _AddStorePageState createState() => _AddStorePageState();
}

class _AddStorePageState extends State<AddStorePage> {
  final _storeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // Create store function
  Future<void> _createStore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    String? userId = prefs.getString('user_id');

    if (token != null && userId != null) {
      try {
        final response = await http.post(
          Uri.parse('http://192.168.1.8:8000/api/store'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          body: {
            'store_name': _storeNameController.text,
            'address': _addressController.text,
            'phone': _phoneController.text,
            'owner_id': userId,
          },
        );

        if (response.statusCode == 201) {
          print("✅ Store Created Successfully");
          Navigator.pop(context); // Go back to the previous screen
        } else {
          print("❌ Failed to create store: ${response.body}");
        }
      } catch (e) {
        print("⚠️ Error creating store: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add New Store"),
        backgroundColor: Color(0xFF008080),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _storeNameController,
                decoration: InputDecoration(labelText: 'Store Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter store name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Address'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _createStore();
                  }
                },
                child: Text('Create Store'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF008080)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
