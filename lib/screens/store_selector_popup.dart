import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:convert';

class StoreSelector {
  // Define colors to match your theme
  static const primaryColor = Color(0xFF00857C);
  static const secondaryColor = Color(0xFF232F34);
  static const backgroundColor = Color(0xFFF8FAFC);

  static Future<void> showStoreSelectionDialog({
    required BuildContext context,
    required Function(int storeId) onStoreSelected,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: StoreSelectionContent(
              onStoreSelected: (storeId) {
                Navigator.of(context).pop();
                onStoreSelected(storeId);
              },
            ),
          ),
        );
      },
    );
  }
}

class StoreSelectionContent extends StatefulWidget {
  final Function(int storeId) onStoreSelected;

  const StoreSelectionContent({
    Key? key,
    required this.onStoreSelected,
  }) : super(key: key);

  @override
  _StoreSelectionContentState createState() => _StoreSelectionContentState();
}

class _StoreSelectionContentState extends State<StoreSelectionContent> {
  List<dynamic> stores = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchStores();
  }

  Future<void> _fetchStores() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    int? userId = int.tryParse(prefs.getString('user_id') ?? '');

    if (token != null && userId != null) {
      try {
        final response = await http.get(
          Uri.parse('http://192.168.43.101:8000/api/stores/user/$userId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          if (mounted) {
            setState(() {
              stores = jsonDecode(response.body);
              isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              isLoading = false;
              hasError = true;
              errorMessage = 'Failed to load stores. Please try again.';
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            isLoading = false;
            hasError = true;
            errorMessage = 'Connection error. Please check your internet.';
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'Authentication error. Please login again.';
        });
      }
    }
  }

  Future<void> _refreshStores() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    await _fetchStores();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: StoreSelector.primaryColor.withOpacity(0.05),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.store_outlined,
                color: StoreSelector.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Select a Store',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: StoreSelector.secondaryColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close,
                  color: Colors.grey[600],
                ),
                splashRadius: 20,
              ),
            ],
          ),
        ),

        // Content
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return _buildLoadingShimmer();
    } else if (hasError) {
      return _buildErrorState();
    } else if (stores.isEmpty) {
      return _buildEmptyState();
    } else {
      return _buildStoresList();
    }
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SizedBox(
        height: 300,
        child: ListView.builder(
          itemCount: 3,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SizedBox(
      height: 250,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: StoreSelector.secondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: StoreSelector.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: _refreshStores,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No stores found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: StoreSelector.secondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any stores yet',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoresList() {
    return SizedBox(
      height: Math.min(400.0, stores.length * 90.0 + 20),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: stores.length,
        itemBuilder: (context, index) {
          final store = stores[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onStoreSelected(store['id']),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Store icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: StoreSelector.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.store_outlined,
                            color: StoreSelector.primaryColor,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Store info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store['store_name'] ?? 'Store',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: StoreSelector.secondaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              store['address'] ?? 'No address provided',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (store['phone'] != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                store['phone'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Arrow icon
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: StoreSelector.primaryColor,
                            size: 14,
                          ),
                        ),
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
}

// Helper class for Math.min since it might not be available
class Math {
  static double min(double a, double b) {
    return a < b ? a : b;
  }
}