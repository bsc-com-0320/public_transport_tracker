import 'package:flutter/material.dart';

class SignUpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF5A3D1F), // Brown background
      body: SingleChildScrollView(
        // Wrap the entire body in SingleChildScrollView
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon at the top
              Icon(Icons.directions_bus, size: 80, color: Colors.white),
              SizedBox(height: 10),
              Text(
                "Sign Up",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),

              // Business Details Section
              _buildSectionTitle("Business Details", Colors.green),
              _buildInputField(Icons.business, "Company Name"),
              _buildInputField(Icons.category, "Category"),
              _buildInputField(Icons.more_horiz, "......................."),
              _buildInputField(Icons.more_horiz, "......................."),

              // Contact Details Section
              _buildSectionTitle("Contact Details", Colors.green),
              _buildInputField(Icons.email, "Email"),
              _buildInputField(Icons.phone, "Contact"),
              _buildInputField(Icons.more_horiz, "......................."),
              _buildInputField(Icons.more_horiz, "......................."),

              // Security Details Section
              _buildSectionTitle("Security Details", Colors.green),
              _buildInputField(Icons.lock, "Enter Password"),
              _buildInputField(Icons.lock, "Repeat Password"),
              _buildInputField(Icons.more_horiz, "......................."),
              _buildInputField(Icons.more_horiz, "......................."),

              SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: Text(
                      "Login",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    onPressed: () {
                      onPressed:
                      Navigator.pushNamed(context, '/');
                    },
                    child: Text(
                      "Sign Up",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: EdgeInsets.only(top: 10, bottom: 5),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInputField(IconData icon, String hintText) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFF5A3D1F)),
            hintText: hintText,
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(15),
          ),
        ),
      ),
    );
  }
}
