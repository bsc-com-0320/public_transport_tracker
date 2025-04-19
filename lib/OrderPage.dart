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
  int _selectedIndex = 1;

  final SupabaseClient supabase = Supabase.instance.client;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        // Already on OrderPage
        break;
      case 2:
        Navigator.pushNamed(context, '/book');
        break;
      case 3:
        Navigator.pushNamed(context, '/addRide');
        break;
    }
  }

  void _selectPickup() async {
    final LatLng? result = await Navigator.pushNamed(context, '/map') as LatLng?;
    if (result != null) {
      String locationName = await getLocationName(result.latitude, result.longitude);
      setState(() => _pickupController.text = locationName);
    }
  }

  void _selectDropoff() async {
    final LatLng? result = await Navigator.pushNamed(context, '/map') as LatLng?;
    if (result != null) {
      String locationName = await getLocationName(result.latitude, result.longitude);
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
            pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute,
          );
          _dateTimeController.text = DateFormat("yyyy-MM-dd HH:mm").format(selectedDateTime!);
        });
      }
    }
  }

  Future<void> _confirmRide() async {
    if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty || (!isOrderActive && _dateTimeController.text.isEmpty)) {
      setState(() => confirmationMessage = "Please fill in all fields.");
      return;
    }

    final rideData = {
      'pickup': _pickupController.text,
      'dropoff': _dropoffController.text,
      'date_time': isOrderActive ? null : _dateTimeController.text,
      'type': isOrderActive ? 'order' : 'book',
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    try {
      await supabase.from('request_ride').insert(rideData);
      await Future.delayed(Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/accounts');
      }
    } catch (e) {
      Navigator.pop(context);
      print("Supabase Error: $e");
      setState(() => confirmationMessage = "Error confirming ride. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5DC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF8B5E3B),
        title: Text("Request Ride", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildToggleButton("Request Ride", isOrderActive, () => setState(() => isOrderActive = true))),
                SizedBox(width: 10),
                Expanded(child: _buildToggleButton("Book", !isOrderActive, () => setState(() => isOrderActive = false))),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: isOrderActive ? buildOrderContent() : buildBookContent(),
            ),
            if (confirmationMessage.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(confirmationMessage, style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
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
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: "Order"),
          BottomNavigationBarItem(icon: Icon(Icons.book_online), label: "Book"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Add Ride"),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
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
      children: [
        _buildTextField("pickup point", _pickupController, _selectPickup),
        _buildTextField("dropoff point", _dropoffController, _selectDropoff),
        _buildTextField("select date & time", _dateTimeController, _selectDateTime),
        ElevatedButton(onPressed: _confirmRide, child: Text("Request Ride Now")),
      ],
    );
  }

  Widget buildBookContent() {
    return Column(
      children: [
        _buildTextField("pickup point", _pickupController, _selectPickup),
        _buildTextField("dropoff point", _dropoffController, _selectDropoff),
        _buildTextField("select date & time", _dateTimeController, _selectDateTime),
        ElevatedButton(onPressed: _confirmRide, child: Text("Book Now")),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, VoidCallback onTap) {
    Icon? icon;

    if (label.toLowerCase().contains('pickup') || label.toLowerCase().contains('dropoff')) {
      icon = Icon(Icons.location_on, color: Colors.brown);
    } else if (label.toLowerCase().contains('date')) {
      icon = Icon(Icons.calendar_today, color: Colors.brown);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(
            prefixIcon: icon,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Future<String> getLocationName(double lat, double lon) async {
    final url = Uri.parse("https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon");
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
