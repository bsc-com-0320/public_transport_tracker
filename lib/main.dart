import 'package:flutter/material.dart';
import 'Homepage.dart';
import 'LoginPage.dart';
import 'SignUpPage.dart';
import 'BookPage.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Public_transport_tracker',
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      initialRoute: '/login',
      routes: {
        '/': (context) => HomePage(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
       '/book': (context) => BookPage(),
        
      },
    );
  }
}
