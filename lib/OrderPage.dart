import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'map_screen.dart';

class OrderPage extends StatefulWidget {
  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  DateTime? selectedDateTime;
  final SupabaseClient supabase = Supabase.instance.client;

  void _selectLocation(TextEditingController controller) async {
    try {
      final LatLng? result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MapScreen()),
      );

      if (result != null) {
        String locationName = await getLocationName(result.latitude, result.longitude);
        setState(() {
          controller.text = locationName;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to get location. Please try again.")),
      );
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

  void _confirmBooking() async {
    if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty || selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all fields!")));
      return;
    }

    final response = await supabase.from('booking').insert({
      'pickup_point': _pickupController.text,
      'dropoff_point': _dropoffController.text,
      'datetime': selectedDateTime!.toIso8601String(),
    }).select();

    if (response == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unexpected error: Response is null")));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ride booked successfully!")));
  }

  Future<String> getLocationName(double lat, double lon) async {
    final url = Uri.parse("https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["display_name"] ?? "Unknown Location";
      }
    } catch (e) {
      print("Error fetching location: $e");
    }
    return "Unknown Location";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: Color(0xFF8B5E3B),
        title: Text("Book a Ride", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildLocationField("Pickup Point", _pickupController, () => _selectLocation(_pickupController)),
            SizedBox(height: 10),
            buildLocationField("Dropoff Point", _dropoffController, () => _selectLocation(_dropoffController)),
            SizedBox(height: 10),
            buildLocationField("Select Date & Time", _dateTimeController, _selectDateTime),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _confirmBooking,
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF8B5E3B)),
                child: Text("Confirm Booking", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLocationField(String label, TextEditingController controller, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        SizedBox(height: 5),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
