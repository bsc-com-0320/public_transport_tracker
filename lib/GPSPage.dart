import 'package:flutter/material.dart';

class GPSPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF5A3D1F), // Brown background
      appBar: AppBar(
        backgroundColor: Color(0xFF8B5E3B),
        title: Text("GPS Tracker", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Text(
                "GPS Tracking Feature",
                style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("AVAILABLE TRANSPORTS", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5A3D1F))),
                SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/rides'),
                      child: Card(
                        color: Color(0xFF8B5E3B),
                        child: ListTile(
                          title: Text("Ride ${index + 1}", style: TextStyle(color: Colors.white)),
                          leading: Icon(Icons.directions_car, color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
