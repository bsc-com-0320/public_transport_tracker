import 'package:flutter/material.dart';
import 'AccountPage.dart';
import 'Homepage.dart';
import 'LoginPage.dart';
import 'OrderPage.dart';
import 'SignUpPage.dart';
import 'CheckPage.dart';
import 'BookPage.dart';
import 'AccountsPage.dart';
import 'AddRidePage.dart'; // Import AddRidePage

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Public Transport Tracker',
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      initialRoute: '/login',
routes: {
  '/': (context) => HomePage(),
  '/login': (context) => LoginPage(),
  '/signup': (context) => SignUpPage(),
  '/order': (context) => OrderPage(),
  '/account': (context) => AccountPage(),
  '/check': (context) => CheckPage(),
  '/book': (context) => BookPage(),
  '/accounts': (context) => AccountsPage(),
  '/rides': (context) => AddRidePage(), // Ensure this is correct
},

    );
  }
}
