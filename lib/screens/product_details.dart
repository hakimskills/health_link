import 'package:flutter/material.dart';
import 'package:health_link/screens/dashboards/healthcare_dashboard.dart';
import 'package:health_link/screens/store_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:health_link/screens/order_checkout_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ProductDetailsPage extends StatefulWidget {
  final dynamic product;

  const ProductDetailsPage({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  bool _isLoading = true;
  Map<String, dynamic> _productDetails = {};
  int _quantity = 1;
  String? _userRole; // Store user role
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;

  // Controller for the image carousel
  final CarouselController _carouselController = CarouselController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchProductDetails();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 200 && !_showTitle) {
      setState(() {
        _showTitle = true;
      });
    } else if (_scrollController.offset <= 200 && _showTitle) {
      setState(() {
        _showTitle = false;
      });
    }
  }

  Future<void> fetchProductDetails() async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    String? role = prefs.getString('user_role'); // Fetch user role

    try {
      final url = Uri.parse('http://192.168.43.101:8000/api/product/${widget.product}');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          _productDetails = decoded;
          _userRole = role; // Set user role
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load product details'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _incrementQuantity() {
    if (_quantity < (_productDetails['stock'] ?? 100)) {
      setState(() {
        _quantity++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum available stock reached'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _addToCart() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to cart: ${_productDetails['product_name']} x $_quantity'),
        backgroundColor: Color(0xFF008080),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to cart
          },
        ),
      ),
    );
  }

  void _buyNow() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderCheckoutPage(
          product: _productDetails,
          quantity: _quantity,
        ),
      ),
    );
  }

  // Get product images or return an empty list if not available
  List<dynamic> get _productImages {
    if (_productDetails.containsKey('images') && _productDetails['images'] is List) {
      return _productDetails['images'];
    }
    return [];
  }

  // Get primary image path or first image path or null
  String? get _primaryImagePath {
    if (_productImages.isNotEmpty) {
      final primaryImage = _productImages.firstWhere(
            (img) => img['is_primary'] == true,
        orElse: () => _productImages.first,
      );
      return primaryImage['image_path'];
    }
    return _productDetails['image'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: _showTitle ? 2 : 0,
        backgroundColor: _showTitle ? Colors.white : Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: _showTitle ? Color(0xFF008080) : Colors.white,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: _showTitle
            ? Text(
          _productDetails['product_name'] ?? 'Product Details',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        )
            : null,
        actions: [
          IconButton(
            icon: Icon(
              Icons.share_outlined,
              color: _showTitle ? Color(0xFF008080) : Colors.white,
            ),
            onPressed: () {
              // Implement share functionality
            },
          ),
          IconButton(
            icon: Icon(
              Icons.favorite_border,
              color: _showTitle ? Color(0xFF008080) : Colors.white,
            ),
            onPressed: () {
              // Implement favorite functionality
            },
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: _showTitle ? Brightness.dark : Brightness.light,
        ),
      ),
      body: _isLoading
          ? _buildLoadingShimmer()
          : CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Product Image Gallery
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.4,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  _buildImageGallery(),
                  // Discount badge for inventory items
                  if (_productDetails['type'] == 'inventory' &&
                      _productDetails['price'] != null &&
                      _productDetails['inventory_price'] != null)
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Stock sale',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Product Details
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image indicators if we have multiple images
                  if (_productImages.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Center(
                        child: AnimatedSmoothIndicator(
                          activeIndex: _currentImageIndex,
                          count: _productImages.length,
                          effect: WormEffect(
                            dotHeight: 8,
                            dotWidth: 8,
                            activeDotColor: Color(0xFF008080),
                            dotColor: Colors.grey[300]!,
                          ),
                        ),
                      ),
                    ),

                  // Product Name and Category
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _productDetails['product_name'] ?? 'Product Name',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            if (_productDetails['category'] != null)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Color(0xFFE6F7F7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _productDetails['category'],
                                  style: TextStyle(
                                    color: Color(0xFF008080),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (_productDetails['type'] == 'inventory' &&
                              _productDetails['price'] != null &&
                              _productDetails['inventory_price'] != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_productDetails['inventory_price']}DA',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF008080),
                                  ),
                                ),
                                Text(
                                  '${_productDetails['price']}DA',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey[600],
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.red[300]!),
                                  ),
                                  child: Text(
                                    '${_calculateDiscountPercentage(_productDetails['price'], _productDetails['inventory_price'])}% OFF',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              '${_productDetails['price'] ?? '0.00'}DA',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF008080),
                              ),
                            ),
                          SizedBox(height: 4),
                          if (_productDetails['stock'] != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 16,
                                  color: _productDetails['stock'] > 10
                                      ? Colors.green
                                      : _productDetails['stock'] > 0
                                      ? Colors.orange
                                      : Colors.red,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _productDetails['stock'] > 0
                                      ? '${_productDetails['stock']} in stock'
                                      : 'Out of stock',
                                  style: TextStyle(
                                    color: _productDetails['stock'] > 10
                                        ? Colors.green
                                        : _productDetails['stock'] > 0
                                        ? Colors.orange
                                        : Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Quantity Selector (only for non-Suppliers)
                  if (_userRole != 'Supplier' &&
                      _productDetails['stock'] != null &&
                      _productDetails['stock'] > 0)
                    Row(
                      children: [
                        Text(
                          'Quantity:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove, size: 18),
                                onPressed: _decrementQuantity,
                                color: Color(0xFF008080),
                                constraints: BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '$_quantity',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.add, size: 18),
                                onPressed: _incrementQuantity,
                                color: Color(0xFF008080),
                                constraints: BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  SizedBox(height: 24),

                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _productDetails['description'] ?? 'No description available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: 24),

                  // Store Information
                  if (_productDetails['store_id'] != null)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Color(0xFF008080).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.store,
                              color: Color(0xFF008080),
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text(
                                  'Verified Seller',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StoreScreen(
                                    storeId: _productDetails['store_id'],
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'Visit Store',
                              style: TextStyle(
                                color: Color(0xFF008080),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 32),

                  // Type Badge
                  if (_productDetails['type'] != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _productDetails['type'] == 'new'
                            ? Colors.blue[50]
                            : Colors.amber[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _productDetails['type'] == 'new'
                              ? Colors.blue[300]!
                              : Colors.amber[300]!,
                        ),
                      ),
                      child: Text(
                        _productDetails['type'] == 'new' ? 'New Product' : 'Inventory Item',
                        style: TextStyle(
                          color: _productDetails['type'] == 'new'
                              ? Colors.blue[700]
                              : Colors.amber[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      // Show bottomSheet only for non-Suppliers
      bottomSheet: _isLoading || _userRole == 'Supplier'
          ? null
          : Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFF008080)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.chat_outlined, color: Color(0xFF008080)),
                  onPressed: () {
                    // Implement chat functionality
                  },
                ),
              ),
              SizedBox(width: 12),
              // Add to Cart Button
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: _productDetails['stock'] != null && _productDetails['stock'] > 0
                      ? _addToCart
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF008080),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Color(0xFF008080)),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Add to Cart',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Buy Now Button
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: _productDetails['stock'] != null && _productDetails['stock'] > 0
                      ? _buyNow
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF008080),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Buy Now',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build image gallery carousel
  Widget _buildImageGallery() {
    // If no images available, show a fallback
    if (_productImages.isEmpty && _productDetails['image'] == null) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey, size: 64),
        ),
      );
    }

    // If only one image or using the old 'image' field
    if (_productImages.isEmpty && _productDetails['image'] != null) {
      return Hero(
        tag: 'product-${widget.product}',
        child: CachedNetworkImage(
          imageUrl: _productDetails['image'],
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008080)),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.grey[400], size: 64),
                SizedBox(height: 16),
                Text(
                  'Image not available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Multiple images - create a carousel
    return Hero(
      tag: 'product-${widget.product}',
      child: CarouselSlider.builder(
        itemCount: _productImages.length,
        options: CarouselOptions(
          height: MediaQuery.of(context).size.height * 0.4,
          viewportFraction: 1.0,
          enlargeCenterPage: false,
          autoPlay: _productImages.length > 1,
          autoPlayInterval: Duration(seconds: 3),
          onPageChanged: (index, reason) {
            setState(() {
              _currentImageIndex = index;
            });
          },
        ),
        itemBuilder: (context, index, realIndex) {
          final imageUrl = _productImages[index]['image_path'];
          return GestureDetector(
            onTap: () {
              _showFullScreenImage(context, index);
            },
            child: Container(
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008080)),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.grey[400], size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Image not available',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Show fullscreen image viewer
  void _showFullScreenImage(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: CarouselSlider.builder(
                itemCount: _productImages.length,
                options: CarouselOptions(
                  height: MediaQuery.of(context).size.height,
                  viewportFraction: 1.0,
                  initialPage: initialIndex,
                  enableInfiniteScroll: _productImages.length > 1,
                ),
                itemBuilder: (context, index, realIndex) {
                  final imageUrl = _productImages[index]['image_path'];
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to calculate discount percentage
  String _calculateDiscountPercentage(String originalPrice, String discountedPrice) {
    try {
      double original = double.parse(originalPrice.replaceAll('DA', '').trim());
      double discounted = double.parse(discountedPrice.replaceAll('DA', '').trim());

      if (original <= 0) return '0';

      double percentage = ((original - discounted) / original) * 100;
      return percentage.toStringAsFixed(0);
    } catch (e) {
      return '0';
    }
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title placeholder
                  Container(
                    width: double.infinity,
                    height: 32,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  // Price placeholder
                  Container(
                    width: 100,
                    height: 24,
                    color: Colors.white,
                  ),
                  SizedBox(height: 32),
                  // Description title placeholder
                  Container(
                    width: 120,
                    height: 20,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  // Description content placeholder
                  Container(
                    width: double.infinity,
                    height: 100,
                    color: Colors.white,
                  ),
                  SizedBox(height: 24),
                  // Store placeholder
                  Container(
                    width: double.infinity,
                    height: 80,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}