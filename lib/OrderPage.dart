import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_typeahead/flutter_typeahead.dart';

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
  bool showAvailableRides = false;
  List<Map<String, dynamic>> availableRides = [];
  bool isLoadingRides = false;

  final List<String> _vehicleTypes = [
    'All',
    'Bus',
    'Coster',
    'Minibus',
    'Taxi',
    'Van',
  ];
  String? _selectedVehicleType;

  final SupabaseClient supabase = Supabase.instance.client;
  int _selectedIndex = 1;
  final List<String> _pages = ['/', '/order', '/records', '/rides'];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pushNamed(context, _pages[index]);
  }

  Future<void> _loadAvailableRides() async {
    setState(() => isLoadingRides = true);
    try {
      var query = supabase.from('ride').select('*');

      if (_selectedVehicleType != null && _selectedVehicleType != 'All') {
        query = query.eq('vehicle_type', _selectedVehicleType!);
      }

      final response = await query.order('departure_time', ascending: true);

      setState(() {
        availableRides = List<Map<String, dynamic>>.from(response);
        isLoadingRides = false;
      });
    } catch (e) {
      setState(() => isLoadingRides = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading rides: $e')));
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Location services are disabled')));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permissions are permanently denied')),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      String locationName = await getLocationName(
        position.latitude,
        position.longitude,
      );
      setState(() => _pickupController.text = locationName);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    }
  }

  Widget _buildPickupField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Pickup point",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TypeAheadField<String>(
                controller: _pickupController,
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: Color(0xFF8B5E3B),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 15,
                      ),
                      hintText: 'Search or select location',
                    ),
                  );
                },
                suggestionsCallback: (pattern) async {
                  if (pattern.length < 3) return [];
                  try {
                    final url = Uri.parse(
                      "https://nominatim.openstreetmap.org/search?format=json&q=$pattern&limit=5",
                    );
                    final response = await http.get(url);
                    if (response.statusCode == 200) {
                      final data = json.decode(response.body) as List;
                      return data
                          .map<String>((item) => item['display_name'] as String)
                          .toList();
                    }
                    return [];
                  } catch (e) {
                    return [];
                  }
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(title: Text(suggestion));
                },
                onSelected: (suggestion) {
                  setState(() {
                    _pickupController.text = suggestion;
                  });
                },
              ),
            ),
            SizedBox(width: 8),
            PopupMenuButton(
              icon: Icon(Icons.more_vert, color: Color(0xFF8B5E3B)),
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      child: Text("Use current location"),
                      onTap: () => _getCurrentLocation(),
                    ),
                    PopupMenuItem(
                      child: Text("Select on map"),
                      onTap: () => _selectPickup(),
                    ),
                  ],
            ),
          ],
        ),
      ],
    );
  }

  void _selectPickup() async {
    final LatLng? result =
        await Navigator.pushNamed(context, '/map') as LatLng?;
    if (result != null) {
      String locationName = await getLocationName(
        result.latitude,
        result.longitude,
      );
      setState(() => _pickupController.text = locationName);
    }
  }

  void _selectDropoff() async {
    final LatLng? result =
        await Navigator.pushNamed(context, '/map') as LatLng?;
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
          _dateTimeController.text = DateFormat(
            "yyyy-MM-dd HH:mm",
          ).format(selectedDateTime!);
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
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Order/Book toggle
                  // Single Toggle: Book Later or Request Now
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SwitchListTile(
                      title: Text(
                        isOrderActive ? "Request Now" : "Book for Later",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF5A3D1F),
                        ),
                      ),
                      activeColor: Color(0xFF8B5E3B),
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.grey[300],
                      value: !isOrderActive,
                      onChanged: (bool value) {
                        setState(() {
                          isOrderActive = !value;
                          showAvailableRides = false;
                        });
                      },
                    ),
                  ),

                  SizedBox(height: 20),

                  // Vehicle type selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Select Vehicle Type",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              _vehicleTypes.map((type) {
                                bool isSelected = _selectedVehicleType == type;
                                return Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(type),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedVehicleType =
                                            selected ? type : null;
                                        if (selected) _loadAvailableRides();
                                      });
                                    },
                                    selectedColor: Color(0xFF8B5E3B),
                                    labelStyle: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                    backgroundColor: Colors.grey[200],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Form content
                  if (!showAvailableRides)
                    Expanded(
                      child:
                          isOrderActive
                              ? _buildOrderContent()
                              : _buildBookContent(),
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
          ),

          // Available rides section
          if (showAvailableRides) _buildAvailableRidesSection(),
        ],
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
            icon: Icon(Icons.directions_bus),
            label: "Order",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: "Records",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Add Ride"),
        ],
      ),
    );
  }

  Widget _buildOrderContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildPickupField(), // Using the new pickup field
          SizedBox(height: 16),
          _buildTextField("Dropoff point", _dropoffController, _selectDropoff),
          SizedBox(height: 24),
          _buildConfirmButton("View Rides to Request"),
        ],
      ),
    );
  }

  Widget _buildBookContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildPickupField(), // Using the new pickup field
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

  Widget _buildAvailableRidesSection() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Rides',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => setState(() => showAvailableRides = false),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                isLoadingRides
                    ? Center(child: CircularProgressIndicator())
                    : availableRides.isEmpty
                    ? Center(child: Text('No available rides found'))
                    : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: availableRides.length,
                      itemBuilder: (context, index) {
                        final ride = availableRides[index];
                        try {
                          return _buildRideCard(ride);
                        } catch (e) {
                          return _buildErrorCard(e.toString());
                        }
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride) {
    try {
      // Parse departure time from string with custom format
      DateTime departureTime;
      try {
        // First try parsing with ISO format (if stored that way)
        departureTime =
            DateTime.tryParse(ride['departure_time']) ?? DateTime.now();

        // If that fails, try parsing with your custom format
        if (departureTime == DateTime.now()) {
          final formatsToTry = [
            "yyyy-MM-dd HH:mm:ss", // e.g., "2023-12-25 14:30:00"
            "dd/MM/yyyy h:mm a", // e.g., "25/12/2023 2:30 PM"
            "MMM dd, yyyy HH:mm", // e.g., "Dec 25, 2023 14:30"
            "yyyy-MM-dd HH:mm", // e.g., "2023-12-25 14:30"
          ];

          for (final format in formatsToTry) {
            try {
              departureTime = DateFormat(format).parse(ride['departure_time']);
              break;
            } catch (e) {
              continue;
            }
          }
        }
      } catch (e) {
        departureTime = DateTime.now();
      }

      final formattedDate = DateFormat('EEE, MMM d').format(departureTime);
      final formattedTime = DateFormat('h:mm a').format(departureTime);
      final seatsAvailable = ride['capacity'] is int ? ride['capacity'] : 0;
      final isFull = seatsAvailable <= 0;
      final totalCost =
          ride['total_cost'] is num
              ? (ride['total_cost'] as num).toDouble()
              : 0.0;

      return Card(
        margin: EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ride #${ride['ride_number']?.toString() ?? 'N/A'}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFull ? Colors.red[100] : Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isFull ? 'FULL' : '$seatsAvailable seats',
                      style: TextStyle(
                        color: isFull ? Colors.red[800] : Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.route, color: Color(0xFF8B5E3B), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride['route']?.toString() ?? 'No route specified',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Color(0xFF8B5E3B),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(formattedDate, style: TextStyle(fontSize: 12)),
                  SizedBox(width: 16),
                  Icon(Icons.access_time, color: Color(0xFF8B5E3B), size: 18),
                  SizedBox(width: 8),
                  Text(formattedTime, style: TextStyle(fontSize: 12)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Cost:', style: TextStyle(fontSize: 12)),
                  Text(
                    '\$${totalCost.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B5E3B),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: isFull ? null : () => _bookRide(ride),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFull ? Colors.grey : Color(0xFF8B5E3B),
                  minimumSize: Size(double.infinity, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isFull ? 'NO SEATS AVAILABLE' : 'BOOK NOW',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return _buildErrorCard(e.toString());
    }
  }

  Widget _buildErrorCard(String error) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: Colors.red[50],
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Text('Error: $error', style: TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    VoidCallback onTap,
  ) {
    Icon? icon =
        label.toLowerCase().contains('pickup') ||
                label.toLowerCase().contains('dropoff')
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
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {
          if (_selectedVehicleType == null) {
            setState(
              () => confirmationMessage = "Please select a vehicle type",
            );
            return;
          }
          setState(() {
            showAvailableRides = true;
            _loadAvailableRides();
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: TextStyle(color: Colors.white, fontSize: 18)),
            Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Future<void> _bookRide(Map<String, dynamic> ride) async {
    // First parse the departure time
    DateTime departureTime;
    try {
      departureTime =
          DateTime.tryParse(ride['departure_time']) ?? DateTime.now();
      if (departureTime == DateTime.now()) {
        final formatsToTry = [
          "yyyy-MM-dd HH:mm:ss",
          "dd/MM/yyyy h:mm a",
          "MMM dd, yyyy HH:mm",
          "yyyy-MM-dd HH:mm",
        ];

        for (final format in formatsToTry) {
          try {
            departureTime = DateFormat(format).parse(ride['departure_time']);
            break;
          } catch (e) {
            continue;
          }
        }
      }
    } catch (e) {
      departureTime = DateTime.now();
    }

    // Show confirmation dialog with the parsed time
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final formattedTime = DateFormat(
          'MMM dd, hh:mm a',
        ).format(departureTime);

        return AlertDialog(
          title: Text('Confirm Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to book this ride?'),
              SizedBox(height: 10),
              Text(
                'Ride #${ride['ride_number'] ?? 'N/A'}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('${ride['vehicle_type']} - $formattedTime'),
              Text('Cost: \$${ride['total_cost']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8B5E3B),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text('Confirm Booking'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 10),
              Text('Processing your booking...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Create booking data
      final bookingData = {
        'ride_id': ride['id'],
        'pickup': _pickupController.text,
        'dropoff': _dropoffController.text,
        'booking_time': DateTime.now().toIso8601String(),
        'type': isOrderActive ? 'order' : 'book', // Add type field
        'vehicle_type': ride['vehicle_type'],
        'departure_time': departureTime.toIso8601String(),
        'total_cost': ride['total_cost'],
      };

      // Insert into request_ride table
      await supabase.from('request_ride').insert(bookingData);

      // Booking successful
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('🎉 Ride booked successfully!')));

      // Update the ride's available seats
      if (ride['capacity'] > 0) {
        await supabase
            .from('ride')
            .update({'capacity': ride['capacity'] - 1})
            .eq('id', ride['id']);
      }

      // Refresh available rides
      _loadAvailableRides();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to book ride: ${e.toString()}')),
      );
    }
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
