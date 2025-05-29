import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'product_details.dart';

class StoreScreen extends StatefulWidget {
  final int storeId;

  const StoreScreen({
    Key? key,
    required this.storeId,
  }) : super(key: key);

  @override
  _StoreScreenState createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  bool _isLoading = true;
  bool _isConnected = true;
  List<dynamic> _storeProducts = [];
  Map<String, dynamic> _storeInfo = {};
  final ScrollController _scrollController = ScrollController();
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    fetchStoreData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchStoreData({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _storeProducts = [];
      });
    }

    setState(() => _isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    try {
      final url = Uri.parse('http://192.168.43.101:8000/api/products/storeName/${widget.storeId}');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Extract store info and products from the response
        final storeOwnerName = decoded['store_name'];
        final products = decoded['products'] ?? [];

        // Extract unique categories from products
        Set<String> categorySet = {'All'};
        for (var product in products) {
          if (product['category'] != null && product['category'].toString().isNotEmpty) {
            categorySet.add(product['category'].toString());
          }
        }

        setState(() {
          _storeInfo = {
            'store_name': storeOwnerName,
          };
          _storeProducts = products;
          _categories = categorySet.toList()..sort();
          _isLoading = false;
          _isConnected = true;
        });
      } else {
        setState(() {
          _isLoading = false;
          if (response.statusCode == 404) {
            _storeProducts = [];
          }
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
        _isConnected = false;
      });
    }
  }

  List<dynamic> get filteredProducts {
    if (_selectedCategory == 'All' && _searchController.text.isEmpty) {
      return _storeProducts;
    }

    return _storeProducts.where((product) {
      bool matchesCategory = _selectedCategory == 'All' ||
          (product['category'] != null && product['category'] == _selectedCategory);

      bool matchesSearch = _searchController.text.isEmpty ||
          (product['product_name'] != null &&
              product['product_name'].toLowerCase().contains(_searchController.text.toLowerCase()));

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Color(0xFF008080),
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        fetchStoreData(refresh: true);
                      }
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.info_outline, color: Colors.white),
                  onPressed: () {
                    _showStoreInfoDialog();
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                title: _isSearching
                    ? Container(
                  height: 40,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search in this store...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search, color: Colors.white),
                        onPressed: () {
                          // Apply search filter locally instead of fetching
                          setState(() {});
                        },
                      ),
                    ),
                    onSubmitted: (_) => setState(() {}),
                  ),
                )
                    : Text(
                  _storeInfo['store_name'] ?? 'Store #${widget.storeId}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF008080),
                        Color(0xFF006666),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.store,
                      size: 80,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                minHeight: 60.0,
                maxHeight: 60.0,
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected = category == _selectedCategory;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                },
                                child: Chip(
                                  label: Text(category),
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                  backgroundColor: isSelected ? Color(0xFF008080) : Colors.white,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  shape: StadiumBorder(
                                    side: BorderSide(
                                      color: isSelected ? Color(0xFF008080) : Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: _isLoading && _storeProducts.isEmpty
            ? _buildLoadingShimmer()
            : !_isConnected
            ? _buildNoConnectionView()
            : filteredProducts.isEmpty
            ? _buildEmptyProductsView()
            : RefreshIndicator(
          onRefresh: () => fetchStoreData(refresh: true),
          color: Color(0xFF008080),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: MasonryGridView.count(
              controller: _scrollController,
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return _buildProductCard(product);
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        color: Colors.white,
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(Icons.shopping_bag_outlined),
                label: Text(
                  'View All Products',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'All';
                    _searchController.clear();
                  });
                  fetchStoreData(refresh: true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF008080),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(product: product['product_id']),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    product['image'] != null
                        ? Hero(
                      tag: 'product-${product['product_id'] ?? UniqueKey()}',
                      child: CachedNetworkImage(
                        imageUrl: product['image'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        memCacheWidth: 600,
                        memCacheHeight: 600,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008080)),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: Colors.grey[400], size: 40),
                              SizedBox(height: 8),
                              Text(
                                'Image not available',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                        : Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                    if (product['type'] != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: product['type'] == 'new'
                                ? Colors.blue[700]
                                : Colors.amber[700],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product['type'] == 'new' ? 'NEW' : 'INVENTORY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_border,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Product Info
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['product_name'] ?? 'Unknown Product',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product['type'] == 'inventory'
                              ? '\$${product['inventory_price'] ?? '0.00'}'
                              : '\$${product['price'] ?? '0.00'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF008080),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Color(0xFF008080),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStoreInfoDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF008080),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.store, color: Color(0xFF008080), size: 32),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _storeInfo['store_name'] ?? 'Store #${widget.storeId}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Store ID: ${widget.storeId}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Store Details
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // Store Stats
                  Text(
                    'Store Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildInfoTile(Icons.inventory_2_outlined, 'Product Count', '${_storeProducts.length} products'),
                  _buildInfoTile(Icons.category_outlined, 'Categories', '${_categories.length - 1} categories'),

                  SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.message_outlined),
                          label: Text('Contact Store'),
                          onPressed: () {
                            // Implement contact store functionality
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF008080),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.share_outlined),
                          label: Text('Share Store'),
                          onPressed: () {
                            // Implement share store functionality
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFF008080),
                            side: BorderSide(color: Color(0xFF008080)),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFF008080).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFF008080), size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoConnectionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No internet connection',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              setState(() => _isConnected = true);
              fetchStoreData(refresh: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF008080),
              foregroundColor: Colors.white,
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProductsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty || _selectedCategory != 'All'
                ? 'Try adjusting your filters'
                : 'This store has no products yet',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          if (_searchController.text.isNotEmpty || _selectedCategory != 'All')
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'All';
                    _searchController.clear();
                  });
                  fetchStoreData(refresh: true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF008080),
                  foregroundColor: Colors.white,
                ),
                child: Text('Clear Filters'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          itemCount: 6,
          itemBuilder: (context, index) {
            return Container(
              height: index.isEven ? 240 : 280,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}