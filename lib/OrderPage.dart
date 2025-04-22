import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class OrderPage extends StatefulWidget {
  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  DateTime? selectedDateTime;
  bool isOrderActive = true;
  String confirmationMessage = "";

  // Vehicle type selection
  final List<String> _vehicleTypes = [
    'Bus',
    'Coster',
    'Minibus',
    'Taxi',
    'Van',
    'Any'
  ];
  String? _selectedVehicleType;

  final SupabaseClient supabase = Supabase.instance.client;

  // Navigation state
  int _selectedIndex = 1; // Order is the 2nd item (index 1)
  final List<String> _pages = ['/', '/order', '/book', '/rides'];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pushNamed(context, _pages[index]);
  }

  void _selectPickup() async {
    final LatLng? result = await Navigator.pushNamed(context, '/map') as LatLng?;
    if (result != null) {
      String locationName = await getLocationName(
        result.latitude,
        result.longitude,
      );
      setState(() => _pickupController.text = locationName);
    }
  }

  void _selectDropoff() async {
    final LatLng? result = await Navigator.pushNamed(context, '/map') as LatLng?;
    if (result != null) {
      String locationName = await getLocationName(
        result.latitude,
        result.longitude,
      );
      setState(() => _dropoffController.text = locationName);
    }
  }

  void _selectDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _dateTimeController.text = DateFormat("yyyy-MM-dd HH:mm").format(selectedDateTime!);
        });
      }
    }
  }

  Future<void> _confirmRide() async {
    if (_pickupController.text.isEmpty ||
        _dropoffController.text.isEmpty ||
        (!isOrderActive && _dateTimeController.text.isEmpty) ||
        _selectedVehicleType == null) {
      setState(() => confirmationMessage = "Please fill in all fields.");
      return;
    }

    final rideData = {
      'pickup': _pickupController.text,
      'dropoff': _dropoffController.text,
      'date_time': isOrderActive ? null : _dateTimeController.text,
      'type': isOrderActive ? 'order' : 'book',
      'vehicle_type': _selectedVehicleType,
    };

    try {
      await supabase.from('orders').insert(rideData);
      setState(() => confirmationMessage = "Ride has successfully Confirmed!");
    } catch (e) {
      print("Supabase Error: $e");
      setState(() => confirmationMessage = "Error confirming ride. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: Color(0xFF8B5E3B),
        automaticallyImplyLeading: false,
        title: Text("Order Ride", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Order/Book toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => isOrderActive = true),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: isOrderActive ? Color(0xFF8B5E3B) : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            "Request Now",
                            style: TextStyle(
                              color: isOrderActive ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => isOrderActive = false),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: !isOrderActive ? Color(0xFF8B5E3B) : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            "Book Later",
                            style: TextStyle(
                              color: !isOrderActive ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Vehicle type selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Vehicle Type",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _vehicleTypes.map((type) {
                      bool isSelected = _selectedVehicleType == type;
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedVehicleType = selected ? type : null;
                            });
                          },
                          selectedColor: Color(0xFF8B5E3B),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Form content
            Expanded(
              child: isOrderActive ? buildOrderContent() : buildBookContent(),
            ),

            // Confirmation message
            if (confirmationMessage.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  confirmationMessage,
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Add Ride"),
        ],
      ),
    );
  }

  Widget buildOrderContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTextField("Pickup point", _pickupController, _selectPickup),
          SizedBox(height: 16),
          _buildTextField("Dropoff point", _dropoffController, _selectDropoff),
          SizedBox(height: 24),
          _buildConfirmButton("View Rides to Request"),
        ],
      ),
    );
  }

  Widget buildBookContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTextField("Pickup point", _pickupController, _selectPickup),
          SizedBox(height: 16),
          _buildTextField("Dropoff point", _dropoffController, _selectDropoff),
          SizedBox(height: 16),
          _buildTextField(
            "Select date & time",
            _dateTimeController,
            _selectDateTime,
          ),
          SizedBox(height: 24),
          _buildConfirmButton("View Rides to Book"),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    VoidCallback onTap,
  ) {
    Icon? icon = label.toLowerCase().contains('pickup') || label.toLowerCase().contains('dropoff')
        ? Icon(Icons.location_on, color: Color(0xFF8B5E3B))
        : Icon(Icons.calendar_today, color: Color(0xFF8B5E3B));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(
            prefixIcon: icon,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(String text) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF8B5E3B),
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: _confirmRide,
        child: Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  Future<String> getLocationName(double lat, double lon) async {
    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon",
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["display_name"] ?? "Unknown Location";
      }
      return "Unknown Location";
    } catch (e) {
      return "Unknown Location";
    }
  }
}