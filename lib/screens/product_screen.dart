import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:health_link/screens/dashboards/add_product_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import 'edit_product_page.dart';

class ProductScreen extends StatefulWidget {
  final int storeId;

  ProductScreen({required this.storeId});

  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> products = [];
  List<dynamic> storeProducts = [];
  List<dynamic> inventoryProducts = [];
  bool isLoading = true;
  final Color primaryColor = Color(0xFF008080);
  final ScrollController _scrollController = ScrollController();
  TextEditingController _searchController = TextEditingController();
  List<dynamic> filteredStoreProducts = [];
  List<dynamic> filteredInventoryProducts = [];
  bool isSearching = false;
  late TabController _tabController;
  String? selectedCategory;
  String? loggedInUserId; // Store the logged-in user's ID
  String? storeOwnerId; // Store the store owner's ID

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeUserAndFetchData(); // Initialize user ID and fetch data
    _tabController.addListener(() {
      if (isSearching) {
        setState(() {
          _searchController.clear();
          _filterProducts('');
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Initialize logged-in user ID and fetch store owner ID and products
  Future<void> _initializeUserAndFetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    setState(() {
      loggedInUserId = prefs.getString('user_id'); // Assumes user_id is stored
    });

    // Fetch store owner's ID
    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.43.101:8000/api/store/${widget.storeId}/owner'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final ownerData = json.decode(response.body);
        setState(() {
          storeOwnerId =
              ownerData['id'].toString(); // Adjust based on API response
        });
      } else {
        print('Failed to fetch store owner: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
        return;
      }
    } catch (e) {
      print('Error fetching store owner: $e');
      setState(() {
        isLoading = false;
      });
      return;
    }

    await _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse('http://192.168.43.101:8000/api/products/${widget.storeId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          products = jsonDecode(response.body);
          storeProducts =
              products.where((product) => product['type'] == 'new').toList();
          inventoryProducts = products
              .where((product) => product['type'] == 'inventory')
              .toList();
          filteredStoreProducts = storeProducts;
          filteredInventoryProducts = inventoryProducts;
          isLoading = false;
        });
      } else {
        print('Failed to load products: ${response.body}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }

  void _filterProducts(String query) {
    if (query.isEmpty && selectedCategory == null) {
      setState(() {
        filteredStoreProducts = storeProducts;
        filteredInventoryProducts = inventoryProducts;
      });
    } else {
      setState(() {
        filteredStoreProducts = storeProducts
            .where((product) =>
                (query.isEmpty ||
                    product['product_name']
                        .toLowerCase()
                        .contains(query.toLowerCase())) &&
                (selectedCategory == null ||
                    product['category'] == selectedCategory))
            .toList();
        filteredInventoryProducts = inventoryProducts
            .where((product) =>
                (query.isEmpty ||
                    product['product_name']
                        .toLowerCase()
                        .contains(query.toLowerCase())) &&
                (selectedCategory == null ||
                    product['category'] == selectedCategory))
            .toList();
      });
    }
  }

  void _applyFilter(String? category) {
    setState(() {
      selectedCategory = category;
      _filterProducts(_searchController.text);
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
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
                      "Store ",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Products",
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 24,
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
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.filter_list, color: primaryColor),
                      onPressed: () {
                        _showFilterOptions();
                      },
                    ),
                    if (selectedCategory != null)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(isSearching ? 140 : 88),
                child: Column(
                  children: [
                    if (isSearching)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _searchController,
                            onChanged: _filterProducts,
                            decoration: InputDecoration(
                              hintText: 'Search products...',
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
                      ),
                    Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: primaryColor,
                        labelColor: primaryColor,
                        unselectedLabelColor: Colors.grey[600],
                        indicatorWeight: 2,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        tabs: [
                          Tab(
                            icon: Icon(Icons.storefront, size: 18),
                            text: "Store",
                          ),
                          Tab(
                            icon: Icon(Icons.inventory_2, size: 18),
                            text: "Inventory",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            if (selectedCategory != null)
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, size: 16, color: primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Filtered by: ',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    Chip(
                      label: Text(
                        selectedCategory!,
                        style: TextStyle(color: primaryColor, fontSize: 12),
                      ),
                      backgroundColor: primaryColor.withOpacity(0.1),
                      deleteIcon: Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          selectedCategory = null;
                          _filterProducts(_searchController.text);
                        });
                      },
                    ),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: isLoading
                        ? _buildLoadingShimmer()
                        : filteredStoreProducts.isEmpty
                            ? _buildEmptyState(true)
                            : RefreshIndicator(
                                color: primaryColor,
                                onRefresh: _initializeUserAndFetchData,
                                child: _buildProductGrid(filteredStoreProducts),
                              ),
                  ),
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: isLoading
                        ? _buildLoadingShimmer()
                        : filteredInventoryProducts.isEmpty
                            ? _buildEmptyState(false)
                            : RefreshIndicator(
                                color: primaryColor,
                                onRefresh: _initializeUserAndFetchData,
                                child: _buildProductGrid(
                                    filteredInventoryProducts),
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          loggedInUserId != null && storeOwnerId == loggedInUserId
              ? FloatingActionButton.extended(
                  backgroundColor: primaryColor,
                  elevation: 4,
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text(
                    "Add ${_tabController.index == 0 ? 'Store' : 'Inventory'} Product",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddProductPage(
                          storeId: widget.storeId,
                          productType: _tabController.index == 0
                              ? 'new'
                              : 'inventory', // Fixed logic
                        ),
                      ),
                    );
                    if (result == true) {
                      _fetchProducts();
                    }
                  },
                )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildProductGrid(List<dynamic> products) {
    return MasonryGridView.count(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 80),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(dynamic product) {
    bool isInventory = product['type'] == 'inventory';
    // Get the primary image or first image if available
    final images = product['images'] as List<dynamic>?;
    final primaryImage = images?.firstWhere(
      (image) => image['is_primary'] == true,
      orElse: () => images != null && images.isNotEmpty ? images[0] : null,
    );

    // Check if the logged-in user is the store owner
    bool isOwner = loggedInUserId != null && storeOwnerId == loggedInUserId;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Product detail view
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: images != null && images.length > 0
                          ? Hero(
                              tag: 'product-${product['product_id']}',
                              child: CachedNetworkImage(
                                imageUrl: primaryImage['image_path'] ?? '',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: primaryColor.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    isInventory
                                        ? Icons.inventory_2_outlined
                                        : Icons.storefront_outlined,
                                    size: 50,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: Icon(
                                isInventory
                                    ? Icons.inventory_2_outlined
                                    : Icons.storefront_outlined,
                                size: 50,
                                color: Colors.grey[400],
                              ),
                            ),
                    ),
                    if (images != null && images.length > 1)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${images.length} images',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          "${product['type'] == 'new' ? product['price'] : product['inventory_price']} DA",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isInventory
                              ? Colors.amber[700]
                              : Colors.blue[700],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (isInventory
                                      ? Colors.amber[700]
                                      : Colors.blue[700])!
                                  .withOpacity(0.3),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isInventory
                                  ? Icons.inventory_2
                                  : Icons.storefront,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              isInventory ? "Inventory" : "Store",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
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
                          padding: EdgeInsets.symmetric(vertical: 4),
                          color: Colors.red.withOpacity(0.7),
                          child: Text(
                            'Low Stock: ${product['stock']}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
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
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
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
                  ],
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['product_name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      if (product['category'] != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCategory = product['category'];
                              _filterProducts(_searchController.text);
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedCategory == product['category']
                                    ? primaryColor
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              product['category'],
                              style: TextStyle(
                                color: selectedCategory == product['category']
                                    ? primaryColor
                                    : Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (isOwner) // Only show options for the owner
                            InkWell(
                              onTap: () {
                                _showProductOptions(product);
                              },
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
              ],
            ),
          ),
        ),
      ),
    );
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
                              product['type'] == 'inventory'
                                  ? Icons.inventory_2_outlined
                                  : Icons.storefront_outlined,
                              color: Colors.grey[400],
                            ),
                          ),
                        )
                      : Icon(
                          product['type'] == 'inventory'
                              ? Icons.inventory_2_outlined
                              : Icons.storefront_outlined,
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
                      if (product['category'] != null)
                        Text(
                          product['category'],
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
                    "${product['type'] == 'new' ? product['price'] : product['inventory_price']} DA",
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
            if (isOwner) ...[
              _buildOptionTile(
                icon: Icons.edit,
                iconColor: primaryColor,
                title: 'Edit Product',
                subtitle: 'Update product details',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProductPage(
                        product: product,
                      ),
                    ),
                  ).then((result) {
                    if (result == true) {
                      _fetchProducts();
                    }
                  });
                },
              ),
              _buildOptionTile(
                icon: Icons.delete_outline,
                iconColor: Colors.red,
                title: 'Delete Product',
                subtitle: 'Remove this product',
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteProduct(product['product_id']);
                },
              ),
              if (product['type'] == 'new')
                _buildOptionTile(
                  icon: Icons.inventory_2_outlined,
                  iconColor: Colors.amber[700]!,
                  title: 'Move to Inventory',
                  subtitle: 'Change product type to inventory',
                  onTap: () {
                    Navigator.pop(context);
                    _showInventoryPriceDialog(product);
                  },
                ),
              if (product['type'] == 'inventory')
                _buildOptionTile(
                  icon: Icons.storefront_outlined,
                  iconColor: Colors.blue[700]!,
                  title: 'Move to Store',
                  subtitle: 'Change product type to store',
                  onTap: () {
                    Navigator.pop(context);
                    // Implement move to store logic if needed
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
                  'You cannot edit or manage this product',
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

  Future<void> _deleteProduct(int productId) async {
    setState(() => isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    try {
      final response = await http.delete(
        Uri.parse('http://192.168.43.101:8000/api/product/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: primaryColor,
          ),
        );
        _fetchProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete product: ${response.body}'),
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

  void _showInventoryPriceDialog(dynamic product) {
    final TextEditingController priceController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Set Inventory Price'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the inventory price for "${product['product_name']}"',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Inventory Price (DA)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.monetization_on_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Move'),
            onPressed: () {
              final inputText = priceController.text.trim();
              if (inputText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a price')),
                );
                return;
              }
              final parsedPrice = double.tryParse(inputText);
              if (parsedPrice == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Invalid number format')),
                );
                return;
              }
              Navigator.of(context).pop();
              _moveToInventory(product['product_id'], parsedPrice);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _moveToInventory(int productId, double inventoryPrice) async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication token not found.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => isLoading = false);
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('http://192.168.43.101:8000/api/products/stock-clearance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'store_product_id': productId,
          'inventory_price': inventoryPrice,
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product moved to inventory successfully'),
            backgroundColor: primaryColor,
          ),
        );
        _fetchProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${response.body}'),
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

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          itemCount: 8,
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.white,
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: 120,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: 80,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 10,
                            width: 50,
                            color: Colors.white,
                          ),
                          Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
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
      ),
    );
  }

  Widget _buildEmptyState(bool isStore) {
    bool isOwner = loggedInUserId != null && storeOwnerId == loggedInUserId;

    return Center(
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
              isStore ? Icons.storefront_outlined : Icons.inventory_2_outlined,
              size: 60,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 24),
          Text(
            isSearching
                ? "No products match your search"
                : isStore
                    ? "No store products available"
                    : "No inventory products available",
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
                  ? "Try different keywords or remove filters"
                  : isStore
                      ? "Add your first store product to get started with selling"
                      : "Add your first inventory item to track your stock",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 32),
          if (!isSearching && isOwner)
            ElevatedButton.icon(
              icon: Icon(isStore ? Icons.storefront : Icons.inventory_2),
              label: Text("Add ${isStore ? "Store" : "Inventory"} Product"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProductPage(
                      storeId: widget.storeId,
                      productType: isStore ? 'inventory' : 'new', // Fixed logic
                    ),
                  ),
                );
                if (result == true) {
                  _fetchProducts();
                }
              },
            ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    List<dynamic> currentProducts =
        _tabController.index == 0 ? storeProducts : inventoryProducts;
    List<String> categories = _getUniqueCategories(currentProducts);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.filter_list, color: primaryColor),
                SizedBox(width: 12),
                Text(
                  "Filter ${_tabController.index == 0 ? 'Store' : 'Inventory'} Products",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              "Select Category",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            categories.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No categories available',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  )
                : Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((category) {
                          bool isSelected = selectedCategory == category;
                          return InkWell(
                            onTap: () => _applyFilter(category),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[800],
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  child: Text("Clear All"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () {
                    setState(() {
                      selectedCategory = null;
                      _filterProducts(_searchController.text);
                    });
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton(
                  child: Text("Apply"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getUniqueCategories(List<dynamic> productList) {
    Set<String> categories = {};
    for (var product in productList) {
      if (product['category'] != null && product['category'].isNotEmpty) {
        categories.add(product['category']);
      }
    }
    return categories.toList();
  }
}
