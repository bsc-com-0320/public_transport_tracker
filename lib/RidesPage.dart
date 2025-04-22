import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RidesPage extends StatefulWidget {
  @override
  _RidesPageState createState() => _RidesPageState();
}

class _RidesPageState extends State<RidesPage> {
  File? _selectedImage;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for all input fields
  final TextEditingController _rideNumberController = TextEditingController();
  final TextEditingController _routeController = TextEditingController();
  final TextEditingController _departureTimeController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _totalCostController = TextEditingController();
  
  TimeOfDay? _selectedTime;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _departureTimeController.text = picked.format(context);
      });
    }
  }

  @override
  void dispose() {
    _rideNumberController.dispose();
    _routeController.dispose();
    _departureTimeController.dispose();
    _capacityController.dispose();
    _totalCostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF5A3D1F),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rides & Services Tabs
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTab("Rides", true),
                    _buildTab("Vehicles", false),
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

                // Ride Number (Numbers only)
                _buildInputField(
                  context,
                  Icons.directions_bus,
                  "Ride number",
                  _rideNumberController,
                  TextInputType.number,
                  (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter ride number';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'Please enter numbers only';
                    }
                    return null;
                  },
                ),

                // Route (Text)
                _buildInputField(
                  context,
                  Icons.location_on,
                  "Route",
                  _routeController,
                  TextInputType.text,
                  (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter route';
                    }
                    return null;
                  },
                ),

                // Departure Time (Time picker)
                GestureDetector(
                  onTap: () => _selectTime(context),
                  child: AbsorbPointer(
                    child: _buildInputField(
                      context,
                      Icons.access_time,
                      "Departure Time",
                      _departureTimeController,
                      TextInputType.datetime,
                      (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select departure time';
                        }
                        return null;
                      },
                    ),
                  ),
                ),

                // Capacity (Numbers only)
                _buildInputField(
                  context,
                  Icons.people,
                  "Capacity",
                  _capacityController,
                  TextInputType.number,
                  (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter capacity';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'Please enter numbers only';
                    }
                    return null;
                  },
                ),

                // Total Route Cost (Numbers with decimal)
                _buildInputField(
                  context,
                  Icons.monetization_on,
                  "Total Route Cost",
                  _totalCostController,
                  TextInputType.numberWithOptions(decimal: true),
                  (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter total cost';
                    }
                    if (!RegExp(r'^[0-9]+(\.[0-9]{1,2})?$').hasMatch(value)) {
                      return 'Please enter valid amount';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 20),

                // Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildActionButton(Icons.cancel, "Cancel", Colors.red, () {
                      Navigator.pop(context);
                    }),
                    _buildActionButton(Icons.check, "Add Service", Colors.green, () {
                      if (_formKey.currentState!.validate()) {
                        // Form is valid, proceed with submission
                        _submitForm();
                      }
                    }),
                  ],
                ),
              ],
            ),
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
          if (index == 0) {
            Navigator.pushNamed(context, '/');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/order');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/book');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/addRide');
          }
        },
      ),
    );
  }

  void _submitForm() {
    // Handle form submission here
    print('Ride Number: ${_rideNumberController.text}');
    print('Route: ${_routeController.text}');
    print('Departure Time: ${_departureTimeController.text}');
    print('Capacity: ${_capacityController.text}');
    print('Total Cost: ${_totalCostController.text}');
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Service added successfully!')),
    );
  }

  Widget _buildInputField(
    BuildContext context,
    IconData icon,
    String label,
    TextEditingController controller,
    TextInputType keyboardType,
    String? Function(String?)? validator,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          icon: Icon(icon, color: Color(0xFF5A3D1F)),
          labelText: label,
          border: InputBorder.none,
        ),
        validator: validator,
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

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onPressed) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: color,
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 30),
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 5),
        Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}