import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:health_link/screens/dashboards/add_used_equipment.dart';
import 'package:health_link/screens/edit_product_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UsedEquipmentPage extends StatefulWidget {
  final int storeId;

  const UsedEquipmentPage({Key? key, required this.storeId}) : super(key: key);

  @override
  _UsedEquipmentPageState createState() => _UsedEquipmentPageState();
}

class _UsedEquipmentPageState extends State<UsedEquipmentPage>
    with SingleTickerProviderStateMixin {
  final String apiUrl = 'http://192.168.43.101:8000/api/';
  List<dynamic> products = [];
  List<dynamic> filteredProducts = [];
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final Color primaryColor = const Color(0xFF008080);
  String? loggedInUserId; // Store the logged-in user's ID
  String? storeOwnerId; // Store the store owner's ID

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeUserAndFetchData(); // Initialize user ID and fetch data
    _searchController.addListener(() {
      _filterProducts(_searchController.text);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Initialize logged-in user ID and fetch store owner ID and equipment
  Future<void> _initializeUserAndFetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    setState(() {
      loggedInUserId = prefs.getString('user_id');
      print(loggedInUserId); // Assumes user_id is stored
    });

    // Fetch store owner's ID
    try {
      final response = await http.get(
        Uri.parse('${apiUrl}store/${widget.storeId}/owner'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final ownerData = json.decode(response.body);
        setState(() {
          storeOwnerId = ownerData['id'].toString();

          print(storeOwnerId); // Adjust based on API response
        });
      } else {
        developer.log(
          'Failed to fetch store owner: ${response.statusCode}',
          name: 'UsedEquipmentPage',
          level: 900,
        );
        setState(() {
          errorMessage = 'Failed to load store owner data';
          isLoading = false;
        });
        return;
      }
    } catch (e) {
      developer.log(
        'Error fetching store owner: $e',
        name: 'UsedEquipmentPage',
        error: e,
        level: 900,
      );
      setState(() {
        errorMessage = 'Error fetching store owner: $e';
        isLoading = false;
      });
      return;
    }

    await _fetchUsedEquipment();
  }

  Future<void> _fetchUsedEquipment() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    final fullUrl = '${apiUrl}products/${widget.storeId}';

    developer.log('Initiating API call to fetch used equipment',
        name: 'UsedEquipmentPage', level: 600);
    try {
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final allProducts = json.decode(response.body);
        setState(() {
          products = allProducts
              .where((product) => product['type'] == 'used_equipment')
              .toList();
          filteredProducts = products;
          isLoading = false;
        });
        _animationController.forward();
      } else {
        setState(() {
          errorMessage = 'Failed to load products: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _filterProducts(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredProducts = products;
      } else {
        filteredProducts = products.where((product) {
          final name = product['product_name']?.toLowerCase() ?? '';
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _deleteProduct(int productId) async {
    setState(() => isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    try {
      final response = await http.delete(
        Uri.parse('${apiUrl}product/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Equipment deleted successfully'),
            backgroundColor: primaryColor,
          ),
        );
        _fetchUsedEquipment();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete equipment: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showProductOptions(dynamic product) {
    final images = product['images'] as List<dynamic>?;
    final primaryImage = images?.firstWhere(
      (image) => image['is_primary'] == true,
      orElse: () => images?.isNotEmpty == true ? images![0] : null,
    );

    // Check if the logged-in user is the store owner
    bool isOwner = loggedInUserId != null && storeOwnerId == loggedInUserId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: primaryImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            primaryImage['image_path'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.fitness_center_outlined,
                              color: Colors.grey[400],
                            ),
                          ),
                        )
                      : Icon(
                          Icons.fitness_center_outlined,
                          color: Colors.grey[400],
                        ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['product_name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        product['condition'] ?? 'N/A',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${product['price']} DA",
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 30),
            // Conditionally show edit/delete options only for the owner
            if (isOwner) ...[
              _buildOptionTile(
                icon: Icons.edit,
                iconColor: primaryColor,
                title: 'Edit Equipment',
                subtitle: 'Update equipment details',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProductPage(product: product),
                    ),
                  ).then((result) {
                    if (result == true) {
                      _fetchUsedEquipment();
                    }
                  });
                },
              ),
              _buildOptionTile(
                icon: Icons.delete_outline,
                iconColor: Colors.red,
                title: 'Delete Equipment',
                subtitle: 'Remove this equipment',
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteProduct(product['product_id']);
                },
              ),
            ] else ...[
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.info, color: Colors.grey),
                ),
                title: Text(
                  'View Only',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'You cannot edit or delete this equipment',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(vertical: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 60,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.white,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: primaryColor),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.only(left: 50, bottom: 16),
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Used ",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Equipment",
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(isSearching ? Icons.close : Icons.search,
                      color: primaryColor),
                  onPressed: () {
                    setState(() {
                      isSearching = !isSearching;
                      if (!isSearching) {
                        _searchController.clear();
                        _filterProducts('');
                      }
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.refresh_rounded, color: primaryColor),
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                      errorMessage = null;
                      searchQuery = '';
                      filteredProducts = products;
                    });
                    _animationController.reset();
                    _initializeUserAndFetchData();
                  },
                ),
                SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(isSearching ? 68 : 20),
                child: isSearching
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search equipment...',
                              prefixIcon: Icon(Icons.search,
                                  color: primaryColor, size: 20),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: EdgeInsets.symmetric(vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: primaryColor, width: 1),
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear,
                                          color: Colors.grey, size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                        _filterProducts('');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      )
                    : SizedBox(),
              ),
            ),
          ];
        },
        body: isLoading
            ? _buildLoadingState()
            : errorMessage != null
                ? _buildErrorState()
                : filteredProducts.isEmpty
                    ? _buildEmptyState(context)
                    : _buildProductGrid(),
      ),
      floatingActionButton:
          loggedInUserId != null && storeOwnerId == loggedInUserId
              ? FloatingActionButton.extended(
                  backgroundColor: primaryColor,
                  elevation: 4,
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text(
                    "Add Equipment",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddUsedEquipmentPage(storeId: widget.storeId),
                      ),
                    ).then((_) {
                      setState(() {
                        isLoading = true;
                        searchQuery = '';
                        filteredProducts = products;
                      });
                      _animationController.reset();
                      _initializeUserAndFetchData();
                    });
                  },
                )
              : null, // Hide FAB for non-owners
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008080)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading equipment...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF008080), Color(0xFF006666)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                    searchQuery = '';
                    filteredProducts = products;
                  });
                  _initializeUserAndFetchData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center_outlined,
                size: 60,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              isSearching
                  ? "No equipment matches your search"
                  : "No used equipment available",
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                isSearching
                    ? "Try different keywords"
                    : "Add your first used equipment to get started",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final slideAnimation = Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (index * 0.1).clamp(0.0, 1.0),
                    ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                    curve: Curves.easeOutBack,
                  ),
                ));

                return SlideTransition(
                  position: slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildProductCard(filteredProducts[index]),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final images = product['images'] as List<dynamic>?;
    final primaryImage = images?.firstWhere(
      (img) => img['is_primary'] == true,
      orElse: () => images != null && images.isNotEmpty ? images[0] : null,
    );

    // Check if the logged-in user is the store owner
    bool isOwner = loggedInUserId != null && storeOwnerId == loggedInUserId;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  images != null && images.isNotEmpty
                      ? _buildImageCarousel(images)
                      : _buildImagePlaceholder(),
                  if (images != null && images.length > 1)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${images.length} images',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  if (product['stock'] != null &&
                      product['stock'] < 5 &&
                      product['stock'] > 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.red.withOpacity(0.7),
                        child: Text(
                          'Low Stock: ${product['stock']}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  if (product['stock'] != null && product['stock'] == 0)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.6),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'OUT OF STOCK',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${product['price']} DA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product['product_name'] ?? 'Unnamed Product',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getConditionColor(product['condition'])
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product['condition'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getConditionColor(product['condition']),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isOwner) // Only show options for the owner
                          InkWell(
                            onTap: () => _showProductOptions(product),
                            customBorder: CircleBorder(),
                            child: Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.more_vert,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<dynamic> images) {
    return CarouselSlider(
      options: CarouselOptions(
        height: double.infinity,
        viewportFraction: 1.0,
        enableInfiniteScroll: true,
        autoPlay: images.length > 1,
        autoPlayInterval: const Duration(seconds: 3),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.easeInOut,
      ),
      items: images.map((image) {
        return CachedNetworkImage(
          imageUrl: image['image_path'] ?? '',
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (context, url) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF1F5F9),
                  const Color(0xFFE2E8F0),
                ],
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008080)),
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            developer.log(
              'Failed to load image: ${image['image_path']}',
              name: 'UsedEquipmentPage',
              error: error,
              level: 900,
            );
            return _buildImagePlaceholder();
          },
        );
      }).toList(),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF1F5F9),
            const Color(0xFFE2E8F0),
          ],
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 40,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 8),
          Text(
            'No Image',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getConditionColor(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'excellent':
        return const Color(0xFF10B981);
      case 'very good':
        return const Color(0xFF059669);
      case 'good':
        return const Color(0xFF3B82F6);
      case 'fair':
        return const Color(0xFFF59E0B);
      case 'poor':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
