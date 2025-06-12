import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CartManager {
  static const String _cartKey = 'cart_items';

  // Add or update item in cart
  static Future<void> addToCart(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> cartItems = await getCartItems();

    // Check if product already exists in cart
    int existingIndex = cartItems.indexWhere((cartItem) => cartItem['product_id'] == item['product_id']);
    if (existingIndex != -1) {
      // Update quantity if product exists
      cartItems[existingIndex]['quantity'] = (cartItems[existingIndex]['quantity'] as int) + (item['quantity'] as int);
    } else {
      // Add new item
      cartItems.add(item);
    }

    // Save updated cart
    await prefs.setString(_cartKey, jsonEncode(cartItems));
  }

  // Get all cart items
  static Future<List<Map<String, dynamic>>> getCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    String? cartData = prefs.getString(_cartKey);
    if (cartData != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cartData);
        return decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  // Get cart item count
  static Future<int> getCartItemCount() async {
    final cartItems = await getCartItems();
    int totalCount = 0;
    for (var item in cartItems) {
      totalCount += (item['quantity'] as int);
    }
    return totalCount;
  }

  // Alternative using fold with explicit type
  static Future<int> getCartItemCountAlternative() async {
    final cartItems = await getCartItems();
    return cartItems.fold<int>(0, (int sum, item) => sum + (item['quantity'] as int));
  }

  // Clear cart
  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }
}