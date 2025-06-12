import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddUsedEquipmentPage extends StatefulWidget {
  final int storeId;

  AddUsedEquipmentPage({
    required this.storeId,
  });

  @override
  _AddUsedEquipmentPageState createState() => _AddUsedEquipmentPageState();
}

class _AddUsedEquipmentPageState extends State<AddUsedEquipmentPage> {
  int _currentStep = 0;
  final _formKeys = List.generate(6, (_) => GlobalKey<FormState>());

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _inventoryPriceController =
      TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _customCategoryController =
      TextEditingController();

  List<XFile> _selectedImages = [];
  String? _selectedCondition;
  String? _selectedCategory;
  bool _isCustomCategory = false;

  // Predefined categories
  final List<String> _categories = [
    "Medical Equipment",
    "Medications",
    "Dental Supplies",
    "Lab Supplies",
    "Health & Wellness",
    "First Aid & Emergency",
    "Protective Gear",
    "Personal Care",
    "Other (Custom)"
  ];

  // Condition options for used equipment
  final List<Map<String, dynamic>> _conditionOptions = [
    {
      'value': 'excellent',
      'label': 'Excellent',
      'description': 'Like new, minimal wear',
      'icon': Icons.star,
      'color': Colors.green,
    },
    {
      'value': 'good',
      'label': 'Good',
      'description': 'Minor wear, fully functional',
      'icon': Icons.thumb_up,
      'color': Colors.blue,
    },
    {
      'value': 'fair',
      'label': 'Fair',
      'description': 'Noticeable wear, good working condition',
      'icon': Icons.check_circle_outline,
      'color': Colors.orange,
    },
    {
      'value': 'poor',
      'label': 'Poor',
      'description': 'Heavy wear, may need repairs',
      'icon': Icons.warning_outlined,
      'color': Colors.red,
    },
  ];

