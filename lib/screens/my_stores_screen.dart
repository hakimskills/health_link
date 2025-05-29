
import 'package:flutter/material.dart';
import 'package:health_link/screens/used_equipment.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:convert';

import 'dashboards/healthcare_dashboard.dart';
import 'product_screen.dart';

class MyStoresScreen extends StatefulWidget {
const MyStoresScreen({Key? key}) : super(key: key);

@override
_MyStoresScreenState createState() => _MyStoresScreenState();
}

class _MyStoresScreenState extends State<MyStoresScreen> with SingleTickerProviderStateMixin {
List<dynamic> stores = [];
bool isLoading = true;
bool hasError = false;
String errorMessage = '';

late AnimationController _animationController;

// Define colors
final primaryColor = const Color(0xFF00857C);
final secondaryColor = const Color(0xFF232F34);
final backgroundColor = const Color(0xFFF8FAFC);

@override
void initState() {
super.initState();
_animationController = AnimationController(
vsync: this,
duration: const Duration(milliseconds: 1000),
);
_fetchStores();
}

@override
void dispose() {
_animationController.dispose();
super.dispose();
}

Future<void> _fetchStores() async {
SharedPreferences prefs = await SharedPreferences.getInstance();
String? token = prefs.getString('auth_token');
int? userId = int.tryParse(prefs.getString('user_id') ?? '');

if (token != null && userId != null) {
try {
final response = await http.get(
Uri.parse('http://192.168.43.101:8000/api/stores/user/$userId'),
headers: {
'Authorization': 'Bearer $token',
'Accept': 'application/json',
},
);
print(response.statusCode);
print(response.body);

if (response.statusCode == 200) {
if (mounted) {
setState(() {
stores = jsonDecode(response.body);
print(stores);
isLoading = false;
_animationController.forward();
});
}
} else {
if (mounted) {
setState(() {
isLoading = false;
hasError = true;
errorMessage = 'Failed to load stores. Please try again.';
});
}
}
} catch (e) {
if (mounted) {
setState(() {
isLoading = false;
hasError = true;
errorMessage = 'Connection error. Please check your internet.';
});
}
}
} else {
if (mounted) {
setState(() {
isLoading = false;
hasError = true;
errorMessage = 'Authentication error. Please login again.';
});
}
}
}

Future<void> _refreshStores() async {
setState(() {
isLoading = true;
hasError = false;
});
await _fetchStores();
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: backgroundColor,
appBar: _buildAppBar(),
body: Stack(
children: [
// Background design elements
Positioned(
top: -100,
right: -100,
child: Container(
width: 300,
height: 300,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: primaryColor.withOpacity(0.1),
),
),
),
Positioned(
bottom: -150,
left: -50,
child: Container(
width: 350,
height: 350,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: primaryColor.withOpacity(0.08),
),
),
),

// Main content
RefreshIndicator(
onRefresh: _refreshStores,
color: primaryColor,
child: _buildContent(),
),
],
),
);
}

AppBar _buildAppBar() {
return AppBar(
backgroundColor: Colors.transparent,
elevation: 0,
title: RichText(
text: TextSpan(
children: [
TextSpan(
text: "Health",
style: TextStyle(
color: secondaryColor,
fontSize: 22,
fontWeight: FontWeight.w800,
letterSpacing: 0.5,
),
),
TextSpan(
text: "Link",
style: TextStyle(
color: primaryColor,
fontSize: 22,
fontWeight: FontWeight.w800,
letterSpacing: 0.5,
),
),
],
),
),
actions: [
IconButton(
icon: Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: Colors.white,
shape: BoxShape.circle,
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 8,
offset: const Offset(0, 2),
),
],
),
child: Icon(Icons.notifications_outlined, color: primaryColor, size: 20),
),
onPressed: () {
// Handle notifications
},
),
const SizedBox(width: 8),
],
iconTheme: IconThemeData(color: primaryColor),
);
}

Widget _buildContent() {
if (isLoading) {
return _buildLoadingShimmer();
} else if (hasError) {
return _buildErrorState();
} else if (stores.isEmpty) {
return _buildEmptyState();
} else {
return _buildStoresList();
}
}

