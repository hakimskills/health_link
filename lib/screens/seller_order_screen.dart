import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({Key? key}) : super(key: key);

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  final Color primaryColor = const Color(0xFF008080);
  final Color secondaryColor = const Color(0xFF232F34);
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchSellerOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchSellerOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    String? sellerId = prefs.getString('user_id');

    final url =
        'http://192.168.43.101:8000/api/product-orders/seller/$sellerId';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] != 'success') {
          throw Exception('API returned status: ${data['status']}');
        }

        if (mounted) {
          setState(() {
            _orders = data['orders'] ?? []; // Extract orders array
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid seller ID');
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackbar("Error: $e");
      }
    }
  }

  Future<void> approveOrder(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.put(
        Uri.parse(
            'http://192.168.43.101:8000/api/product-orders/$orderId/approve'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print(response.body);

      if (response.statusCode == 200) {
        _showSnackbar("Order approved successfully");
        await fetchSellerOrders();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to approve order');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar("Error: $e");
    }
  }

  Future<void> markAsShipped(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.put(
        Uri.parse(
            'http://192.168.43.101:8000/api/product-orders/$orderId/ship'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print(response.body);

      if (response.statusCode == 200) {
        _showSnackbar("Order marked as shipped successfully");
        await fetchSellerOrders();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Failed to mark order as shipped');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar("Error: $e");
    }
  }

  Future<void> cancelOrder(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.put(
        Uri.parse(
            'http://192.168.43.101:8000/api/product-orders/$orderId/cancel'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print(response.body);

      if (response.statusCode == 200) {
        _showSnackbar("Order canceled successfully");
        await fetchSellerOrders();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to cancel order');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar("Error: $e");
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
      builder: (context) => SellerOrderDetailsSheet(
        order: order,
        primaryColor: primaryColor,
        onApprove: order['order_status'].toLowerCase() == 'pending'
            ? () {
                Navigator.pop(context);
                approveOrder(order['product_order_id']);
              }
            : null,
        onShip: order['order_status'].toLowerCase() == 'processing'
            ? () {
                Navigator.pop(context);
                markAsShipped(order['product_order_id']);
              }
            : null,
        onCancel: order['order_status'].toLowerCase() == 'pending'
            ? () {
                Navigator.pop(context);
                cancelOrder(order['product_order_id']);
              }
            : null,
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
      case 'canceled':
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
      case 'canceled':
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

  List<dynamic> _getFilteredOrders(String status) {
    return _orders.where((order) {
      final orderStatus = order['order_status']?.toLowerCase() ?? 'pending';
      if (status == 'pending') {
        return orderStatus == 'pending';
      } else if (status == 'active') {
        return orderStatus == 'processing' || orderStatus == 'shipped';
      } else {
        return orderStatus == 'delivered' ||
            orderStatus == 'cancelled' ||
            orderStatus == 'canceled';
      }
    }).toList();
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Active"),
            Tab(text: "Completed"),
          ],
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
              child: Icon(Icons.refresh, color: primaryColor, size: 20),
            ),
            onPressed: fetchSellerOrders,
          ),
          const SizedBox(width: 8),
        ],
        iconTheme: IconThemeData(color: primaryColor),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList('pending'),
                _buildOrdersList('active'),
                _buildOrdersList('completed'),
              ],
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(height: 200),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;

    switch (status) {
      case 'pending':
        message = "No pending orders";
        icon = Icons.hourglass_empty;
        break;
      case 'active':
        message = "No active orders";
        icon = Icons.sync;
        break;
      case 'completed':
        message = "No completed orders";
        icon = Icons.check_circle_outline;
        break;
      default:
        message = "No orders found";
        icon = Icons.shopping_bag_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your orders will appear here",
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(String status) {
    final filteredOrders = _getFilteredOrders(status);

    if (filteredOrders.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: fetchSellerOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(filteredOrders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final buyer = order['buyer'];
    final items = order['items'];
    final status = order['order_status'] ?? 'Pending';
    final totalItems = items.length;
    final firstItem = items.isNotEmpty ? items[0] : null;
    final firstProduct = firstItem != null ? firstItem['product'] : null;
    final isPending = status.toLowerCase() == 'pending';
    final isProcessing = status.toLowerCase() == 'processing';
    // Select primary image or first image
    final images = firstProduct?['images'] as List<dynamic>?;
    final primaryImage = images?.firstWhere(
      (image) => image['is_primary'] == true,
      orElse: () => images?.isNotEmpty == true ? images![0] : null,
    );

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
                  if (isPending) ...[
                    OutlinedButton.icon(
                      onPressed: () => approveOrder(order['product_order_id']),
                      icon: const Icon(
                        Icons.check,
                        size: 16,
                        color: Color(0xFF008080),
                      ),
                      label: const Text("Approve"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF008080),
                        side: const BorderSide(color: Color(0xFF008080)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => cancelOrder(order['product_order_id']),
                      icon: const Icon(
                        Icons.cancel,
                        size: 16,
                        color: Colors.red,
                      ),
                      label: const Text("Cancel"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                      ),
                    ),
                  ],
                  if (isProcessing)
                    OutlinedButton.icon(
                      onPressed: () => markAsShipped(order['product_order_id']),
                      icon: const Icon(Icons.local_shipping, size: 16),
                      label: const Text("Ship"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF008080),
                        side: const BorderSide(color: Color(0xFF008080)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                      ),
                    ),
                ],
              ),
            ),

            // Order preview
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Buyer info
                  if (buyer != null)
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: primaryColor.withOpacity(0.2),
                          radius: 20,
                          child: Text(
                            (buyer['first_name'] ?? 'B')[0].toUpperCase(),
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
                              "Buyer",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "${buyer['first_name'] ?? ''} ${buyer['last_name'] ?? ''}",
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
                          child:
                              _buildProductImage(primaryImage?['image_path']),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                firstProduct['product_name'] ??
                                    'Unnamed Product',
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
                  if (order['total_amount'] != null)
                    Text(
                      "Total: ${order['total_amount'] is String ? order['total_amount'] : order['total_amount'].toStringAsFixed(2)} DA",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showOrderDetails(order),
                    icon: const Icon(Icons.chevron_right, size: 18),
                    label: const Text("Details"),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF008080)),
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

class SellerOrderDetailsSheet extends StatelessWidget {
  final dynamic order;
  final Color primaryColor;
  final VoidCallback? onApprove;
  final VoidCallback? onShip;
  final VoidCallback? onCancel;

  const SellerOrderDetailsSheet({
    Key? key,
    required this.order,
    required this.primaryColor,
    this.onApprove,
    this.onShip,
    this.onCancel,
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
      case 'canceled':
        return Colors.red;
      case 'pending':
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrderProgress(String status) {
    final steps = ['pending', 'processing', 'shipped', 'delivered'];
    final currentIndex = steps.indexOf(status.toLowerCase());

    if (currentIndex == -1 ||
        status.toLowerCase() == 'cancelled' ||
        status.toLowerCase() == 'canceled') {
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
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
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
                          color: index < currentIndex
                              ? primaryColor
                              : Colors.grey[300],
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = order['order_status'] ?? 'Pending';
    final buyer = order['buyer'];
    final items = order['items'];
    final total = order['total_amount'] ?? 0.0;
    final formattedTotal =
        total is String ? total : '${total.toStringAsFixed(2)} DA';
    final isPending = status.toLowerCase() == 'pending';
    final isProcessing = status.toLowerCase() == 'processing';

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

              // Header with status
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
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
                          _buildInfoRow(
                              "Order Date", formatDate(order['created_at'])),
                          if (order['estimated_delivery'] != null)
                            _buildInfoRow("Est. Delivery",
                                formatDate(order['estimated_delivery'])),
                          if (order['delivery_address'] != null)
                            _buildInfoRow(
                                "Delivery Address", order['delivery_address']),
                          _buildInfoRow("Total Amount", formattedTotal),
                          _buildInfoRow("Payment Method",
                              order['payment_method'] ?? "Not specified"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Buyer info
                    if (buyer != null) ...[
                      Text(
                        "Buyer",
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
                                (buyer['first_name'] ?? 'B')[0].toUpperCase(),
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
                                    "${buyer['first_name'] ?? ''} ${buyer['last_name'] ?? ''}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (buyer['email'] != null)
                                    Text(
                                      buyer['email'],
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  if (buyer['phone'] != null)
                                    Text(
                                      buyer['phone'],
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
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

                    // Action buttons (bottom)
                    if (isPending || isProcessing)
                      Wrap(
                        spacing: 8,
                        children: [
                          if (isPending && onApprove != null)
                            ElevatedButton.icon(
                              onPressed: onApprove,
                              icon: const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                              ),
                              label: const Text("Approve Order"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF008080),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(160, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                              ),
                            ),
                          if (isPending && onCancel != null)
                            ElevatedButton.icon(
                              onPressed: onCancel,
                              icon: const Icon(
                                Icons.cancel_outlined,
                                color: Colors.white,
                              ),
                              label: const Text("Cancel Order"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(160, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                              ),
                            ),
                          if (isProcessing && onShip != null)
                            ElevatedButton.icon(
                              onPressed: onShip,
                              icon: const Icon(
                                Icons.local_shipping_outlined,
                                color: Colors.white,
                              ),
                              label: const Text("Mark as Shipped"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF008080),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(160, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProductDetailsCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Select primary image or first image
    final images = product['images'] as List<dynamic>?;
    final primaryImage = images?.firstWhere(
      (image) => image['is_primary'] == true,
      orElse: () => images?.isNotEmpty == true ? images![0] : null,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 80,
              height: 80,
              child: primaryImage != null && primaryImage['image_path'] != null
                  ? CachedNetworkImage(
                      imageUrl: primaryImage['image_path'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF008080)),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: primaryColor.withOpacity(0.1),
                        child: Center(
                          child: Icon(
                            Icons.shopping_bag,
                            color: primaryColor,
                            size: 40,
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
                          size: 40,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['product_name'] ?? 'Unnamed Product',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (product['category'] != null)
                  Text(
                    product['category'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Qty: $quantity",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "${product['price'] ?? '0.00'} DA",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
