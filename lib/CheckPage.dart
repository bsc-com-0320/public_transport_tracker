// Rides Page
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CheckPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF5A3D1F),
      appBar: AppBar(
        backgroundColor: Color(0xFF8B5E3B),
        title: Text("Checks", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: Text("This is  a Check Page",
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
    );
  }
}
