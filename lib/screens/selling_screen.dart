import 'package:flutter/material.dart';

class SellingScreen extends StatefulWidget {
  @override
  _SellingScreenState createState() => _SellingScreenState();
}

class _SellingScreenState extends State<SellingScreen> {
  final List<Map<String, String>> _itemsForSale = [];

  void _addItem(String name, String description) {
    setState(() {
      _itemsForSale.add({'name': name, 'description': description});
    });
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add New Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Item Name'),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Item Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final name = nameController.text;
              final description = descriptionController.text;
              if (name.isNotEmpty && description.isNotEmpty) {
                _addItem(name, description);
                Navigator.of(ctx).pop();
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selling Items'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddItemDialog,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _itemsForSale.length,
        itemBuilder: (ctx, index) {
          final item = _itemsForSale[index];
          return ListTile(
            title: Text(item['name']!),
            subtitle: Text(item['description']!),
          );
        },
      ),
    );
  }
}
