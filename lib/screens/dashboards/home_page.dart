import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:health_link/screens/product_details.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _products = [];
  Set<String> _productIds = {}; // Track unique product IDs to prevent duplicates
  bool _isLoading = true;
  bool _hasMore = true;
  int _page = 1;
  final int _pageSize = 10; // Increased page size for better performance
  bool _isLoadingMore = false;
  bool _isConnected = true;
  List<String> _categories = [
    'All',
    'Medications',
    'Supplies',
    'Inventory',
    'Used Equipment'
  ];
  String _selectedCategory = 'All';
  TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    fetchProducts();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        _isConnected) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    await fetchProducts(loadMore: true);

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _checkConnectivity() async {
    // Placeholder for connectivity_plus package
    setState(() {
      _isConnected = true;
    });
  }

  Future<void> fetchProducts({bool refresh = false, bool loadMore = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _products = [];
        _productIds.clear(); // Clear the set of product IDs
        _hasMore = true;
        _isLoading = true;
      });
    }

    if (!_hasMore && loadMore) return;

    if (!loadMore && !refresh) {
      setState(() => _isLoading = true);
    }

    final url = Uri.parse('http://192.168.43.101:8000/api/products?page=$_page&limit=$_pageSize');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Accept-Encoding': 'gzip',
          'Connection': 'Keep-Alive',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> newProducts = decoded is List ? decoded : (decoded['data'] ?? []);

        // Filter out duplicate products
        final List<dynamic> uniqueNewProducts = [];
        for (var product in newProducts) {
          String productId = product['product_id']?.toString() ?? product['id']?.toString() ?? '';
          if (productId.isNotEmpty && !_productIds.contains(productId)) {
            uniqueNewProducts.add(product);
            _productIds.add(productId);
          }
        }

        if (mounted) {
          setState(() {
            if (loadMore) {
              _products.addAll(uniqueNewProducts);
            } else {
              _products = uniqueNewProducts;
            }
            _isLoading = false;

            // Only increment page if we got new unique products
            if (uniqueNewProducts.isNotEmpty) {
              _page++;
            }

            // Check if we have more products to load
            _hasMore = newProducts.length >= _pageSize && uniqueNewProducts.isNotEmpty;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isConnected = response.statusCode != 401; // Assume network issue if not auth error
          });
        }
      }
    } catch (e) {
      print('Error fetching products: $e'); // Debug print
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isConnected = false;
        });
      }
    }
  }

  List<dynamic> get filteredProducts {
    if (_selectedCategory == 'All' && _searchController.text.isEmpty) {
      return _products;
    }

    return _products.where((product) {
      // Handle category filtering
      bool matchesCategory = true;
      if (_selectedCategory != 'All') {
        if (_selectedCategory == 'Inventory') {
          matchesCategory = product['type'] == 'inventory';
        } else if (_selectedCategory == 'Used Equipment') {
          matchesCategory = product['type'] == 'used_equipment';
        } else {
          matchesCategory = product['category'] != null &&
              product['category'].toString().toLowerCase() == _selectedCategory.toLowerCase();
        }
      }

      // Handle search filtering
      bool matchesSearch = _searchController.text.isEmpty ||
          (product['product_name'] != null &&
              product['product_name'].toString().toLowerCase().contains(_searchController.text.toLowerCase()));

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Health",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: "Link",
                          style: TextStyle(
                            color: Color(0xFF008080),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.shopping_cart_outlined, color: Color(0xFF008080)),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.notifications_outlined, color: Color(0xFF008080)),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      // Reset pagination when searching
                      if (value.isEmpty) {
                        fetchProducts(refresh: true);
                      }
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search health products...',
                    prefixIcon: Icon(Icons.search, color: Color(0xFF008080)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),

            // Categories
            Container(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                          // Reset pagination when category changes
                          fetchProducts(refresh: true);
                        });
                      },
                      child: Chip(
                        label: Text(category),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

            // Products Grid
            Expanded(
              child: _isLoading && _products.isEmpty
                  ? _buildLoadingShimmer()
                  : !_isConnected
                  ? _buildNoConnectionView()
                  : filteredProducts.isEmpty
                  ? _buildEmptyProductsView()
                  : RefreshIndicator(
                onRefresh: () => fetchProducts(refresh: true),
                color: Color(0xFF008080),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: MasonryGridView.count(
                          controller: _scrollController,
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return ProductCard(
                              key: ValueKey(product['product_id'] ?? product['id'] ?? index),
                              product: product,
                            );
                          },
                        ),
                      ),
                      if (_isLoadingMore)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008080)),
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
              _checkConnectivity();
              fetchProducts(refresh: true);
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
          if (_searchController.text.isNotEmpty || _selectedCategory != 'All')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedCategory = 'All';
                  });
                  fetchProducts(refresh: true);
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

class ProductCard extends StatelessWidget {
  final dynamic product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isInventory = product['type'] == 'inventory';
    final double originalPrice = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
    final double inventoryPrice = isInventory
        ? (double.tryParse(product['inventory_price']?.toString() ?? '0') ?? 0.0)
        : originalPrice;

    int discountPercentage = 0;
    if (isInventory && originalPrice > 0) {
      discountPercentage = ((originalPrice - inventoryPrice) / originalPrice * 100).round();
    }

    String? imageUrl;
    if (product['images'] != null && product['images'] is List && product['images'].isNotEmpty) {
      final primaryImage = product['images'].firstWhere(
            (img) => img['is_primary'] == true,
        orElse: () => product['images'][0],
      );
      imageUrl = primaryImage['image_path'];
    } else if (product['image'] != null) {
      imageUrl = product['image'];
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(
              product: product['product_id'],
            ),
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
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    imageUrl != null
                        ? Hero(
                      tag: 'product-${product['product_id'] ?? product['id'] ?? UniqueKey()}',
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        memCacheWidth: 600,
                        memCacheHeight: 600,
                        maxWidthDiskCache: 1200,
                        maxHeightDiskCache: 1200,
                        fadeInDuration: Duration(milliseconds: 300),
                        progressIndicatorBuilder: (context, url, downloadProgress) => Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: downloadProgress.progress,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008080)),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          return Container(
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, color: Colors.grey[400], size: 40),
                                SizedBox(height: 8),
                                Text(
                                  'Image not available',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                        : Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                    if (product['images'] != null && product['images'] is List && product['images'].length > 1)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_library,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${product['images'].length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!isInventory)
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
                    if (isInventory)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'STOCK SALE',
                            style: TextStyle(
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
                    if (isInventory)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '\$${inventoryPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.red,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'SAVE $discountPercentage%',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '\$${originalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${originalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF008080),
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
}