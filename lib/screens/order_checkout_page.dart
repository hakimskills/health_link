import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_link/screens/dashboards/healthcare_dashboard.dart';

class OrderCheckoutPage extends StatefulWidget {
  final dynamic product;
  final int quantity;
  final List<Map<String, dynamic>>? cartItems;

  const OrderCheckoutPage({
    Key? key,
    this.product,
    this.quantity = 1,
    this.cartItems,
  }) : super(key: key);

  @override
  _OrderCheckoutPageState createState() => _OrderCheckoutPageState();
}

class _OrderCheckoutPageState extends State<OrderCheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _deliveryAddress = '';
  DateTime? _estimatedDelivery;
  String _userId = '';
  List<Map<String, dynamic>> _items = [];

  TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _prepareItems();
  }

  void _prepareItems() {
    if (widget.cartItems != null) {
      // If cart items are provided, use them
      _items = widget.cartItems!;
    } else if (widget.product != null) {
      // If single product is provided, create an item for it
      _items = [
        {
          'product_id': widget.product['product_id'],
          'quantity': widget.quantity,
          'product_name': widget.product['product_name'],
          'price': widget.product['type'] == 'inventory'
              ? widget.product['inventory_price']
              : widget.product['price'],
          'image': widget.product['image'],
        }
      ];
    }
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id') ?? '';
      // Pre-fill with saved address if available
      String savedAddress = prefs.getString('delivery_address') ?? '';
      _deliveryAddress = savedAddress;
      _addressController.text = savedAddress;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 3)),
      firstDate: DateTime.now().add(Duration(days: 1)),
      lastDate: DateTime.now().add(Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFF008080),
            colorScheme: ColorScheme.light(primary: Color(0xFF008080)),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _estimatedDelivery) {
      setState(() {
        _estimatedDelivery = picked;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to place an order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _formKey.currentState!.save();
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    // Save the delivery address for future use
    prefs.setString('delivery_address', _deliveryAddress);

    try {
      final url = Uri.parse('http://192.168.43.101:8000/api/product-orders');

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'buyer_id': _userId, // ✅ updated key
        'delivery_address': _deliveryAddress,
        'items': _items.map((item) => {
          'product_id': item['product_id'],
          'quantity': item['quantity'],
        }).toList(),
      };

      if (_estimatedDelivery != null) {
        requestBody['estimated_delivery'] = _estimatedDelivery!.toIso8601String();
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 201) {
        final order = json.decode(response.body);
        _showOrderSuccessDialog(order['order']);
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: ${error['message']}'),
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


  void _showOrderSuccessDialog(dynamic order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              Icon(
                Icons.check_circle,
                color: Color(0xFF008080),
                size: 60,
              ),
              SizedBox(height: 16),
              Text(
                'Order Placed Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF008080),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your order has been placed and will be processed soon.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Order Date: ${DateTime.parse(order['order_date']).toString().substring(0, 16)}',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                'View Orders',
                style: TextStyle(color: Color(0xFF008080)),
              ),
              onPressed: () {
                // Navigate to orders page (you'll need to implement this)
                Navigator.of(context).pop();
                // TODO: Navigate to orders page
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF008080),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Continue Shopping',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => HealthcareDashboard()),
                      (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double total = _items.fold(0.0, (sum, item) {
      double price = double.tryParse(item['price'].toString().replaceAll('DA', '').trim()) ?? 0.0;
      return sum + (price * item['quantity']);
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Checkout',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF008080)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008080)),
        ),
      )
          : Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Order summary card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16),
                    // List of items
                    ...List.generate(
                      _items.length,
                          (index) => Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _items[index]['image'] != null
                                  ? Image.network(
                                _items[index]['image'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image_not_supported, color: Colors.grey),
                                ),
                              )
                                  : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[200],
                                child: Icon(Icons.image_not_supported, color: Colors.grey),
                              ),
                            ),
                            SizedBox(width: 12),
                            // Product details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _items[index]['product_name'] ?? 'Product',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Quantity: ${_items[index]['quantity']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Price
                            Text(
                              '${_items[index]['price'] ?? '0.00DA'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF008080),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(thickness: 1),
                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${total.toStringAsFixed(2)}DA',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF008080),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Delivery information
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16),
                    // Delivery address
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Delivery Address',
                        hintText: 'Enter your full delivery address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFF008080), width: 2),
                        ),
                        prefixIcon: Icon(Icons.location_on_outlined, color: Color(0xFF008080)),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter delivery address';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _deliveryAddress = value!;
                      },
                    ),
                    SizedBox(height: 16),
                    // Preferred delivery date
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Preferred Delivery Date (Optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF008080)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _estimatedDelivery != null
                                  ? '${_estimatedDelivery!.day}/${_estimatedDelivery!.month}/${_estimatedDelivery!.year}'
                                  : 'Select a date',
                              style: TextStyle(
                                color: _estimatedDelivery != null
                                    ? Colors.black87
                                    : Colors.grey[600],
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: Color(0xFF008080)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 32),

            // Payment options (simplified for now)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16),
                    // Cash on delivery option
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          Icon(Icons.money, color: Color(0xFF008080)),
                          SizedBox(width: 12),
                          Text('Cash on Delivery'),
                        ],
                      ),
                      value: 'cash',
                      groupValue: 'cash', // Hardcoded for now
                      onChanged: (value) {
                        // Only cash on delivery is supported currently
                      },
                      activeColor: Color(0xFF008080),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF008080),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              _isLoading ? 'Processing...' : 'Place Order',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}