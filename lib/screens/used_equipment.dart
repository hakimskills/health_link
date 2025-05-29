// Add these dependencies to pubspec.yaml
// cached_network_image: ^3.2.3
// carousel_slider: ^4.2.1

import 'package:flutter/material.dart';
import 'package:health_link/screens/dashboards/add_used_equipment.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';

class UsedEquipmentPage extends StatefulWidget {
  final int storeId;

  const UsedEquipmentPage({Key? key, required this.storeId}) : super(key: key);

  @override
  _UsedEquipmentPageState createState() => _UsedEquipmentPageState();
}

class _UsedEquipmentPageState extends State<UsedEquipmentPage>
    with SingleTickerProviderStateMixin {
  final String apiUrl = 'http://192.168.43.101:8000/api/products/';
  List<dynamic> products = [];
  List<dynamic> filteredProducts = []; // List for filtered products
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = ''; // Store the search query

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
    _fetchUsedEquipment();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsedEquipment() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    final fullUrl = '$apiUrl${widget.storeId}';

    developer.log('Initiating API call to fetch used equipment',
        name: 'UsedEquipmentPage', level: 600);
    developer.log('API URL: $fullUrl', name: 'UsedEquipmentPage', level: 600);
    developer.log('Auth token: ${token != null ? 'present' : 'missing'}',
        name: 'UsedEquipmentPage', level: 600);

    try {
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      developer.log('API response received with status code: ${response.statusCode}',
          name: 'UsedEquipmentPage', level: 600);

      if (response.statusCode == 200) {
        final allProducts = json.decode(response.body);
        developer.log('Total products received: ${allProducts.length}',
            name: 'UsedEquipmentPage', level: 600);

        setState(() {
          products = allProducts.where((product) => product['type'] == 'used_equipment').toList();
          filteredProducts = products; // Initialize filtered list
          isLoading = false;
          developer.log('Filtered used_equipment products: ${products.length}',
              name: 'UsedEquipmentPage', level: 600);
        });
        _animationController.forward();
      } else {
        setState(() {
          errorMessage = 'Failed to load products: ${response.statusCode} - ${response.body}';
          isLoading = false;
          developer.log('API error: $errorMessage',
              name: 'UsedEquipmentPage', error: errorMessage, level: 900);
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
        developer.log('Exception caught during API call: $e',
            name: 'UsedEquipmentPage', error: e, level: 1000);
      });
    }
  }

  // Function to filter products based on search query
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
      developer.log('Filtered products count: ${filteredProducts.length}',
          name: 'UsedEquipmentPage', level: 600);
    });
  }

  // Function to show search dialog
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempQuery = searchQuery;
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Search Equipment',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter equipment name',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF008080)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF008080)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF008080), width: 2),
              ),
            ),
            onChanged: (value) {
              tempQuery = value;
              _filterProducts(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _filterProducts('');
                Navigator.pop(context);
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: Color(0xFF008080)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Done',
                style: TextStyle(color: Color(0xFF008080)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    developer.log('Building UsedEquipmentPage UI',
        name: 'UsedEquipmentPage', level: 600);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF008080)),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Color(0xFF008080)),
                  onPressed: _showSearchDialog,
                  tooltip: 'Search',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF008080)),
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                      errorMessage = null;
                      searchQuery = ''; // Reset search query on refresh
                      filteredProducts = products; // Reset filtered list
                    });
                    _animationController.reset();
                    _fetchUsedEquipment();
                  },
                  tooltip: 'Refresh',
                ),
                const SizedBox(width: 8),
              ],
            ),
          ];
        },
        body: isLoading
            ? _buildLoadingState()
            : errorMessage != null
            ? _buildErrorState()
            : filteredProducts.isEmpty
            ? _buildEmptyState()
            : _buildProductGrid(),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF008080),
              Color(0xFF006666),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF008080).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            developer.log('Add Used Equipment button pressed',
                name: 'UsedEquipmentPage', level: 600);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddUsedEquipmentPage(storeId: widget.storeId),
              ),
            ).then((_) {
              developer.log('Returning to UsedEquipmentPage, refreshing products',
                  name: 'UsedEquipmentPage', level: 600);
              setState(() {
                isLoading = true;
                searchQuery = ''; // Reset search query
                filteredProducts = products; // Reset filtered list
              });
              _animationController.reset();
              _fetchUsedEquipment();
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          label: const Text(
            'Add Equipment',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
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
                  developer.log('Retry button pressed',
                      name: 'UsedEquipmentPage', level: 600);
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                    searchQuery = ''; // Reset search query
                    filteredProducts = products; // Reset filtered list
                  });
                  _fetchUsedEquipment();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(40),
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF008080),
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                searchQuery.isEmpty ? 'No Equipment Found' : 'No Matching Equipment',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                searchQuery.isEmpty
                    ? 'Start building your inventory by adding your first piece of used equipment.'
                    : 'No equipment matches your search. Try a different name.',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
          itemCount: filteredProducts.length, // Use filteredProducts
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
                    child: _buildProductCard(filteredProducts[index]), // Use filteredProducts
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

    developer.log('Rendering product: ${product['product_name'] ?? 'Unnamed'}',
        name: 'UsedEquipmentPage', level: 600);

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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  if (product['stock'] != null && product['stock'] < 5 && product['stock'] > 0)
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF008080),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF008080).withOpacity(0.3),
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getConditionColor(product['condition']).withOpacity(0.15),
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
            Icons.image_outlined,
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