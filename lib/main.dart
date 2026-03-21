import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/Login_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Community App",
      theme: ThemeData(
        primaryColor: Color(0xFF0F8F82),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: LoginPage(),
    );
  }
}
