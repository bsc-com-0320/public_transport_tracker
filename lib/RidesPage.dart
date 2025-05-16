import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:math';

class RidesPage extends StatefulWidget {
  @override
  _RidesPageState createState() => _RidesPageState();
}

class _RidesPageState extends State<RidesPage> {
  final TextEditingController _numberPlateController = TextEditingController();
  final TextEditingController _vehicleCapacityController = TextEditingController();

  final _supabase = Supabase.instance.client;
  File? _selectedImage;
  final _formKey = GlobalKey<FormState>();
  bool _isRideSelected = true;
  bool _isLoading = false;
  int _selectedIndex = 3;

  // Navigation routes
  final List<String> _pages = ['/', '/order', '/records', '/rides'];

  // Vehicle type dropdown options
  final List<String> _vehicleTypes = [
    'Bus',
    'Coster',
    'Minibus',
    'Taxi',
    'Van',
  ];
  String? _selectedVehicleType;

  // Controllers for ride fields
  final TextEditingController _rideNumberController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _totalCostController = TextEditingController();
  final TextEditingController _departureTimeController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();

  TimeOfDay? _selectedTime;
  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;
  double _distanceInKm = 0.0;

  @override
  void initState() {
    super.initState();
    _distanceController.text = '0.0';
  }

  @override
  void dispose() {
    _rideNumberController.dispose();
    _capacityController.dispose();
    _totalCostController.dispose();
    _departureTimeController.dispose();
    _distanceController.dispose();
    _contactController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

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

  Future<void> _getCurrentLocation(bool isPickup) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location services are disabled')));
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
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final locationName = await getLocationName(
        position.latitude,
        position.longitude,
      );

      setState(() {
        if (isPickup) {
          _pickupLatLng = LatLng(position.latitude, position.longitude);
          _pickupController.text = locationName;
        } else {
          _dropoffLatLng = LatLng(position.latitude, position.longitude);
          _dropoffController.text = locationName;
        }
      });

      _calculateDistance();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: ${e.toString()}')),
      );
    }
  }

  Future<String> getLocationName(double lat, double lon) async {
    try {
      final places = await placemarkFromCoordinates(lat, lon);
      if (places.isNotEmpty) {
        final place = places.first;
        return [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].where((part) => part?.isNotEmpty ?? false).join(', ');
      }
      return 'Current Location';
    } catch (e) {
      return 'Current Location';
    }
  }

  Future<void> _selectOnMap(bool isPickup) async {
    try {
      final result = await Navigator.pushNamed(context, '/map') as LatLng?;
      if (result != null) {
        final locationName = await getLocationName(
          result.latitude,
          result.longitude,
        );

        setState(() {
          if (isPickup) {
            _pickupLatLng = result;
            _pickupController.text = locationName;
          } else {
            _dropoffLatLng = result;
            _dropoffController.text = locationName;
          }
        });

        _calculateDistance();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting location: ${e.toString()}')),
      );
    }
  }

  void _calculateDistance() {
    if (_pickupLatLng != null && _dropoffLatLng != null) {
      final distance = _coordinateDistance(
        _pickupLatLng!.latitude,
        _pickupLatLng!.longitude,
        _dropoffLatLng!.latitude,
        _dropoffLatLng!.longitude,
      );

      setState(() {
        _distanceInKm = distance;
        _distanceController.text = distance.toStringAsFixed(1);
      });
    } else {
      setState(() {
        _distanceInKm = 0.0;
        _distanceController.text = '0.0';
      });
    }
  }

  double _coordinateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = pi / 180;
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Future<void> _uploadRideData() async {
    if (!_formKey.currentState!.validate()) return;

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
        'capacity': int.parse(_capacityController.text),
        'total_cost': double.parse(_totalCostController.text),
        'departure_time': _departureTimeController.text,
        'vehicle_type': _selectedVehicleType,
        'distance': _distanceInKm,
        'pickup_point': _pickupController.text,
        'dropoff_point': _dropoffController.text,
        'contact': _contactController.text,
        'pickup_lat': _pickupLatLng?.latitude,
        'pickup_lng': _pickupLatLng?.longitude,
        'dropoff_lat': _dropoffLatLng?.latitude,
        'dropoff_lng': _dropoffLatLng?.longitude,
        'created_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ride added successfully!')));
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

  void _clearForm() {
    _rideNumberController.clear();
    _capacityController.clear();
    _totalCostController.clear();
    _departureTimeController.clear();
    _contactController.clear();
    _pickupController.clear();
    _dropoffController.clear();
    _distanceController.text = '0.0';
    setState(() {
      _selectedImage = null;
      _selectedTime = null;
      _selectedVehicleType = null;
      _pickupLatLng = null;
      _dropoffLatLng = null;
      _distanceInKm = 0.0;
    });
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
        imageUrl = _supabase.storage
            .from('vehicle_images')
            .getPublicUrl(filePath);
      }

      await _supabase.from('vehicle').insert({
        'number_plate': _numberPlateController.text,
        'vehicle_type': _selectedVehicleType,
        'capacity': int.parse(_vehicleCapacityController.text),
        'created_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vehicle added successfully!')));
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

  Widget _buildLocationField(
    String label,
    TextEditingController controller,
    bool isPickup,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF5A3D1F),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TypeAheadField<String>(
                controller: controller,
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: Color(0xFF5A3D1F),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 15,
                      ),
                      hintText: 'Search or select location',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                    ),
                  );
                },
                suggestionsCallback: (pattern) async {
                  if (pattern.length < 3) return [];
                  try {
                    final locations = await locationFromAddress(pattern);
                    return locations
                        .map((loc) => '${loc.latitude},${loc.longitude}')
                        .toList();
                  } catch (e) {
                    return [];
                  }
                },
                itemBuilder:
                    (context, suggestion) => ListTile(title: Text(suggestion)),
                onSelected: (suggestion) async {
                  final coords = suggestion.split(',');
                  final lat = double.tryParse(coords[0]);
                  final lng = double.tryParse(coords[1]);
                  if (lat != null && lng != null) {
                    final locationName = await getLocationName(lat, lng);
                    controller.text = locationName;
                    setState(() {
                      if (isPickup) {
                        _pickupLatLng = LatLng(lat, lng);
                      } else {
                        _dropoffLatLng = LatLng(lat, lng);
                      }
                    });
                    _calculateDistance();
                  }
                },
              ),
            ),
            SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF8B5E3B),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.map, color: Colors.white),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPickup)
                          ListTile(
                            leading: Icon(Icons.my_location),
                            title: Text("Use current location"),
                            onTap: () {
                              Navigator.pop(context);
                              _getCurrentLocation(isPickup);
                            },
                          ),
                        ListTile(
                          leading: Icon(Icons.map),
                          title: Text("Select on map"),
                          onTap: () {
                            Navigator.pop(context);
                            _selectOnMap(isPickup);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          _isRideSelected ? "Add Ride" : "Add Vehicle",
          style: TextStyle(
            color: Color(0xFF5A3D1F),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Color(0xFF5A3D1F)),
            onPressed: () {},
          ),
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: CircleAvatar(
              backgroundColor: Color(0xFF5A3D1F).withOpacity(0.1),
              child: Icon(Icons.person, color: Color(0xFF5A3D1F)),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF5A3D1F)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rides & Vehicles Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _isRideSelected = true),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(
                                  color: _isRideSelected ? Color(0xFF8B5E3B).withOpacity(0.2) : Colors.transparent,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "Rides",
                                    style: TextStyle(
                                      color: _isRideSelected ? Color(0xFF5A3D1F) : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _isRideSelected = false),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(
                                  color: !_isRideSelected ? Color(0xFF8B5E3B).withOpacity(0.2) : Colors.transparent,
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "Vehicles",
                                    style: TextStyle(
                                      color: !_isRideSelected ? Color(0xFF5A3D1F) : Colors.grey[600],
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

                    // Add Photos Button
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            if (_selectedImage != null)
                              Container(
                                height: 120,
                                width: 120,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: FileImage(_selectedImage!),
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              )
                            else
                              Container(
                                height: 80,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Color(0xFF8B5E3B).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: Icon(
                                  Icons.add_a_photo,
                                  color: Color(0xFF5A3D1F),
                                  size: 40,
                                ),
                              ),
                            SizedBox(height: 10),
                            Text(
                              _selectedImage != null ? "Change Photo" : "Add Photos",
                              style: TextStyle(
                                color: Color(0xFF5A3D1F),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Show Ride or Vehicle fields based on selection
                    if (_isRideSelected) ...[
                      // Ride Number (Numbers only)
                      _buildInputField(
                        context,
                        Icons.confirmation_number,
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

                      // Vehicle Type Dropdown
                      _buildDropdownField(
                        "Vehicle Type",
                        _selectedVehicleType,
                        (String? newValue) {
                          setState(() {
                            _selectedVehicleType = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select vehicle type';
                          }
                          return null;
                        },
                      ),

                      // Pickup Point
                      _buildLocationField(
                        "Pickup Point",
                        _pickupController,
                        true,
                      ),
                      SizedBox(height: 15),

                      // Dropoff Point
                      _buildLocationField(
                        "Dropoff Point",
                        _dropoffController,
                        false,
                      ),
                      SizedBox(height: 15),

                      // Distance (auto-calculated)
                      _buildInputField(
                        context,
                        Icons.directions,
                        "Distance (km)",
                        _distanceController,
                        TextInputType.numberWithOptions(decimal: true),
                        (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select both locations to calculate distance';
                          }
                          return null;
                        },
                        readOnly: true,
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

                      // Total Cost (Numbers with decimal)
                      _buildInputField(
                        context,
                        Icons.monetization_on,
                        "Total Cost",
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

                      // Contact Information
                      _buildInputField(
                        context,
                        Icons.phone,
                        "Contact",
                        _contactController,
                        TextInputType.phone,
                        (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter contact information';
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
                      _buildDropdownField(
                        "Vehicle Type",
                        _selectedVehicleType,
                        (String? newValue) {
                          setState(() {
                            _selectedVehicleType = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select vehicle type';
                          }
                          return null;
                        },
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

                    SizedBox(height: 25),

                    // Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Cancel Button
                        _buildActionButton(
                          "Cancel",
                          Colors.white,
                          Color(0xFF5A3D1F),
                          Icons.close,
                          () {
                            Navigator.pop(context);
                          },
                        ),
                        
                        // Add Ride/Vehicle Button
                        _buildActionButton(
                          _isRideSelected ? "Add Ride" : "Add Vehicle",
                          Color(0xFF5A3D1F),
                          Colors.white,
                          Icons.check,
                          () {
                            if (_formKey.currentState!.validate()) {
                              _isRideSelected
                                  ? _uploadRideData()
                                  : _uploadVehicleData();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildInputField(
    BuildContext context,
    IconData icon,
    String label,
    TextEditingController controller,
    TextInputType keyboardType,
    String? Function(String?)? validator, {
    bool readOnly = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: Color(0xFF5A3D1F)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    void Function(String?) onChanged, {
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        icon: Icon(Icons.arrow_drop_down, color: Color(0xFF5A3D1F)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.directions_car, color: Color(0xFF5A3D1F)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        ),
        validator: validator,
        items: _vehicleTypes.map((String type) {
          return DropdownMenuItem<String>(
            value: type,
            child: Text(type),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    Color backgroundColor,
    Color textColor,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Color(0xFF5A3D1F),
                width: backgroundColor == Colors.white ? 1 : 0,
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 15),
            elevation: 5,
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF5A3D1F),
      unselectedItemColor: Colors.grey[600],
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      elevation: 10,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_bus_outlined),
          activeIcon: Icon(Icons.directions_bus),
          label: "Order",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history),
          label: "Records",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          activeIcon: Icon(Icons.add_circle),
          label: "Add Ride",
        ),
      ],
    );
  }
}