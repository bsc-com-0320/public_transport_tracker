import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Transport Tracker"),
        backgroundColor: Colors.brown,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.green,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Transport Tracker\n8 Miles",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Icon(Icons.location_on, color: Colors.white),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("City Destination", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTransportOption(Icons.directions_bus, "Bus"),
                      _buildTransportOption(Icons.local_taxi, "Taxi"),
                      _buildTransportOption(Icons.directions_bike, "Bike"),
                    ],
                  ),
                ],
              ),
            ),
          ),
          BottomNavigationBar(
            backgroundColor: Colors.brown,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white60,
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransportOption(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.brown,
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 16)),
      ],
    );
  }
}
