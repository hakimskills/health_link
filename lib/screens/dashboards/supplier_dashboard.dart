import 'package:flutter/material.dart';
import 'package:health_link/screens/seller_order_screen.dart';
import 'package:health_link/user_profile/profile_screen.dart';
import 'package:health_link/screens/used_equipment.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../my_stores_screen.dart';
import '../reusable component/app_drawer.dart';
import '../reusable component/custom_bottom_nav.dart';
import '../product_screen.dart';
import '../store_selector_popup.dart';
import 'home_page.dart';

class SupplierDashboard extends StatefulWidget {
  @override
  _SupplierDashboardState createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> {
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
      print('Loaded user role: $_userRole');
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
    print('Navigating to page: $index');
  }

  void _showStoreSelector() {
    StoreSelector.showStoreSelectionDialog(
      context: context,
      onStoreSelected: (int storeId) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                RoleBasedRedirectScreen(storeId: storeId),
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
          print('Page changed to: $index');
        },
        children: [
          HomePage(),
          MyStoresScreen(),
          SellerOrdersScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        onFabPressed: _userRole == 'Doctor' || _userRole == 'Dentist' || _userRole =="Supplier"
            ? _showStoreSelector
            : null,
        fabLabel: _userRole == 'Doctor' || _userRole == 'Dentist' ? 'Add' : null,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// Role-based redirection screen
class RoleBasedRedirectScreen extends StatelessWidget {
  final int storeId;

  const RoleBasedRedirectScreen({Key? key, required this.storeId}) : super(key: key);

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