import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  int get itemCount => _items.length;

  double get totalAmount {
    return _items.fold(0.0, (sum, item) {
      double price = double.tryParse(item['price'].toString().replaceAll('DA', '').trim()) ?? 0.0;
      return sum + (price * item['quantity']);
    });
  }

  CartProvider() {
    _loadCartFromPrefs();
  }

  Future<void> _loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = prefs.getString('cart');

    if (cartData != null) {
      try {
        final List<dynamic> decodedData = json.decode(cartData);
        _items = List<Map<String, dynamic>>.from(decodedData);
        notifyListeners();
      } catch (e) {
        print("Error loading cart data: $e");
      }
    }
  }

  Future<void> _saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = json.encode(_items);
    await prefs.setString('cart', cartData);
  }

  void addItem(Map<String, dynamic> product, int quantity) {
    // Check if product already exists in cart
    int existingIndex = _items.indexWhere((item) => item['product_id'] == product['product_id']);

    if (existingIndex >= 0) {
      // Update existing item
      _items[existingIndex]['quantity'] += quantity;
    } else {
      // Add new item
      _items.add({
        'product_id': product['product_id'],
        'product_name': product['product_name'],
        'price': product['type'] == 'inventory' ? product['inventory_price'] : product['price'],
        'quantity': quantity,
        'image': product['image'],
        'type': product['type'],
      });
    }

    _saveCartToPrefs();
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item['product_id'] == productId);
    _saveCartToPrefs();
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item['product_id'] == productId);
    if (index >= 0) {
      _items[index]['quantity'] = quantity;
      _saveCartToPrefs();
      notifyListeners();
    }
  }

  void clear() {
    _items = [];
    _saveCartToPrefs();
    notifyListeners();
  }
}