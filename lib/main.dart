// main.dart
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
        scaffoldBackgroundColor: Color(0xFFF5F5DC),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MainNavigationPage(),
        '/order': (context) => OrderPage(),
        '/edit-profile': (context) => EditProfilePage(),
        '/check': (context) => CheckPage(),
        '/accounts': (context) => AccountsPage(),
      },
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  @override
  _MainNavigationPageState createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    OrderPage(),
    CheckPage(),
    AccountsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Color(0xFF8B5E3B),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: 'Order',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Account',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF5A3D1F),
        child: Icon(Icons.person),
        onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
      ),
    );
  }
}