  // Method to pick multiple images
  Future<void> _pickImages() async {
    final List<XFile>? pickedImages = await ImagePicker().pickMultiImage();
    if (pickedImages != null && pickedImages.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedImages);
      });
    }
  }

  // Method to take a photo with camera
  Future<void> _takePhoto() async {
    final XFile? photo =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _selectedImages.add(photo);
      });
    }
  }

  // Method to remove an image from the selection
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    bool isPhoneNumber = false,
    bool isEmail = false,
    bool isName = false,
    bool isNumeric = false,
    int maxLines = 1,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: isPhoneNumber || isNumeric
              ? TextInputType.number
              : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            helperText: helperText,
            labelStyle: TextStyle(color: Colors.grey[600]),
            helperStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF008080), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF008080), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return "$label is required";
            if (isName && !RegExp(r"^[a-zA-Z0-9\s\-\.]+$").hasMatch(value))
              return "Only letters, numbers, spaces, hyphens, and periods are allowed";
            if (isPhoneNumber && !RegExp(r'^\d+$').hasMatch(value))
              return "Enter a valid phone number";
            if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
              return "Enter a valid email";
            if (isNumeric && double.tryParse(value) == null)
              return "$label must be a number";
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Equipment Category",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Select the most appropriate category or choose 'Other' to add a custom category",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF008080), width: 1.5),
            color: Colors.grey[50],
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: "Select Category",
              labelStyle: TextStyle(color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            dropdownColor: Colors.white,
            icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF008080)),
            items: _categories.map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Row(
                  children: [
                    Icon(
                      category == "Other (Custom)"
                          ? Icons.edit
                          : Icons.category_outlined,
                      color: Color(0xFF008080),
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedCategory = newValue;
                _isCustomCategory = newValue == "Other (Custom)";
                if (!_isCustomCategory) {
                  _customCategoryController.clear();
                }
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please select a category";
              }
              return null;
            },
          ),
        ),

        // Custom category text field (shown when "Other" is selected)
        if (_isCustomCategory) ...[
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF008080).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF008080).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    color: Color(0xFF008080), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Enter your custom category name below",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _customCategoryController,
            decoration: InputDecoration(
              labelText: "Custom Category Name",
              hintText: "e.g., Surgical Instruments, Rehabilitation Equipment",
              labelStyle: TextStyle(color: Colors.grey[600]),
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF008080), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF008080), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.edit, color: Color(0xFF008080)),
            ),
            validator: (value) {
              if (_isCustomCategory && (value == null || value.isEmpty)) {
                return "Please enter a custom category name";
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildConditionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Equipment Condition",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Select the current condition of the equipment",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 16),
        Column(
          children: _conditionOptions.map((condition) {
            final isSelected = _selectedCondition == condition['value'];
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedCondition = condition['value'];
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isSelected ? condition['color'] : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? condition['color'].withOpacity(0.1)
                        : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        condition['icon'],
                        color:
                            isSelected ? condition['color'] : Colors.grey[600],
                        size: 24,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              condition['label'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? condition['color']
                                    : Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              condition['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: condition['color'],
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<Widget> getStepWidgets() => [
        // Step 1: Equipment Name
        Form(
          key: _formKeys[0],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.build_outlined,
                      color: Color(0xFF008080), size: 28),
                  SizedBox(width: 12),
                  Text("Equipment Name",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF008080).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF008080).withOpacity(0.3)),
                ),
                child: Text(
                  "Enter a clear and descriptive name for your used equipment. Include the brand, model, and key specifications if applicable.",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              SizedBox(height: 20),
              _buildTextField(
                _nameController,
                "Equipment Name",
                isName: true,
                helperText: "e.g., Canon EOS 5D Mark IV Camera Body",
              ),
            ],
          ),
        ),

        // Step 2: Description
        Form(
          key: _formKeys[1],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description_outlined,
                      color: Color(0xFF008080), size: 28),
                  SizedBox(width: 12),
                  Text("Description",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF008080).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF008080).withOpacity(0.3)),
                ),
                child: Text(
                  "Provide detailed information about the equipment's features, specifications, accessories included, and any notable history.",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              SizedBox(height: 20),
              _buildTextField(
                _descriptionController,
                "Equipment Description",
                maxLines: 6,
                helperText:
                    "Include specifications, accessories, usage history, etc.",
              ),
            ],
          ),
        ),

        // Step 3: Condition Assessment
        Form(
          key: _formKeys[2],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.assessment_outlined,
                      color: Color(0xFF008080), size: 28),
                  SizedBox(width: 12),
                  Text("Condition",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF008080).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF008080).withOpacity(0.3)),
                ),
                child: Text(
                  "Honestly assess the current condition of your equipment. This helps buyers make informed decisions.",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              SizedBox(height: 20),
              _buildConditionSelector(),
            ],
          ),
        ),

        // Step 4: Pricing
        Form(
          key: _formKeys[3],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.attach_money_outlined,
                      color: Color(0xFF008080), size: 28),
                  SizedBox(width: 12),
                  Text("Pricing & Stock",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF008080).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF008080).withOpacity(0.3)),
                ),
                child: Text(
                  "Set competitive prices based on the equipment's condition and market value. Include inventory cost if applicable.",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              SizedBox(height: 20),
              _buildTextField(
                _priceController,
                "Selling Price",
                isNumeric: true,
                helperText: "Price customers will pay",
              ),
              SizedBox(height: 16),
              _buildTextField(
                _inventoryPriceController,
                "Inventory Price (Optional)",
                isNumeric: true,
                helperText: "Your cost/purchase price for tracking",
              ),
              SizedBox(height: 16),
              _buildTextField(
                _stockController,
                "Quantity Available",
                isNumeric: true,
                helperText: "Number of units available",
              ),
            ],
          ),
        ),

        // Step 5: Category (Updated with dropdown)
        Form(
          key: _formKeys[4],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.category_outlined,
                      color: Color(0xFF008080), size: 28),
                  SizedBox(width: 12),
                  Text("Category",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF008080).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF008080).withOpacity(0.3)),
                ),
                child: Text(
                  "Choose the most appropriate category to help customers find your equipment easily.",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              SizedBox(height: 20),
              _buildCategoryDropdown(),
            ],
          ),
        ),

        // Step 6: Equipment Images
        Form(
          key: _formKeys[5],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.photo_camera_outlined,
                      color: Color(0xFF008080), size: 28),
                  SizedBox(width: 12),
                  Text("Equipment Photos",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF008080).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF008080).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "📸 Photo Tips for Used Equipment:",
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "• Take multiple angles including front, back, and sides\n• Show any wear, scratches, or imperfections clearly\n• Include photos of accessories and original packaging\n• Use good lighting and clear focus\n• The first image will be the main display photo",
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Image selection buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: Icon(Icons.photo_library, color: Colors.white),
                      label: Text("Select Photos",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF008080),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: Icon(Icons.camera_alt, color: Colors.white),
                      label: Text("Take Photo",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF008080),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Display selected images
              if (_selectedImages.isEmpty)
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Color(0xFF008080),
                        width: 2,
                        style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                    color: Color(0xFF008080).withOpacity(0.05),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined,
                          color: Color(0xFF008080), size: 48),
                      SizedBox(height: 12),
                      Text(
                        "No photos selected",
                        style: TextStyle(
                          color: Color(0xFF008080),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Add photos to showcase your equipment",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.photo_library,
                            color: Color(0xFF008080), size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Selected Photos (${_selectedImages.length})",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Container(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                margin: EdgeInsets.only(right: 12),
                                width: 160,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: index == 0
                                        ? Colors.amber
                                        : Color(0xFF008080),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(_selectedImages[index].path),
                                    fit: BoxFit.cover,
                                    width: 160,
                                    height: 160,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 20,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(Icons.close,
                                        size: 16, color: Colors.red),
                                  ),
                                ),
                              ),
                              if (index == 0)
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
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
            ],
          ),
        ),
      ];

  void _nextStep() {
    // Custom validation for condition step
    if (_currentStep == 2 && _selectedCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select the equipment condition'),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }

    // Custom validation for category step
    if (_currentStep == 4) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a category'),
            backgroundColor: Colors.red[400],
          ),
        );
        return;
      }
      if (_isCustomCategory && _customCategoryController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a custom category name'),
            backgroundColor: Colors.red[400],
          ),
        );
        return;
      }
    }

    if (_formKeys[_currentStep].currentState!.validate()) {
      // Final step validation
      if (_currentStep == getStepWidgets().length - 1 &&
          _selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please add at least one photo of the equipment'),
            backgroundColor: Colors.red[400],
          ),
        );
        return;
      }

      if (_currentStep < getStepWidgets().length - 1) {
        setState(() => _currentStep += 1);
      } else {
        _submitUsedEquipment();
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  Future<void> _submitUsedEquipment() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add at least one photo of the equipment'),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }

    if (_selectedCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select the equipment condition'),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF008080)),
                SizedBox(height: 16),
                Text("Adding used equipment...",
                    style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        );
      },
    );

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final category =
        _isCustomCategory ? _customCategoryController.text : _selectedCategory!;

    // Log the category for debugging

    final uri = Uri.parse('http://192.168.1.8:8000/api/product/used-equipment');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json'
      ..fields['store_id'] = widget.storeId.toString()
      ..fields['product_name'] = _nameController.text
      ..fields['description'] = _descriptionController.text
      ..fields['price'] = _priceController.text
      ..fields['stock'] = _stockController.text
      ..fields['category'] = category
      ..fields['condition'] = _selectedCondition!;

    // Add inventory_price if provided
    if (_inventoryPriceController.text.isNotEmpty) {
      request.fields['inventory_price'] = _inventoryPriceController.text;
    }

    // Add images to the request
    for (int i = 0; i < _selectedImages.length; i++) {
      final file = await http.MultipartFile.fromPath(
        'images[]',
        _selectedImages[i].path,
      );
      request.files.add(file);
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Used equipment added successfully!'),
            backgroundColor: Colors.green[400],
          ),
        );
        Navigator.pop(context, true);
      } else {
        // Log the response body for debugging

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add equipment: ${response.body}'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error occurred: $e'),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  Widget _buildProgressBar() {
    final progress = (_currentStep + 1) / getStepWidgets().length;
    return Container(
      height: 6,
      child: LinearProgressIndicator(
        value: progress,
        color: Color(0xFF008080),
        backgroundColor: Colors.grey[300],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = getStepWidgets();

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
        title: Column(
          children: [
            Text(
              "Add Used Equipment",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              "Step ${_currentStep + 1} of ${steps.length}",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(6),
          child: _buildProgressBar(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: steps[_currentStep],
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF008080),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentStep == steps.length - 1
                      ? 'Add Equipment'
                      : 'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _inventoryPriceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}
