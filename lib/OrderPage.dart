import 'package:flutter/material.dart';

class OrderPage extends StatefulWidget {
  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  bool isOrderActive = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5DC), // Light beige background
      appBar: AppBar(
        backgroundColor: Color(0xFF8B5E3B),
        title: Text("Order", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildToggleButton("Order", isOrderActive, () {
                    setState(() {
                      isOrderActive = true;
                    });
                  }),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildToggleButton("Book", !isOrderActive, () {
                    setState(() {
                      isOrderActive = false;
                    });
                  }),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: isOrderActive ? buildOrderContent() : buildBookContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Color(0xFF8B5E3B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget buildOrderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField("Pickup Point"),
        _buildTextField("Dropoff Point"),
        SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/accounts'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8B5E3B),
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
            child: Text("Order Now", style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget buildBookContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField("Select Date & Time"),
        _buildTextField("Pickup Point"),
        _buildTextField("Dropoff Point"),
        SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/accounts'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8B5E3B),
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
            child: Text("Book Now", style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        TextField(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
