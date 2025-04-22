import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class RidesPage extends StatefulWidget {
  @override
  _RidesPageState createState() => _RidesPageState();
}

class _RidesPageState extends State<RidesPage> {
  final _supabase = Supabase.instance.client;
  File? _selectedImage;
  final _formKey = GlobalKey<FormState>();
  bool _isRideSelected = true;
  bool _isLoading = false;
  int _selectedIndex = 3; // Add Ride is the 4th item (index 3)

  // Navigation routes
  final List<String> _pages = ['/', '/order', '/book', '/rides'];

  // Vehicle type dropdown options
  final List<String> _vehicleTypes = [
    'Bus',
    'Coster',
    'Minibus',
    'Taxi',
    'Van'
  ];
  String? _selectedVehicleType;

  // Controllers for ride fields
  final TextEditingController _rideNumberController = TextEditingController();
  final TextEditingController _routeController = TextEditingController();
  final TextEditingController _departureTimeController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _totalCostController = TextEditingController();

  // Controller for vehicle field
  final TextEditingController _numberPlateController = TextEditingController();
  final TextEditingController _vehicleCapacityController = TextEditingController();

  TimeOfDay? _selectedTime;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pushNamed(context, _pages[index]);
  }

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

  Future<void> _uploadRideData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        final filePath = 'rides/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.storage
            .from('ride_images')
            .upload(filePath, _selectedImage!);
        imageUrl = _supabase.storage.from('ride_images').getPublicUrl(filePath);
      }

      await _supabase.from('ride').insert({
        'ride_number': _rideNumberController.text,
        'route': _routeController.text,
        'departure_time': _departureTimeController.text,
        'capacity': int.parse(_capacityController.text),
        'total_cost': double.parse(_totalCostController.text),
        'created_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ride added successfully!')),
      );
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding ride: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadVehicleData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        final filePath = 'vehicles/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.storage
            .from('vehicle_images')
            .upload(filePath, _selectedImage!);
        imageUrl = _supabase.storage.from('vehicle_images').getPublicUrl(filePath);
      }

      await _supabase.from('vehicle').insert({
        'number_plate': _numberPlateController.text,
        'vehicle_type': _selectedVehicleType,
        'capacity': int.parse(_vehicleCapacityController.text),
        'created_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vehicle added successfully!')),
      );
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding vehicle: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _rideNumberController.clear();
    _routeController.clear();
    _departureTimeController.clear();
    _capacityController.clear();
    _totalCostController.clear();
    _numberPlateController.clear();
    _vehicleCapacityController.clear();
    setState(() {
      _selectedImage = null;
      _selectedTime = null;
      _selectedVehicleType = null;
    });
  }

  @override
  void dispose() {
    _rideNumberController.dispose();
    _routeController.dispose();
    _departureTimeController.dispose();
    _capacityController.dispose();
    _totalCostController.dispose();
    _numberPlateController.dispose();
    _vehicleCapacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF5A3D1F),
      appBar: AppBar(
         automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF5A3D1F),
        title: Text(
          _isRideSelected ? "Add Ride" : "Add Vehicle",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Icon(Icons.account_circle, color: Colors.white, size: 30),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rides & Vehicles Tabs
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isRideSelected = true;
                              });
                            },
                            child: _buildTab("Rides", _isRideSelected),
                          ),
                          SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isRideSelected = false;
                              });
                            },
                            child: _buildTab("Vehicles", !_isRideSelected),
                          ),
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

                      // Show Ride or Vehicle fields based on selection
                      if (_isRideSelected) ...[
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
                      ] else ...[
                        // Number Plate
                        _buildInputField(
                          context,
                          Icons.directions_car,
                          "Number Plate",
                          _numberPlateController,
                          TextInputType.text,
                          (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter number plate';
                            }
                            if (!RegExp(r'^[A-Z0-9\s]{3,15}$').hasMatch(value)) {
                              return 'Enter valid plate (e.g., ABC 1234)';
                            }
                            return null;
                          },
                        ),

                        // Vehicle Type Dropdown
                        Container(
                          margin: EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedVehicleType,
                            icon: Icon(Icons.arrow_drop_down, color: Color(0xFF5A3D1F)),
                            decoration: InputDecoration(
                              icon: Icon(Icons.category, color: Color(0xFF5A3D1F)),
                              labelText: "Vehicle Type",
                              border: InputBorder.none,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select vehicle type';
                              }
                              return null;
                            },
                            items: _vehicleTypes.map((String type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedVehicleType = newValue;
                              });
                            },
                          ),
                        ),

                        // Vehicle Capacity
                        _buildInputField(
                          context,
                          Icons.people,
                          "Seating Capacity",
                          _vehicleCapacityController,
                          TextInputType.number,
                          (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter seating capacity';
                            }
                            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                              return 'Please enter numbers only';
                            }
                            return null;
                          },
                        ),
                      ],

                      SizedBox(height: 20),

                      // Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildActionButton(Icons.cancel, "Cancel", Colors.red, () {
                            Navigator.pop(context);
                          }),
                          _buildActionButton(Icons.check, _isRideSelected ? "Add Ride" : "Add Vehicle", Colors.green, () {
                            if (_formKey.currentState!.validate()) {
                              _isRideSelected ? _uploadRideData() : _uploadVehicleData();
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
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Add Ride"),
        ],
      ),
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