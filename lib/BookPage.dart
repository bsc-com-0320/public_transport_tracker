import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'map_screen.dart';

class BookPage extends StatefulWidget {
  @override
  _BookPageState createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  DateTime? selectedDateTime;

  final SupabaseClient supabase = Supabase.instance.client;

  void _selectPickup() async {
    try {
      final LatLng? result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MapScreen()),
      );

      if (result != null) {
        debugPrint("Latitude: ${result.latitude}");
        debugPrint("Longitude: ${result.longitude}");

        String locationName = await getLocationName(result.latitude, result.longitude);

        setState(() {
          _pickupController.text = locationName;
        });
      }
    } catch (e) {
      print("Error selecting pickup location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to get pickup location. Please try again.")),
      );
    }
  }

  void _selectDropoff() async {
    try {
      final LatLng? result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MapScreen()),
      );

      if (result != null) {
        debugPrint("Latitude: ${result.latitude}");
        debugPrint("Longitude: ${result.longitude}");

        String locationName = await getLocationName(result.latitude, result.longitude);

        setState(() {
          _dropoffController.text = locationName;
        });
      }
    } catch (e) {
      print("Error selecting dropoff location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to get dropoff location. Please try again.")),
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
      'ride_date': selectedDateTime!.toIso8601String(),
    });

    if (response.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error booking ride!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ride booked successfully!")));
    }
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
            Text("Pickup Point", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            SizedBox(height: 5),
            TextField(controller: _pickupController, readOnly: true, onTap: _selectPickup, decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),)),
            SizedBox(height: 10),
            Text("Dropoff Point", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            SizedBox(height: 5),
            TextField(controller: _dropoffController, readOnly: true, onTap: _selectDropoff, decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),)),
            SizedBox(height: 10),
            Text("Select Date & Time", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            SizedBox(height: 5),
            TextField(controller: _dateTimeController, readOnly: true, onTap: _selectDateTime, decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),)),
            SizedBox(height: 20),
            Center(child: ElevatedButton(onPressed: _confirmBooking, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF8B5E3B), padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12)), child: Text("Confirm Booking", style: TextStyle(color: Colors.white)))),
          ],
        ),
      ),
    );
  }

  Future<String> getLocationName(double lat, double lon) async {
    final url = Uri.parse("https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String? location = data["display_name"] as String?;
        return location ?? "Unknown Location";
      } else {
        print("Failed to fetch location: ${response.statusCode}");
        return "Unknown Location";
      }
    } catch (e) {
      print("Error fetching location: $e");
      return "Unknown Location";
    }
  }
}
