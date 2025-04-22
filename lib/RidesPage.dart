import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RidesPage extends StatefulWidget {
  @override
  _RidesPageState createState() => _RidesPageState();
}

class _RidesPageState extends State<RidesPage> {
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF5A3D1F), // Brown background
      appBar: AppBar(
        backgroundColor: Color(0xFF5A3D1F),
        title: Text("Add Service",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Icon(Icons.account_circle, color: Colors.white, size: 30),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rides & Services Tabs
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTab("Rides", true), // Active
                  _buildTab("Vehicles", false), // Inactive
                ],
              ),
              SizedBox(height: 15),

              // Add Photos Button
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFF8B5E3B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      if (_selectedImage != null)
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        )
                      else
                        Icon(Icons.add, color: Colors.white, size: 40),
                      SizedBox(height: 5),
                      Text(
                        _selectedImage != null ? "Change Photo" : "Add Photos",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 15),

              // Input Fields with clickable icons
              _buildClickableInputField(
                  context, Icons.directions_bus, "Ride number", '/rides'),
              _buildClickableInputField(
                  context, Icons.location_on, "Route", '/routes'),
              _buildClickableInputField(
                  context, Icons.access_time, "Departure Time", '/rides'),
              _buildClickableInputField(
                  context, Icons.people, "Capacity", '/rides'),
              _buildClickableInputField(context, Icons.monetization_on,
                  "Total Route Cost", '/rides'),
              _buildClickableInputField(
                  context, Icons.more_horiz, "Other", '/rides'),

              SizedBox(height: 20),

              // Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionButton(Icons.cancel, "Cancel", Colors.red),
                  _buildActionButton(Icons.check, "Add Service", Colors.green),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF5A3D1F),
        unselectedItemColor: Color(0xFF8B5E3B),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_bus), label: "Order"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Book"),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle), label: "Add Ride"),
        ],
        onTap: (index) {
          // Handle navigation when tapping on bottom nav items
          if (index == 0) {
            Navigator.pushNamed(context, '/'); // Home
          } else if (index == 1) {
            Navigator.pushNamed(context, '/order'); // Order
          } else if (index == 2) {
            Navigator.pushNamed(context, '/book'); // Book
          } else if (index == 3) {
            Navigator.pushNamed(context, '/addRide'); // Add Ride
          }
        },
      ),
    );
  }

  // Custom clickable input field with navigation
  Widget _buildClickableInputField(
      BuildContext context, IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, route), // Navigate to specified page
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Color(0xFF5A3D1F)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    color: Color(0xFF5A3D1F), fontWeight: FontWeight.bold),
              ),
            ),
            Icon(Icons.arrow_forward, color: Color(0xFF5A3D1F)),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 25),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Color(0xFF8B5E3B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Color(0xFF5A3D1F) : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        SizedBox(height: 5),
        Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}