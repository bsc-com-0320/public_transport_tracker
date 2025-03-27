import 'package:flutter/material.dart';
import 'EditProfilePage.dart';
import 'OrderPage.dart';
import 'CheckPage.dart';
import 'AccountsPage.dart';

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
      initialRoute: '/order', // Ensure this exists in the routes map
      routes: {
        '/order': (context) => OrderPage(),
        '/edit-profile': (context) => EditProfilePage(),
        '/check': (context) => CheckPage(),
        '/accounts': (context) => AccountsPage(),
      },
    );
  }
}

