import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import 'dashboards/healthcare_dashboard.dart';

class MyOrderScreen extends StatefulWidget {
  const MyOrderScreen({Key? key}) : super(key: key);

  @override
  State<MyOrderScreen> createState() => _MyOrderScreenState();
}

class _MyOrderScreenState extends State<MyOrderScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  final Color primaryColor = const Color(0xFF008080);
  final secondaryColor = const Color(0xFF232F34);

  @override
  void initState() {
    super.initState();
    fetchBuyerOrders();
  }

  Future<void> fetchBuyerOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final token = prefs.getString('auth_token');

    if (userId == null) {
      if (mounted) {
        _showSnackbar("User ID not found");
        setState(() => _isLoading = false);
      }
      return;
    }

    final url = 'http://192.168.43.101:8000/api/buyer-orders';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final filteredOrders = data['orders']
            .where((order) => order['buyer_id'].toString() == userId)
            .toList();

        if (mounted) {
          setState(() {
            _orders = filteredOrders;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackbar("Error: $e");
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        backgroundColor: primaryColor,
      ),
    );
  }

  void _showOrderDetails(dynamic order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderDetailsSheet(
        order: order,
        primaryColor: primaryColor,
      ),
    );
  }

  Color getStatusColor(String? status) {
    switch (status?.toLowerCase() ?? 'pending') {
      case 'delivered':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'pending':
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String? status) {
    switch (status?.toLowerCase() ?? 'pending') {
      case 'delivered':
        return Icons.check_circle;
      case 'shipped':
        return Icons.local_shipping;
      case 'processing':
        return Icons.sync;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.hourglass_empty;
    }
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Not specified';
    }

    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "Health",
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              TextSpan(
                text: "Link",
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),

            ),
            onPressed: () {
              // Handle notifications
            },
          ),
          const SizedBox(width: 8),
        ],
        iconTheme: IconThemeData(color: primaryColor),

      ),
      body: _isLoading
          ? _buildLoadingState()
          : _orders.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        color: primaryColor,
        onRefresh: fetchBuyerOrders,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _orders.length,
          itemBuilder: (context, index) {
            return _buildOrderCard(_orders[index]);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(height: 200),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "No orders found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your order history will appear here",
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to shop page
              // Navigator.of(context).push(MaterialPageRoute(builder: (_) => ShopScreen()));
            },
            icon: const Icon(Icons.shopping_cart_outlined),
            label: const Text("Start Shopping"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final seller = order['seller'];
    final items = order['items'];
    final status = order['order_status'] ?? 'Pending';
    final totalItems = items.length;
    final firstItem = items.isNotEmpty ? items[0] : null;
    final firstProduct = firstItem != null ? firstItem['product'] : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header
            Container(
              decoration: BoxDecoration(
                color: getStatusColor(status).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    getStatusIcon(status),
                    color: getStatusColor(status),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: getStatusColor(status),
                    ),
                  ),
                  const Spacer(),

                ],
              ),
            ),

            // Order preview
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seller info
                  if (seller != null)
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: primaryColor.withOpacity(0.2),
                          radius: 20,
                          child: Text(
                            (seller['first_name'] ?? 'S')[0].toUpperCase(),
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Seller",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "${seller['first_name'] ?? ''} ${seller['last_name'] ?? ''}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          formatDate(order['created_at']),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Product preview
                  if (firstProduct != null)
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildProductImage(firstProduct['image']),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                firstProduct['product_name'] ?? 'Unnamed Product',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Quantity: ${firstItem['quantity']}",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                              if (totalItems > 1)
                                Text(
                                  "+ ${totalItems - 1} more item${totalItems > 2 ? 's' : ''}",
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Action footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (order['estimated_delivery'] != null)
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          "Est. Delivery: ${formatDate(order['estimated_delivery'])}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showOrderDetails(order),
                    icon: const Icon(Icons.chevron_right, size: 18),
                    label: const Text("Details"),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    return SizedBox(
      width: 60,
      height: 60,
      child: imageUrl != null && imageUrl.isNotEmpty
          ? CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008080)),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: primaryColor.withOpacity(0.1),
          child: Center(
            child: Icon(
              Icons.shopping_bag,
              color: primaryColor,
              size: 28,
            ),
          ),
        ),
      )
          : Container(
        color: primaryColor.withOpacity(0.1),
        child: Center(
          child: Icon(
            Icons.shopping_bag,
            color: primaryColor,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class OrderDetailsSheet extends StatelessWidget {
  final dynamic order;
  final Color primaryColor;

  const OrderDetailsSheet({
    Key? key,
    required this.order,
    required this.primaryColor,
  }) : super(key: key);

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Not specified';
    }

    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color getStatusColor(String? status) {
    switch (status?.toLowerCase() ?? 'pending') {
      case 'delivered':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'pending':
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrderProgress(String status) {
    final steps = ['pending', 'processing', 'shipped', 'delivered'];
    final currentIndex = steps.indexOf(status.toLowerCase());

    if (currentIndex == -1 || status.toLowerCase() == 'cancelled') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order Progress",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length, (index) {
              final isActive = index <= currentIndex;
              final isLast = index == steps.length - 1;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: isActive ? primaryColor : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getStepIcon(steps[index]),
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            steps[index].capitalize(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive ? primaryColor : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index < currentIndex ? primaryColor : Colors.grey[300],
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _getStepIcon(String step) {
    switch (step) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'processing':
        return Icons.sync;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = order['order_status'] ?? 'Pending';
    final seller = order['seller'];
    final items = order['items'];
    final total = order['total_amount'] ?? 0.0;
    final formattedTotal = total is String ? total : '\$${total.toStringAsFixed(2)}';

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [

                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: getStatusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Order progress tracker
              _buildOrderProgress(status.toLowerCase()),

              // Order details
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Order summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Order Summary",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow("Order Date", formatDate(order['created_at'])),
                          if (order['estimated_delivery'] != null)
                            _buildInfoRow("Est. Delivery", formatDate(order['estimated_delivery'])),
                          if (order['delivery_address'] != null)
                            _buildInfoRow("Delivery Address", order['delivery_address']),
                          _buildInfoRow("Total Amount", formattedTotal),
                          _buildInfoRow("Payment Method", order['payment_method'] ?? "Not specified"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Seller info
                    if (seller != null) ...[
                      Text(
                        "Seller",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: primaryColor.withOpacity(0.2),
                              radius: 25,
                              child: Text(
                                (seller['first_name'] ?? 'S')[0].toUpperCase(),
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${seller['first_name'] ?? ''} ${seller['last_name'] ?? ''}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),

                                ],
                              ),


                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Products list
                    Text(
                      "Products (${items.length})",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...items.map<Widget>((item) {
                      final product = item['product'];
                      return ProductDetailsCard(
                        product: product,
                        quantity: item['quantity'],
                        primaryColor: primaryColor,
                      );
                    }).toList(),

                    const SizedBox(height: 32),

                    // Action buttons

                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const Text(
            ": ",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductDetailsCard extends StatefulWidget {
  final dynamic product;
  final int quantity;
  final Color primaryColor;


  const ProductDetailsCard({
    Key? key,
    required this.product,

    required this.quantity,
    required this.primaryColor,
  }) : super(key: key);

  @override
  State<ProductDetailsCard> createState() => _ProductDetailsCardState();
}

class _ProductDetailsCardState extends State<ProductDetailsCard> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildProductImage(widget.product['image']),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product != null ? (widget.product['product_name'] ?? 'Unnamed Product') : 'N/A',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              widget.product != null ?
                              (widget.product['price'] != null ?
                              '\$${widget.product['price']}' : 'Price not available') :
                              'N/A',
                              style: TextStyle(
                                color: widget.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: widget.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Qty: ${widget.quantity}",
                                style: TextStyle(
                                  color: widget.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                    ),
                    onPressed: _toggleExpanded,
                  ),
                ],
              ),
            ),
            if (_isExpanded)
              Container(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    if (widget.product['description'] != null) ...[
                      Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.product['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Additional product details
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (widget.product['category'] != null)
                          _buildProductDetailChip(
                            "Category",
                            widget.product['category'],
                            Icons.category_outlined,
                          ),
                        if (widget.product['brand'] != null)
                          _buildProductDetailChip(
                            "Brand",
                            widget.product['brand'],
                            Icons.branding_watermark_outlined,
                          ),
                        if (widget.product['weight'] != null)
                          _buildProductDetailChip(
                            "Weight",
                            widget.product['weight'].toString(),
                            Icons.fitness_center_outlined,
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Action buttons

                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetailChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            "$label: $value",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    return SizedBox(
      width: 80,
      height: 80,
      child: imageUrl != null && imageUrl.isNotEmpty
          ? CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008080)),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: widget.primaryColor.withOpacity(0.1),
          child: Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: widget.primaryColor,
              size: 30,
            ),
          ),
        ),
      )
          : Container(
        color: widget.primaryColor.withOpacity(0.1),
        child: Center(
          child: Icon(
            Icons.shopping_bag,
            color: widget.primaryColor,
            size: 30,
          ),
        ),
      ),
    );
  }
}

// Extension to capitalize first letter of string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}