import 'package:flutter/material.dart';
import 'BookPage.dart'; // Import the BookPage

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _selectedTransport = "All";

  final List<String> _pages = ['/', '/order', '/book', '/rides']; // Change '/add_ride' to '/rides'


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    Navigator.pushNamed(context, _pages[index]);
  }

  void _filterTransport(String transportType) {
    setState(() {
      _selectedTransport = transportType;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: Color(0xFF8B5E3B),
        title: Text("Transport Tracker", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/account'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Choose What You Need",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTransportOption(Icons.local_taxi, "Taxi"),
                _buildTransportOption(Icons.directions_bus, "Bus"),
                _buildTransportOption(Icons.pedal_bike, "Bike"),
              ],
            ),
            SizedBox(height: 20),
            Text("Available Rides",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return _selectedTransport == "All" ||
                          (index % 3 == 0 && _selectedTransport == "Taxi") ||
                          (index % 3 == 1 && _selectedTransport == "Bus") ||
                          (index % 3 == 2 && _selectedTransport == "Bike")
                      ? Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Icon(
                              _selectedTransport == "Bus"
                                  ? Icons.directions_bus
                                  : _selectedTransport == "Bike"
                                      ? Icons.pedal_bike
                                      : Icons.local_taxi,
                              color: Color(0xFF8B5E3B),
                            ),
                            title:
                                Text("${_selectedTransport} Ride ${index + 1}"),
                            subtitle: Text("6 Miles - 30 Minutes (Approx)"),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF8B5E3B)),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => BookPage()),
                                );
                              },
                              child: Text("Order Now",
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        )
                      : SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF8B5E3B),
        unselectedItemColor: Color(0xFF5A3D1F),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_bus), label: "Order"),
          BottomNavigationBarItem(icon: Icon(Icons.book_online), label: "Book"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Add Ridess"),
        ],
      ),
    );
  }

  Widget _buildTransportOption(IconData icon, String label) {
    bool isActive = _selectedTransport == label;
    return GestureDetector(
      onTap: () => _filterTransport(label),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: isActive ? Colors.green : Color(0xFF8B5E3B),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          SizedBox(height: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 16,
                  color: isActive ? Colors.green : Colors.black,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
