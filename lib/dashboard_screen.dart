import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'offer_model.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Offer> offers = [];
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    fetchOffers();
  }

  Future<void> fetchOffers() async {
    try {
      final response = await http.get(Uri.parse("http://10.0.2.2:3000/api/offers"));

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          offers = jsonData.map((json) => Offer.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dashboard")),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading spinner
          : isError
          ? Center(child: Text("Failed to load offers."))
          : ListView.builder(
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              leading: offer.offerImage != null
                  ? Image.network(offer.offerImage!, width: 50, height: 50, fit: BoxFit.cover)
                  : Icon(Icons.image_not_supported),
              title: Text(offer.offerName, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${offer.offerDesc}\nPrice: \$${offer.offerPrice.toString()}"),
              trailing: Text("Qty: ${offer.offerQuantity}"),
            ),
          );
        },
      ),
    );
  }
}
