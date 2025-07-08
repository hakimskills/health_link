import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:health_link/user_profile/update_personal_info.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/product_screen.dart';
import '../screens/used_equipment.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // Make userId optional

  const ProfileScreen({Key? key, this.userId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? firstName;
  String? lastName;
  File? _image;
  String? role;
  String? imageUrl;
  String? _userId; // Internal userId to store resolved ID
  String? _currentUserId; // Store the current authenticated user's ID
  List<dynamic> userStores = [];
  final picker = ImagePicker();
  bool _loading = true;
  bool _loadingStores = false;
  bool _isOwnProfile = false; // Track if viewing own profile

  final String baseUrl = 'http://192.168.43.101:8000';
  final Color primaryColor = const Color(0xFF008080);

  @override
  void initState() {
    super.initState();
    _resolveUserIdAndFetchData();
  }

  Future<void> _resolveUserIdAndFetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('user_id');

    // Resolve userId: use widget.userId if provided, otherwise get from SharedPreferences
    if (widget.userId != null) {
      _userId = widget.userId;
      _isOwnProfile = (_userId == _currentUserId);
    } else {
      _userId = _currentUserId;
      _isOwnProfile = true;
    }

    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");

    Uri apiUrl;
    Map<String, String> headers = {
      "Accept": "application/json",
    };

    // Determine which endpoint to use
    if (_isOwnProfile) {
      // Use authenticated endpoint for own profile
      apiUrl = Uri.parse("$baseUrl/api/user");
      headers["Authorization"] = "Bearer $token";
    } else {
      // Use public endpoint for other users
      apiUrl = Uri.parse("$baseUrl/api/users/$_userId/public");
      headers["Authorization"] =
          "Bearer $token"; // Still include token for authentication
    }

    try {
      final response = await http.get(apiUrl, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          firstName = data['first_name'];
          lastName = data['last_name'];
          role = data['role'] ?? "";
          imageUrl = data['profile_image'];

          // For own profile, update _userId if not already set
          if (_isOwnProfile) {
            _userId ??= data['id'].toString();
            // Save user_id to SharedPreferences if it wasn't provided
            if (widget.userId == null && _userId != null) {
              prefs.setString('user_id', _userId!);
            }
          }

          _loading = false;
        });

        // Fetch user stores after getting user data
        if (_userId != null) {
          _fetchUserStores();
        }
      } else if (response.statusCode == 404) {
        // User not found
        setState(() {
          _loading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User not found'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: EdgeInsets.all(10),
            ),
          );
        }
      } else {
        print("Failed to fetch user data: ${response.body}");
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _fetchUserStores() async {
    if (_userId == null) return;

    setState(() {
      _loadingStores = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/stores/user/$_userId"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userStores = data;
          _loadingStores = false;
        });
      } else if (response.statusCode == 404) {
        // No stores found
        setState(() {
          userStores = [];
          _loadingStores = false;
        });
      } else {
        print("Failed to fetch stores: ${response.body}");
        setState(() {
          _loadingStores = false;
        });
      }
    } catch (e) {
      print("Error fetching stores: $e");
      setState(() {
        _loadingStores = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    // Only allow image upload for own profile
    if (!_isOwnProfile) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can only edit your own profile'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
      return;
    }

    // Show dialog to choose between camera and gallery
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Image Source'),
        actions: [
          TextButton(
            child: Text('Camera'),
            onPressed: () => Navigator.pop(context, ImageSource.camera),
          ),
          TextButton(
            child: Text('Gallery'),
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
          ),
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );

    // If user cancels the dialog, return
    if (source == null) return;

    final XFile? pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final uri = Uri.parse('$baseUrl/api/profile/upload-image');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json';

    if (_image != null) {
      request.files
          .add(await http.MultipartFile.fromPath('image', _image!.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      final newImageUrl = data['profile_image'];
      setState(() {
        imageUrl = newImageUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile image updated!'),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
    } else {
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update image'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = "${firstName ?? ''} ${lastName ?? ''}".trim();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isOwnProfile ? 'My Profile' : 'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Only show edit button for own profile
          if (_isOwnProfile)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.edit, color: primaryColor, size: 20),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UpdatePersonalInfoScreen(),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
                strokeWidth: 3,
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await _fetchUserData();
              },
              color: primaryColor,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(fullName),
                    _buildProfileBody(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader(String fullName) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor.withOpacity(0.8),
            primaryColor.withOpacity(0.6),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(height: 20),
            Hero(
              tag: 'profile-image',
              child: GestureDetector(
                onTap: _isOwnProfile ? _pickAndUploadImage : null,
                child: Stack(
                  children: [
                    Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, _, __) => Center(
                                  child: Icon(
                                    Icons.person,
                                    size: 50,
                                    color: primaryColor.withOpacity(0.6),
                                  ),
                                ),
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: primaryColor,
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: primaryColor.withOpacity(0.6),
                                ),
                              ),
                      ),
                    ),
                    // Only show camera icon for own profile
                    if (_isOwnProfile)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              fullName.isNotEmpty ? fullName : 'Unnamed User',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black26,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                role ?? 'User',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 25),
            Container(
              padding: EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatItem(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileBody() {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isOwnProfile ? 'My Stores' : 'Stores',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (userStores.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      // Navigate to all stores
                    },
                    child: Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 10),
            _loadingStores
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(
                        color: primaryColor,
                      ),
                    ),
                  )
                : userStores.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.store_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No Stores Yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _isOwnProfile
                                  ? 'You haven\'t created any stores yet.\nStart your business journey today!'
                                  : 'This user hasn\'t created any stores yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                                height: 1.4,
                              ),
                            ),
                            SizedBox(height: 20),
                            // Only show create store button for own profile
                            if (_isOwnProfile)
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Navigate to create store screen
                                },
                                icon: Icon(Icons.add),
                                label: Text('Create Store'),
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all(primaryColor),
                                  foregroundColor:
                                      MaterialStateProperty.all(Colors.white),
                                  padding: MaterialStateProperty.all(
                                    EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                  ),
                                  shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : Column(
                        children: userStores.take(3).map((store) {
                          return _buildStoreItem(store);
                        }).toList(),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem() {
    return Column(
      children: [
        Text(
          userStores.length.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Stores Owned',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStoreItem(dynamic store) {
    return GestureDetector(
      onTap: () => _navigateToStore(store),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.store,
                color: primaryColor,
                size: 28,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store['store_name'] ?? 'Unnamed Store',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          store['address'] ?? 'No address',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      SizedBox(width: 4),
                      Text(
                        store['phone'] ?? 'No phone',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Created: ${_formatDate(store['created_at'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToStore(dynamic store) {
    final storeId = store['id'];

    if (storeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Store ID not found'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
      return;
    }

    // Check user role and navigate accordingly
    if (role != null &&
        (role!.toLowerCase() == 'dentist' || role!.toLowerCase() == 'doctor')) {
      // Navigate to UsedEquipmentPage for dentists and doctors
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UsedEquipmentPage(storeId: storeId),
        ),
      );
    } else {
      // Navigate to StoreProductScreen for other roles
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductScreen(storeId: storeId),
        ),
      );
    }
  }
}
