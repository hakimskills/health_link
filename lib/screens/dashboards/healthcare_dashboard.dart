import 'package:flutter/material.dart';
import 'package:health_link/screens/used_equipment.dart';
import 'package:health_link/user_profile/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../my_stores_screen.dart';
import '../orders_screen.dart';
import '../product_screen.dart'; // Import ProductScreen
import '../reusable component/app_drawer.dart';
import '../reusable component/custom_bottom_nav.dart';
import '../store_selector_popup.dart'; // Import the store selector
import 'home_page.dart';

class HealthcareDashboard extends StatefulWidget {
  @override
  _HealthcareDashboardState createState() => _HealthcareDashboardState();
}

class _HealthcareDashboardState extends State<HealthcareDashboard> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role');
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  void _showStoreSelector() {
    StoreSelector.showStoreSelectionDialog(
      context: context,
      onStoreSelected: (int storeId) {
        // Navigate to the appropriate screen based on user role
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                RoleBasedRedirectScreen(storeId: storeId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: AppDrawer(),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          HomePage(),
          MyStoresScreen(),
          OrdersScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        onFabPressed: _userRole == 'Doctor' ||
                _userRole == 'Dentist' ||
                _userRole == 'Pharmacist'
            ? _showStoreSelector // Show selector for Doctor or Dentist
            : null,
        fabLabel: _userRole == 'Doctor' ||
                _userRole == 'Dentist' ||
                _userRole == 'Pharmacist'
            ? 'Add'
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// New class to handle role-based redirection
class RoleBasedRedirectScreen extends StatelessWidget {
  final int storeId;

  const RoleBasedRedirectScreen({Key? key, required this.storeId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userRole = snapshot.data;
        if (userRole == 'Doctor' || userRole == 'Dentist') {
          return UsedEquipmentPage(storeId: storeId);
        } else {
          return ProductScreen(storeId: storeId);
        }
      },
    );
  }

  Future<String?> _getUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }
}