Widget _buildLoadingShimmer() {
return Shimmer.fromColors(
baseColor: Colors.grey[300]!,
highlightColor: Colors.grey[100]!,
child: ListView.builder(
padding: const EdgeInsets.all(16),
itemCount: 5,
itemBuilder: (_, __) => Padding(
padding: const EdgeInsets.only(bottom: 16),
child: Container(
height: 100,
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(16),
),
),
),
),
);
}

Widget _buildErrorState() {
return Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.error_outline,
size: 60,
color: Colors.red[300],
),
const SizedBox(height: 16),
Text(
errorMessage,
style: TextStyle(
fontSize: 16,
color: secondaryColor,
),
textAlign: TextAlign.center,
),
const SizedBox(height: 24),
ElevatedButton(
style: ElevatedButton.styleFrom(
backgroundColor: primaryColor,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
),
onPressed: _refreshStores,
child: const Text('Try Again'),
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
Icon(
Icons.store_outlined,
size: 60,
color: Colors.grey[400],
),
const SizedBox(height: 16),
Text(
'No stores found',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.w600,
color: secondaryColor,
),
),
const SizedBox(height: 8),
Text(
'You don\'t have any stores yet',
style: TextStyle(
fontSize: 14,
color: Colors.grey[600],
),
),
],
),
);
}

Widget _buildStoresList() {
return ListView.builder(
padding: const EdgeInsets.all(16),
itemCount: stores.length,
itemBuilder: (context, index) {
final store = stores[index];

return GestureDetector(
onTap: () async {
// Check user_role from SharedPreferences
SharedPreferences prefs = await SharedPreferences.getInstance();
String? userRole = prefs.getString('user_role');

// Determine the target screen based on user_role
Widget targetScreen;
if (userRole == 'Doctor' || userRole == 'Dentist') {
targetScreen = UsedEquipmentPage(storeId: store['id']);
} else {
targetScreen = ProductScreen(storeId: store['id']);
}

// Navigate to the appropriate screen with slide transition
Navigator.push(
context,
PageRouteBuilder(
pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
transitionsBuilder: (context, animation, secondaryAnimation, child) {
const begin = Offset(1.0, 0.0);
const end = Offset.zero;
const curve = Curves.easeOutCubic;
var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
var offsetAnimation = animation.drive(tween);
return SlideTransition(position: offsetAnimation, child: child);
},
transitionDuration: const Duration(milliseconds: 400),
),
);
},
child: Container(
margin: const EdgeInsets.only(bottom: 16),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
),
child: Padding(
padding: const EdgeInsets.all(16),
child: Row(
children: [
// Store icon
Container(
width: 60,
height: 60,
decoration: BoxDecoration(
color: primaryColor.withOpacity(0.1),
borderRadius: BorderRadius.circular(12),
),
child: Center(
child: Icon(
Icons.store_outlined,
color: primaryColor,
size: 28,
),
),
),
const SizedBox(width: 16),

// Store info
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
store['store_name'] ?? 'Store',
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 16,
color: secondaryColor,
),
),
const SizedBox(height: 4),
Text(
store['address'] ?? 'No address provided',
style: TextStyle(
color: Colors.grey[700],
fontSize: 14,
),
),
if (store['phone'] != null) ...[
const SizedBox(height: 4),
Text(
store['phone'],
style: TextStyle(
color: Colors.grey[600],
fontSize: 13,
),
),
],
],
),
),

// Arrow icon
Container(
width: 36,
height: 36,
decoration: BoxDecoration(
color: Colors.grey[100],
borderRadius: BorderRadius.circular(8),
),
child: Center(
child: Icon(
Icons.arrow_forward_ios,
color: primaryColor,
size: 16,
),
),
),
],
),
),
).animate(
controller: _animationController,
effects: [
FadeEffect(
curve: Curves.easeOut,
delay: Duration(milliseconds: 100 * index), // Staggered animation
duration: const Duration(milliseconds: 500),
),
SlideEffect(
begin: const Offset(0, 30),
end: const Offset(0, 0),
curve: Curves.easeOut,
delay: Duration(milliseconds: 100 * index),
duration: const Duration(milliseconds: 500),
),
],
),
);
},
);
}
}
