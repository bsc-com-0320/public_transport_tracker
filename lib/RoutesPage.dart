import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// Routes Page
class RoutesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF5A3D1F),
      appBar: AppBar(
        backgroundColor: Color(0xFF8B5E3B),
        title: Text("Routes", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Available Routes", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              itemCount: 5,
              itemBuilder: (context, index) {
                return Card(
                  color: Color(0xFF8B5E3B),
                  child: ListTile(
                    title: Text("Route ${index + 1}", style: TextStyle(color: Colors.white)),
                    leading: Icon(Icons.map, color: Colors.white),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
