import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:health_link/screens/order_checkout_page.dart';
import 'package:health_link/screens/product_details.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../cart_manager.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _products = [];
  List<dynamic> _recommendedProducts = [];
  Set<String> _productIds = {};
  bool _isLoading = true;
  bool _isLoadingRecommendations = true;
  bool _hasMore = true;
  int _page = 1;
  final int _pageSize = 10;
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
  int _cartItemCount = 0;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadUserRole();
    fetchProducts();
    fetchRecommendations();
    _scrollController.addListener(_scrollListener);
    _loadCartItemCount();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role');
    });
  }

  Future<void> _loadCartItemCount() async {
    final count = await CartManager.getCartItemCount();
    setState(() {
      _cartItemCount = count;
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
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
    setState(() {
      _isConnected = true;
    });
  }

  Future<void> fetchRecommendations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    String? userRole = prefs.getString('user_role');

    if (token == null || userRole == 'Supplier') {
      setState(() {
        _isLoadingRecommendations = false;
      });
      return;
    }

    try {
      final url = Uri.parse('http://192.168.43.101:8000/api/recommendations');
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
        final List<dynamic> recommendations =
            decoded['recommended_products'] ?? [];

        if (mounted) {
          setState(() {
            _recommendedProducts = recommendations;
            _isLoadingRecommendations = false;
          });
        }
      } else {
        print('Failed to fetch recommendations: ${response.statusCode}');
        if (mounted) {
          setState(() {
            _isLoadingRecommendations = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching recommendations: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecommendations = false;
        });
      }
    }
  }

  Future<void> fetchProducts(
      {bool refresh = false, bool loadMore = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _products = [];
        _productIds.clear();
        _hasMore = true;
        _isLoading = true;
      });
      // Also refresh recommendations when refreshing products
      fetchRecommendations();
    }

    if (!_hasMore && loadMore) return;

    if (!loadMore && !refresh) {
      setState(() => _isLoading = true);
    }

    final url = Uri.parse(
        'http://192.168.43.101:8000/api/products?page=$_page&limit=$_pageSize');
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
        final List<dynamic> newProducts =
            decoded is List ? decoded : (decoded['data'] ?? []);

        final List<dynamic> uniqueNewProducts = [];
        for (var product in newProducts) {
          String productId = product['product_id']?.toString() ??
              product['id']?.toString() ??
              '';
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
            if (uniqueNewProducts.isNotEmpty) {
              _page++;
            }
            _hasMore =
                newProducts.length >= _pageSize && uniqueNewProducts.isNotEmpty;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isConnected = response.statusCode != 401;
          });
        }
      }
    } catch (e) {
      print('Error fetching products: $e');
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
      bool matchesCategory = true;
      if (_selectedCategory != 'All') {
        if (_selectedCategory == 'Inventory') {
          matchesCategory = product['type'] == 'inventory';
        } else if (_selectedCategory == 'Used Equipment') {
          matchesCategory = product['type'] == 'used_equipment';
        } else {
          matchesCategory = product['category'] != null &&
              product['category'].toString().toLowerCase() ==
                  _selectedCategory.toLowerCase();
        }
      }

      bool matchesSearch = _searchController.text.isEmpty ||
          (product['product_name'] != null &&
              product['product_name']
                  .toString()
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()));

      return matchesCategory && matchesSearch;
    }).toList();
  }

  Widget _buildRecommendationsCarousel() {
    if (_userRole == 'Supplier' ||
        (!_isLoadingRecommendations && _recommendedProducts.isEmpty)) {
      return SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (_isLoadingRecommendations) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.recommend, color: Color(0xFF008080), size: 24),
                Text(
                  'Recommended for You',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 300,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _recommendedProducts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final product = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Container(
                      width: 200,
                      child: ProductCard(
                        key: ValueKey(
                            'recommended-${product['product_id'] ?? product['id'] ?? index}'),
                        product: product,
                        isRecommended: true,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
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
                        Stack(
                          children: [
                            IconButton(
                              icon: Icon(Icons.shopping_cart_outlined,
                                  color: Color(0xFF008080)),
                              onPressed: () async {
                                final cartItems =
                                    await CartManager.getCartItems();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OrderCheckoutPage(cartItems: cartItems),
                                  ),
                                );
                              },
                            ),
                            if (_cartItemCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$_cartItemCount',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
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
            ),
            if (_userRole != 'Supplier') _buildRecommendationsCarousel(),
            SliverToBoxAdapter(
              child: Container(
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
                            fetchProducts(refresh: true);
                          });
                        },
                        child: Chip(
                          label: Text(category),
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          backgroundColor:
                              isSelected ? Color(0xFF008080) : Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: isSelected
                                  ? Color(0xFF008080)
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(12.0),
              sliver: _isLoading && _products.isEmpty
                  ? SliverToBoxAdapter(child: _buildLoadingShimmer())
                  : !_isConnected
                      ? SliverToBoxAdapter(child: _buildNoConnectionView())
                      : filteredProducts.isEmpty
                          ? SliverToBoxAdapter(child: _buildEmptyProductsView())
                          : SliverToBoxAdapter(
                              child: RefreshIndicator(
                                onRefresh: () => fetchProducts(refresh: true),
                                color: Color(0xFF008080),
                                child: Column(
                                  children: [
                                    MasonryGridView.count(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 16,
                                      crossAxisSpacing: 16,
                                      itemCount: filteredProducts.length,
                                      itemBuilder: (context, index) {
                                        final product = filteredProducts[index];
                                        return ProductCard(
                                          key: ValueKey(product['product_id'] ??
                                              product['id'] ??
                                              index),
                                          product: product,
                                        );
                                      },
                                    ),
                                    if (_isLoadingMore)
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF008080)),
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

class StarRating extends StatelessWidget {
  final double rating;
  final int maxStars;
  final double size;
  final Color filledColor;
  final Color unfilledColor;

  const StarRating({
    Key? key,
    required this.rating,
    this.maxStars = 5,
    this.size = 16,
    this.filledColor = const Color(0xFFFFD700), // Gold color
    this.unfilledColor = const Color(0xFFE0E0E0), // Light gray
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        double starValue = rating - index;

        return Icon(
          starValue >= 1.0
              ? Icons.star
              : starValue >= 0.5
                  ? Icons.star_half
                  : Icons.star_border,
          color: starValue > 0 ? filledColor : unfilledColor,
          size: size,
        );
      }),
    );
  }
}

class ProductCard extends StatelessWidget {
  final dynamic product;
  final bool isRecommended;

  const ProductCard({
    Key? key,
    required this.product,
    this.isRecommended = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isInventory = product['type'] == 'inventory';
    final double originalPrice =
        double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
    final double inventoryPrice = isInventory
        ? (double.tryParse(product['inventory_price']?.toString() ?? '0') ??
            0.0)
        : originalPrice;

    int discountPercentage = 0;
    if (isInventory && originalPrice > 0) {
      discountPercentage =
          ((originalPrice - inventoryPrice) / originalPrice * 100).round();
    }

    String? imageUrl;
    if (product['images'] != null &&
        product['images'] is List &&
        product['images'].isNotEmpty) {
      final primaryImage = product['images'].firstWhere(
        (img) => img['is_primary'] == true,
        orElse: () => product['images'][0],
      );
      imageUrl = primaryImage['image_path'];
    } else if (product['image'] != null) {
      imageUrl = product['image'];
    }

    final double averageRating =
        double.tryParse(product['average_rating']?.toString() ?? '0') ?? 0.0;
    final int reviewCount =
        int.tryParse(product['review_count']?.toString() ?? '0') ?? 0;

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
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    imageUrl != null
                        ? Hero(
                            tag:
                                'product-${product['product_id'] ?? product['id'] ?? UniqueKey()}',
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              memCacheWidth: 600,
                              memCacheHeight: 600,
                              maxWidthDiskCache: 1200,
                              maxHeightDiskCache: 1200,
                              fadeInDuration: Duration(milliseconds: 300),
                              progressIndicatorBuilder:
                                  (context, url, downloadProgress) => Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: downloadProgress.progress,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF008080)),
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
                                      Icon(Icons.broken_image,
                                          color: Colors.grey[400], size: 40),
                                      SizedBox(height: 8),
                                      Text(
                                        'Image not available',
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.image_not_supported,
                                color: Colors.grey),
                          ),
                    if (product['images'] != null &&
                        product['images'] is List &&
                        product['images'].length > 1)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    if (isInventory)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    if (isRecommended)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFF008080),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Recommended',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                      // Updated rating section - now shows for both regular and recommended products
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: averageRating > 0
                            ? Row(
                                children: [
                                  StarRating(
                                    rating: averageRating,
                                    size: isRecommended
                                        ? 12
                                        : 14, // Smaller stars for recommendations
                                  ),
                                  SizedBox(width: isRecommended ? 4 : 6),
                                  Text(
                                    '${averageRating.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: isRecommended ? 10 : 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (reviewCount > 0) ...[
                                    SizedBox(width: isRecommended ? 2 : 4),
                                    Text(
                                      '($reviewCount)',
                                      style: TextStyle(
                                        fontSize: isRecommended ? 10 : 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            : Text(
                                'No reviews yet',
                                style: TextStyle(
                                  fontSize: isRecommended ? 10 : 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                      ),
                      if (isInventory)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${inventoryPrice.toStringAsFixed(2)} DA',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.red,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
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
                              '${originalPrice.toStringAsFixed(2)} DA',
                              style: TextStyle(
                                fontSize: 13,
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
                            Flexible(
                              child: Text(
                                '${originalPrice.toStringAsFixed(2)} DA',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Color(0xFF008080),
                                ),
                                overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}
