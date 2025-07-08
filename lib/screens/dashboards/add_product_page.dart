import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddProductPage extends StatefulWidget {
  final int storeId;
  final String productType;

  AddProductPage({
    required this.storeId,
    required this.productType,
  });

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  int _currentStep = 0;
  final _formKeys = List.generate(5, (_) => GlobalKey<FormState>());

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _inventoryPriceController =
      TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _customCategoryController =
      TextEditingController();

  // Category dropdown variables
  String? _selectedCategory;
  bool _showCustomCategory = false;

  final List<String> categories = [
    "Medical Equipment",
    "Pharmaceuticals",
    "Personal Protective Equipment",
    "Home Healthcare Devices",
    "Health & Wellness",
    "First Aid Supplies",
    "Other (Custom)"
  ];

  List<XFile> _selectedImages = [];
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  Future<void> _pickImages() async {
    final List<XFile>? pickedImages = await ImagePicker().pickMultiImage();
    if (pickedImages != null && pickedImages.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedImages);
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _selectedImages.add(photo);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    bool isPassword = false,
    bool isConfirmPassword = false,
    bool isPhoneNumber = false,
    bool isEmail = false,
    bool isName = false,
    bool isNumeric = false,
    int maxLines = 1,
  }) {
    return Theme(
      data: ThemeData(
        primaryColor: Colors.grey,
        hintColor: Colors.grey,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: isPhoneNumber || isNumeric
            ? TextInputType.number
            : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFF008080), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFF008080), width: 2),
          ),
          suffixIcon: isPassword || isConfirmPassword
              ? IconButton(
                  icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() {
                    if (isPassword) {
                      _passwordVisible = !_passwordVisible;
                    } else {
                      _confirmPasswordVisible = !_confirmPasswordVisible;
                    }
                  }),
                )
              : null,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return "$label is required";
          if (isName && !RegExp(r"^[a-zA-Z\s-]+$").hasMatch(value))
            return "Only letters, spaces, and hyphens are allowed";
          if (isPhoneNumber && !RegExp(r'^\d+$').hasMatch(value))
            return "Enter a valid phone number";
          if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
            return "Enter a valid email";
          if (isNumeric && double.tryParse(value) == null)
            return "$label must be a number";
          return null;
        },
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF008080), width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              hint: Text(
                "Select Category",
                style: TextStyle(color: Colors.grey),
              ),
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: Color(0xFF008080)),
              items: categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(
                    category,
                    style: TextStyle(
                      color: category == "Other (Custom)"
                          ? Color(0xFF008080)
                          : Colors.black,
                      fontWeight: category == "Other (Custom)"
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                  _showCustomCategory = newValue == "Other (Custom)";

                  if (newValue != "Other (Custom)") {
                    _categoryController.text = newValue ?? '';
                    _customCategoryController.clear();
                  } else {
                    _categoryController.clear();
                  }
                });
              },
            ),
          ),
        ),

        // Custom category input field
        if (_showCustomCategory) ...[
          SizedBox(height: 12),
          _buildTextField(
            _customCategoryController,
            "Enter Custom Category",
          ),
        ],
      ],
    );
  }

  List<Widget> getStepWidgets() => [
        // Step 1: Product Name
        Form(
          key: _formKeys[0],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Product Name",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Enter a clear and recognizable name for your product."),
              SizedBox(height: 15),
              _buildTextField(_nameController, "Product Name", isName: true),
            ],
          ),
        ),

        // Step 2: Description
        Form(
          key: _formKeys[1],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Description",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text(
                  "Provide helpful details about the product, including specs and usage."),
              SizedBox(height: 15),
              _buildTextField(_descriptionController, 'Description',
                  maxLines: 5),
            ],
          ),
        ),

        // Step 3: Price & Stock
        Form(
          key: _formKeys[2],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Price & Stock",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Set a price and indicate how many units are available."),
              SizedBox(height: 15),
              _buildTextField(_priceController, "Price", isNumeric: true),
              if (widget.productType == 'inventory') ...[
                SizedBox(height: 10),
                _buildTextField(_inventoryPriceController, "Inventory Price",
                    isNumeric: true),
              ],
              SizedBox(height: 10),
              _buildTextField(_stockController, "Stock Quantity",
                  isNumeric: true),
            ],
          ),
        ),

        // Step 4: Category
        Form(
          key: _formKeys[3],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Category",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Group your product into a relevant category."),
              SizedBox(height: 15),
              _buildCategoryDropdown(),
            ],
          ),
        ),

        // Step 5: Product Images
        Form(
          key: _formKeys[4],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Product Images",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text(
                  "Add clear photos to help users better understand the product. The first image will be set as the primary image."),
              SizedBox(height: 15),

              // Image selection buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: Icon(Icons.photo_library),
                      label: Text("Select images"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF008080),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: Icon(Icons.camera_alt),
                      label: Text("Take photo"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF008080),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 15),

              // Display selected images with remove option
              if (_selectedImages.isEmpty)
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF00C6A2), width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined,
                          color: Color(0xFF00C6A2), size: 40),
                      SizedBox(height: 8),
                      Text("No images selected",
                          style: TextStyle(
                              color: Color(0xFF00C6A2),
                              fontSize: 16,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Selected Images (${_selectedImages.length})",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 150,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: EdgeInsets.only(right: 10),
                                  width: 150,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: index == 0
                                          ? Colors.amber
                                          : Color(0xFF00C6A2),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_selectedImages[index].path),
                                      fit: BoxFit.cover,
                                      width: 150,
                                      height: 150,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 5,
                                  right: 15,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.close,
                                          size: 18, color: Colors.red),
                                    ),
                                  ),
                                ),
                                if (index == 0)
                                  Positioned(
                                    bottom: 5,
                                    left: 5,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        "Primary",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ];

  void _nextStep() {
    if (_formKeys[_currentStep].currentState!.validate()) {
      // Additional validation for category step
      if (_currentStep == 3) {
        if (_selectedCategory == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select a category')),
          );
          return;
        }

        if (_showCustomCategory &&
            _customCategoryController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please enter a custom category')),
          );
          return;
        }

        // Set the final category value
        if (_showCustomCategory) {
          _categoryController.text = _customCategoryController.text.trim();
        }
      }

      // Additional validation for the final step
      if (_currentStep == getStepWidgets().length - 1 &&
          _selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select at least one product image')),
        );
        return;
      }

      // Validate inventory price is provided when needed
      if (_currentStep == 2 &&
          widget.productType == 'inventory' &&
          (_inventoryPriceController.text.isEmpty ||
              double.tryParse(_inventoryPriceController.text) == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Inventory price is required for inventory products')),
        );
        return;
      }

      if (_currentStep < getStepWidgets().length - 1) {
        setState(() => _currentStep += 1);
      } else {
        _submitProduct();
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  Future<void> _submitProduct() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one product image')),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final uri = Uri.parse('http://192.168.43.101:8000/api/product');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json'
      ..fields['store_id'] = widget.storeId.toString()
      ..fields['product_name'] = _nameController.text
      ..fields['description'] = _descriptionController.text
      ..fields['price'] = _priceController.text
      ..fields['stock'] = _stockController.text
      ..fields['category'] = _categoryController.text
      ..fields['type'] = widget.productType;

    // Add inventory_price if it's an inventory product
    if (widget.productType == 'inventory' &&
        _inventoryPriceController.text.isNotEmpty) {
      request.fields['inventory_price'] = _inventoryPriceController.text;
    }

    // Add multiple images to the request
    for (int i = 0; i < _selectedImages.length; i++) {
      final file = await http.MultipartFile.fromPath(
        'images[]',
        _selectedImages[i].path,
      );
      request.files.add(file);
    }

    print("Request to add product: ${request.fields}");
    print("Uploading ${_selectedImages.length} images");

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product added successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product: ${response.body}')),
        );
      }
    } catch (e) {
      print("Error occurred while adding product: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred: $e')),
      );
    }
  }

  Widget _buildProgressBar() {
    final progress = (_currentStep + 1) / getStepWidgets().length;
    return LinearProgressIndicator(
      value: progress,
      color: Color(0xFF008080),
      backgroundColor: Colors.grey[300],
      minHeight: 4,
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = getStepWidgets();

    String pageTitle = widget.productType == 'new'
        ? "Add Store Product"
        : "Add Inventory Product";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _prevStep,
              )
            : IconButton(
                icon: Icon(Icons.close, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          pageTitle,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: _buildProgressBar(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(child: SingleChildScrollView(child: steps[_currentStep])),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF008080)),
                child: Text(
                  _currentStep == steps.length - 1 ? 'Submit' : 'Next',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
