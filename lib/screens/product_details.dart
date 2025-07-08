import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_link/screens/order_checkout_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../user_profile/profile_screen.dart';
import 'cart_manager.dart';

class ProductDetailsPage extends StatefulWidget {
  final dynamic product;

  const ProductDetailsPage({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
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

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  bool _isLoading = true;
  Map<String, dynamic> _productDetails = {};
  int _quantity = 1;
  String? _userRole;
  String? _ownerUserId; // Store the owner's userId
  String? _currentUserId; // Store the logged-in user's ID
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;
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
    String? role = prefs.getString('user_role');
    String? userId = prefs.getString('user_id'); // Fetch current user's ID

    try {
      // Fetch product details
      final url =
          Uri.parse('http://192.168.43.101:8000/api/product/${widget.product}');
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
          _userRole = role;
          _currentUserId = userId; // Set current user's ID
        });

        // Fetch store owner's userId if store_id exists
        if (_productDetails['store_id'] != null) {
          try {
            final ownerResponse = await http.get(
              Uri.parse(
                  'http://192.168.43.101:8000/api/store/${_productDetails['store_id']}/owner'),
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            );

            if (ownerResponse.statusCode == 200) {
              final ownerData = json.decode(ownerResponse.body);
              setState(() {
                _ownerUserId =
                    ownerData['id'].toString(); // Adjust if field is different
              });
            } else {
              print('Failed to fetch store owner: ${ownerResponse.body}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load store owner information'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            print('Error fetching store owner: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error fetching store owner'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load product details'),
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
      setState(() {
        _isLoading = false;
      });
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

  void _addToCart() async {
    final cartItem = {
      'product_id': _productDetails['product_id'],
      'quantity': _quantity,
      'product_name': _productDetails['product_name'],
      'price': _productDetails['type'] == 'inventory'
          ? _productDetails['inventory_price']
          : _productDetails['price'],
      'image': _primaryImagePath,
    };

    await CartManager.addToCart(cartItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Added to cart: ${_productDetails['product_name']} x $_quantity'),
        backgroundColor: Color(0xFF008080),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () async {
            final cartItems = await CartManager.getCartItems();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderCheckoutPage(cartItems: cartItems),
              ),
            );
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

  List<dynamic> get _productImages {
    if (_productDetails.containsKey('images') &&
        _productDetails['images'] is List) {
      return _productDetails['images'];
    }
    return [];
  }

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

  bool get _isOwnProduct {
    return _currentUserId != null &&
        _ownerUserId != null &&
        _currentUserId == _ownerUserId;
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
        ],
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              _showTitle ? Brightness.dark : Brightness.light,
        ),
      ),
      body: _isLoading
          ? _buildLoadingShimmer()
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  expandedHeight: MediaQuery.of(context).size.height * 0.4,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      children: [
                        _buildImageGallery(),
                        if (_productDetails['type'] == 'inventory' &&
                            _productDetails['price'] != null &&
                            _productDetails['inventory_price'] != null)
                          Positioned(
                            top: 20,
                            right: 20,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
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
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _productDetails['product_name'] ??
                                        'Product Name',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  if (_productDetails['category'] != null)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
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
                                  SizedBox(height: 8),
                                  if (_productDetails['average_rating'] != null)
                                    Row(
                                      children: [
                                        StarRating(
                                          rating: double.tryParse(
                                                  _productDetails[
                                                          'average_rating']
                                                      .toString()) ??
                                              0.0,
                                          size: 18,
                                          filledColor: Color(0xFFFFD700),
                                          unfilledColor: Colors.grey[300]!,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '(${double.tryParse(_productDetails['average_rating'].toString())?.toStringAsFixed(1) ?? '0.0'})',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    )
                                ],
                              ),
                            ),
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
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: Colors.red[300]!),
                                        ),
                                        child: Text(
                                          '${_calculateDiscountPercentage(_productDetails['price'].toString(), _productDetails['inventory_price'].toString())}% OFF',
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
                        if (_userRole != 'Supplier' &&
                            _productDetails['stock'] != null &&
                            _productDetails['stock'] > 0 &&
                            !_isOwnProduct)
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
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 12),
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
                        if (_isOwnProduct)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'this is your own product.',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        SizedBox(height: 24),
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
                          _productDetails['description'] ??
                              'No description available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 24),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                  onPressed: _ownerUserId != null
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProfileScreen(
                                                userId: _ownerUserId,
                                              ),
                                            ),
                                          );
                                        }
                                      : null,
                                  child: Text(
                                    'Visit Profile',
                                    style: TextStyle(
                                      color: _ownerUserId != null
                                          ? Color(0xFF008080)
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: 32),
                        if (_productDetails['type'] != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
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
                              _productDetails['type'] == 'new'
                                  ? 'New Product'
                                  : 'Inventory Item',
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
      bottomSheet: _isLoading || _userRole == 'Supplier' || _isOwnProduct
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
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: _productDetails['stock'] != null &&
                                _productDetails['stock'] > 0
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
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: _productDetails['stock'] != null &&
                                _productDetails['stock'] > 0
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

  Widget _buildImageGallery() {
    if (_productImages.isEmpty && _productDetails['image'] == null) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey, size: 64),
        ),
      );
    }

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
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF008080)),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image,
                          color: Colors.grey[400], size: 64),
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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
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

  String _calculateDiscountPercentage(
      String originalPrice, String discountedPrice) {
    try {
      double original = double.parse(originalPrice.replaceAll('DA', '').trim());
      double discounted =
          double.parse(discountedPrice.replaceAll('DA', '').trim());
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
                  Container(
                    width: double.infinity,
                    height: 32,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: 100,
                    height: 24,
                    color: Colors.white,
                  ),
                  SizedBox(height: 32),
                  Container(
                    width: 120,
                    height: 20,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 100,
                    color: Colors.white,
                  ),
                  SizedBox(height: 24),
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
