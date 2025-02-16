import 'package:flutter/material.dart';
import 'welcome_screen.dart'; // Import the welcome screen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.purple),
      home: WelcomeScreen(), // Start with Welcome Screen
    );
  }
}
