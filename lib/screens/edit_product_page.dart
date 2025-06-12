import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProductPage extends StatefulWidget {
  final dynamic product;

  EditProductPage({required this.product});

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  TextEditingController _nameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  TextEditingController _stockController = TextEditingController();
  TextEditingController _categoryController = TextEditingController();
  TextEditingController _inventoryPriceController = TextEditingController();

  List<File> _newImageFiles = [];
  List<dynamic> _existingImages = [];
  List<int> _imagesToDelete = [];
  int? _primaryImageId;
  bool _isLoading = false;
  String _productType = 'new';
  String _condition = 'excellent'; // Default condition for used equipment
  int? _storeId;

  final Color primaryColor = Color(0xFF008080);

  // Product type options
  final List<Map<String, dynamic>> _productTypes = [
    {
      'value': 'new',
      'label': 'New Product',
      'icon': Icons.new_releases,
      'color': Colors.blue[700],
    },
    {
      'value': 'inventory',
      'label': 'Inventory Product',
      'icon': Icons.inventory_2,
      'color': Colors.amber[700],
    },
    {
      'value': 'used_equipment',
      'label': 'Used Equipment',
      'icon': Icons.build,
      'color': Colors.orange[700],
    },
  ];

  // Condition options for used equipment
  final List<String> _conditionOptions = [
    'excellent',
    'very_good',
    'good',
    'fair',
    'poor',
  ];

  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  void _loadProductData() {
    dynamic product = widget.product;

    _storeId = product['store_id'];
    _nameController.text = product['product_name'] ?? '';
    _descriptionController.text = product['description'] ?? '';
    _priceController.text = product['price']?.toString() ?? '0';
    _stockController.text = product['stock']?.toString() ?? '0';
    _categoryController.text = product['category'] ?? '';
    _inventoryPriceController.text =
        product['inventory_price']?.toString() ?? '';
    _productType = product['type'] ?? 'new';
    _condition = product['condition'] ?? 'excellent';
    _existingImages = List.from(product['images'] ?? []);
    _primaryImageId = _existingImages.firstWhere(
      (image) => image['is_primary'] == true,
      orElse: () => null,
    )?['id'];
  }

  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage(
      imageQuality: 80,
    );

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _newImageFiles.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImageFiles.removeAt(index);
    });
  }

  void _markExistingImageForDeletion(int imageId) {
    setState(() {
      _imagesToDelete.add(imageId);
      _existingImages.removeWhere((image) => image['id'] == imageId);
      if (_primaryImageId == imageId) {
        _primaryImageId =
            _existingImages.isNotEmpty ? _existingImages[0]['id'] : null;
      }
    });
  }

  void _setPrimaryImage(int imageId) {
    setState(() {
      _primaryImageId = imageId;
    });
  }

  String _getConditionDisplayName(String condition) {
    switch (condition) {
      case 'excellent':
        return 'Excellent';
      case 'very_good':
        return 'Very Good';
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      case 'poor':
        return 'Poor';
      default:
        return condition;
    }
  }

  Color _getConditionColor(String condition) {
    switch (condition) {
      case 'excellent':
        return Colors.green[700]!;
      case 'very_good':
        return Colors.lightGreen[700]!;
      case 'good':
        return Colors.yellow[700]!;
      case 'fair':
        return Colors.orange[700]!;
      case 'poor':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      Uri url = Uri.parse(
          'http://192.168.1.8:8000/api/product/${widget.product['product_id']}');

      var request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['_method'] = 'PUT';
      request.fields['store_id'] = _storeId.toString();
      request.fields['product_name'] = _nameController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['price'] = _priceController.text;
      request.fields['stock'] = _stockController.text;
      request.fields['category'] = _categoryController.text;
      // Removed: request.fields['type'] = _productType;

      if (_productType == 'inventory') {
        request.fields['inventory_price'] = _inventoryPriceController.text;
      }

      if (_productType == 'used_equipment') {
        request.fields['condition'] = _condition;
      }

      if (_primaryImageId != null) {
        request.fields['primary_image_id'] = _primaryImageId.toString();
      }

      // Send delete_images as individual array elements
      for (int i = 0; i < _imagesToDelete.length; i++) {
        request.fields['delete_images[$i]'] = _imagesToDelete[i].toString();
      }

      // Add new images
      for (var image in _newImageFiles) {
        request.files
            .add(await http.MultipartFile.fromPath('images[]', image.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('Failed: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed: ${jsonDecode(response.body)['message'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Edit Product',
          style: TextStyle(color: Colors.black87),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              icon: Icon(Icons.save, color: primaryColor),
              label: Text(
                'Save',
                style:
                    TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
              ),
              onPressed: _updateProduct,
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Section
                    Text(
                      'Product Images',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Existing Images
                        ..._existingImages.map((image) => _buildImageTile(
                              isNetwork: true,
                              imageUrl: image['image_path'],
                              imageId: image['id'],
                              isPrimary: image['id'] == _primaryImageId,
                            )),
                        // New Images
                        ..._newImageFiles
                            .asMap()
                            .entries
                            .map((entry) => _buildImageTile(
                                  isNetwork: false,
                                  file: entry.value,
                                  index: entry.key,
                                )),
                        // Add Image Button
                        GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 30,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Add Image',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Product Type Display (Read-only)
                    Text(
                      'Product Type',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _productTypes
                            .firstWhere((type) =>
                                type['value'] == _productType)['color']
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _productTypes.firstWhere(
                              (type) => type['value'] == _productType)['color'],
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _productTypes.firstWhere((type) =>
                                type['value'] == _productType)['icon'],
                            color: _productTypes.firstWhere((type) =>
                                type['value'] == _productType)['color'],
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            _productTypes.firstWhere((type) =>
                                type['value'] == _productType)['label'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _productTypes.firstWhere((type) =>
                                  type['value'] == _productType)['color'],
                              fontSize: 16,
                            ),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Read Only',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Product Name
                    _buildTextField(
                      controller: _nameController,
                      label: 'Product Name',
                      hint: 'Enter product name',
                      icon: Icons.shopping_bag_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Description
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description (Optional)',
                      hint: 'Enter product description',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),

                    // Price
                    _buildTextField(
                      controller: _priceController,
                      label: 'Price (DA)',
                      hint: 'Enter product price',
                      icon: Icons.price_change_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Inventory Price (for inventory products)
                    if (_productType == 'inventory')
                      Column(
                        children: [
                          _buildTextField(
                            controller: _inventoryPriceController,
                            label: 'Inventory Price (DA)',
                            hint: 'Enter inventory price',
                            icon: Icons.price_change_outlined,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter inventory price';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid price';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                        ],
                      ),

                    // Condition (for used equipment)
                    if (_productType == 'used_equipment')
                      Column(
                        children: [
                          _buildConditionField(),
                          SizedBox(height: 16),
                        ],
                      ),

                    // Stock
                    _buildTextField(
                      controller: _stockController,
                      label: 'Stock Quantity',
                      hint: 'Enter stock quantity',
                      icon: Icons.inventory_2_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter stock quantity';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Category
                    _buildTextField(
                      controller: _categoryController,
                      label: 'Category',
                      hint: 'Enter product category',
                      icon: Icons.category_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product category';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isLoading ? null : _updateProduct,
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Update Product',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
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

  Widget _buildConditionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Equipment Condition',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<String>(
            value: _condition,
            decoration: InputDecoration(
              prefixIcon:
                  Icon(Icons.star_rate, color: _getConditionColor(_condition)),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: _conditionOptions.map((condition) {
              return DropdownMenuItem<String>(
                value: condition,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getConditionColor(condition),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(_getConditionDisplayName(condition)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _condition = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageTile({
    required bool isNetwork,
    String? imageUrl,
    File? file,
    int? imageId,
    int? index,
    bool isPrimary = false,
  }) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
            border:
                isPrimary ? Border.all(color: primaryColor, width: 2) : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: isNetwork
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    ),
                    errorWidget: (_, __, ___) => Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey[400],
                    ),
                  )
                : Image.file(
                    file!,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        // Delete Button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              if (isNetwork && imageId != null) {
                _markExistingImageForDeletion(imageId);
              } else if (index != null) {
                _removeNewImage(index);
              }
            },
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // Primary Image Indicator
        if (isNetwork && imageId != null)
          Positioned(
            bottom: 4,
            left: 4,
            child: GestureDetector(
              onTap: () => _setPrimaryImage(imageId),
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isPrimary ? primaryColor : Colors.grey[600],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: primaryColor),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.red),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
