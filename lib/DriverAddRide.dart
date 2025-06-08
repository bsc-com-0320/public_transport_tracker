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
import 'available_driver_rides.dart'; // Import the AvailableDriverRides screen

/// A StatefulWidget for drivers to add new rides or view available rides.
class DriverAddRide extends StatefulWidget {
  @override
  _DriverAddRide createState() => _DriverAddRide();
}

/// The State class for DriverAddRide.
class _DriverAddRide extends State<DriverAddRide> {
  // Text editing controllers for various input fields.
  final TextEditingController _numberPlateController = TextEditingController();
  final TextEditingController _vehicleCapacityController = TextEditingController();
  final TextEditingController _rideNumberController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _totalCostController = TextEditingController();
  final TextEditingController _departureTimeController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();

  // Supabase client instance for database interactions.
  final _supabase = Supabase.instance.client;
  // File to store the selected image.
  File? _selectedImage;
  // Global key for the form to validate inputs.
  final _formKey = GlobalKey<FormState>();
  // Flag to indicate whether the "Add Ride" tab is selected.
  bool _isAddRideSelected = true; // Renamed from _isRideSelected for clarity
  // Flag to indicate if data is being loaded/uploaded.
  bool _isLoading = false;
  // Index for bottom navigation bar.
  int _selectedIndex = 1;

  // Navigation routes for the bottom navigation bar.
  final List<String> _pages = [
    '/driver-home',
    '/driver-ride', // This screen's route
    '/driver-records',
    '/driver-fund-account',
  ];

  // Vehicle type dropdown options.
  final List<String> _vehicleTypes = [
    'Bus',
    'Coster',
    'Minibus',
    'Taxi',
    'Van',
  ];
  String? _selectedVehicleType; // Currently selected vehicle type.

  TimeOfDay? _selectedTime; // Selected departure time.
  LatLng? _pickupLatLng; // Latitude and longitude for pickup point.
  LatLng? _dropoffLatLng; // Latitude and longitude for dropoff point.
  double _distanceInKm = 0.0; // Calculated distance in kilometers.

  @override
  void initState() {
    super.initState();
    // Initialize distance controller text.
    _distanceController.text = '0.0';
  }

  @override
  void dispose() {
    // Dispose all text editing controllers to prevent memory leaks.
    _numberPlateController.dispose();
    _vehicleCapacityController.dispose();
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

  /// Handles item taps on the bottom navigation bar.
  /// Navigates to the corresponding route, replacing the current one.
  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Do nothing if already on the selected index.
    setState(() => _selectedIndex = index);
    Navigator.pushReplacementNamed(
      context,
      _pages[index],
    );
  }

  /// Allows the user to pick an image from the gallery.
  //Future<void> _pickImage() async {
   // final picker = ImagePicker();
   // final pickedFile = await picker.pickImage(source: ImageSource.gallery);

   // if (pickedFile != null) {
    //  setState(() {
      //  _selectedImage = File(pickedFile.path);
     // });
   // }
  //}

  /// Shows a time picker and updates the departure time controller with the selected time.
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF5A3D1F), // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Color(0xFF5A3D1F), // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF5A3D1F), // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _departureTimeController.text = picked.format(context);
      });
    }
  }

  /// Gets the current geographical location of the device.
  /// Updates the respective controller (pickup or dropoff) with the location name.
  Future<void> _getCurrentLocation(bool isPickup) async {
    if (!mounted) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location services are disabled')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;

      // Show a dialog with option to open settings if permissions are permanently denied.
      bool? openSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Permission Required'),
          content: Text(
            'Location permissions are permanently denied. Please enable them in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Open Settings'),
            ),
          ],
        ),
      );

      if (openSettings == true) {
        await Geolocator.openAppSettings();
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      if (!mounted) return;

      // First set the text to "Getting location..." while we fetch the address.
      setState(() {
        if (isPickup) {
          _pickupLatLng = LatLng(position.latitude, position.longitude);
          _pickupController.text = "Getting location...";
        } else {
          _dropoffLatLng = LatLng(position.latitude, position.longitude);
          _dropoffController.text = "Getting location...";
        }
      });

      // Get the actual address name from coordinates.
      final address = await getLocationName(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        if (isPickup) {
          _pickupController.text = address;
        } else {
          _dropoffController.text = address;
        }
      });

      _calculateDistance(); // Recalculate distance after updating location.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: ${e.toString()}')),
      );
    }
  }

  /// Converts latitude and longitude coordinates to a human-readable address.
  Future<String> getLocationName(double lat, double lon) async {
    try {
      final places = await placemarkFromCoordinates(lat, lon);
      if (places.isNotEmpty) {
        final place = places.first;
        // Concatenate relevant address parts.
        return [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].where((part) => part?.isNotEmpty ?? false).join(', ');
      }
      return 'Current Location'; // Fallback if no places found.
    } catch (e) {
      return 'Current Location'; // Fallback on error.
    }
  }

  /// Navigates to a map screen to allow the user to select a location.
  Future<void> _selectOnMap(bool isPickup) async {
    try {
      // Expects a LatLng result from the '/map' route.
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

        _calculateDistance(); // Recalculate distance after map selection.
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting location: ${e.toString()}')),
      );
    }
  }

  /// Calculates the distance between the pickup and dropoff points.
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
        _distanceController.text = distance.toStringAsFixed(1); // Display with one decimal place.
      });
    } else {
      setState(() {
        _distanceInKm = 0.0;
        _distanceController.text = '0.0';
      });
    }
  }

  /// Calculates the distance between two geographical coordinates using the Haversine formula.
  double _coordinateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = pi / 180; // Convert degrees to radians.
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 12742 is (2 * R) where R is Earth's radius in km.
  }

  /// Uploads the new ride data to Supabase.
  Future<void> _uploadRideData() async {
    if (!_formKey.currentState!.validate()) return; // Validate form inputs.

    setState(() {
      _isLoading = true; // Show loading indicator.
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      String? imageUrl;
      if (_selectedImage != null) {
        final filePath = 'rides/${DateTime.now().millisecondsSinceEpoch}.jpg';
        // Upload image to Supabase storage.
        await _supabase.storage.from('ride_images').upload(filePath, _selectedImage!);
        imageUrl = _supabase.storage.from('ride_images').getPublicUrl(filePath);
      }

      final capacity = int.parse(_capacityController.text); // Parse capacity to integer.

      // Insert ride data into the 'ride' table.
      await _supabase.from('ride').insert({
        'ride_number': _rideNumberController.text,
        'capacity': capacity,
        'remaining_capacity': capacity, // Initially, remaining capacity is full capacity.
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
        'driver_id': userId,
      //  'image_url': imageUrl, // Include the image URL if it exists.
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ride added successfully!')),
      );
      _clearForm(); // Clear the form after successful submission.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding ride: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator.
      });
    }
  }

  /// Clears all input fields and resets state variables.
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

  /// Shows a confirmation dialog for logging out.
  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Logout",
            style: TextStyle(
              color: Color(0xFF5A3D1F),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Are you sure you want to logout?",
            style: TextStyle(color: Colors.grey[700]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel", style: TextStyle(color: Color(0xFF5A3D1F))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5A3D1F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout();
              },
              child: Text("Logout", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// Logs out the current user and navigates to the login screen.
  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      // Navigate to login screen and remove all previous routes.
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Shows a modal bottom sheet with profile menu options.
  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 5,
                margin: EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              _buildMenuOption(
                icon: Icons.person,
                title: "Profile",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              Divider(height: 20, color: Colors.grey[200]),
              _buildMenuOption(
                icon: Icons.logout,
                title: "Logout",
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog();
                },
                isLogout: true,
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  /// Helper widget to build a menu option for the profile bottom sheet.
  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Color(0xFF5A3D1F)),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : Color(0xFF5A3D1F),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  /// Helper widget to build a general text input field.
  Widget _buildInputField(
    BuildContext context,
    IconData icon,
    String label,
    TextEditingController controller,
    TextInputType keyboardType,
    String? Function(String?)? validator, {
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
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
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Color(0xFF5A3D1F)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
              hintText: 'Enter $label',
              hintStyle: TextStyle(color: Colors.grey[500]),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  /// Helper widget to build a dropdown selection field.
  Widget _buildDropdownField(
    String label,
    String? selectedValue,
    ValueChanged<String?> onChanged, {
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
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
          DropdownButtonFormField<String>(
            value: selectedValue,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.category, color: Color(0xFF5A3D1F)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
              hintText: 'Select $label',
              hintStyle: TextStyle(color: Colors.grey[500]),
            ),
            items: _vehicleTypes.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: onChanged,
            validator: validator,
          ),
        ],
      ),
    );
  }

  /// Helper widget to build a location input field with map and current location options.
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
                itemBuilder: (context, suggestion) => ListTile(title: Text(suggestion)),
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
                        if (isPickup) // Only show "Use current location" for pickup.
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

  /// Builds the custom bottom navigation bar.
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
          icon: Icon(Icons.add_circle_outline),
          activeIcon: Icon(Icons.add_circle),
          label: "Add Ride",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history),
          label: "Records",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined),
          activeIcon: Icon(Icons.account_balance_wallet),
          label: "Fund Account",
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false, // No back button on this main screen.
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isAddRideSelected ? "Add Ride" : "Available Rides", // Dynamic title
          style: TextStyle(
            color: Color(0xFF5A3D1F),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Color(0xFF5A3D1F)),
            onPressed: () {
              // TODO: Implement notification functionality.
            },
          ),
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: _showProfileMenu,
              child: CircleAvatar(
                backgroundColor: Color(0xFF5A3D1F).withOpacity(0.1),
                child: Icon(Icons.person, color: Color(0xFF5A3D1F)),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Color(0xFF5A3D1F)),
            )
          : Column( // Use Column to hold the tabs and the content
              children: [
                // Tabs for Add Ride and Available Rides
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
                  margin: EdgeInsets.all(16), // Add margin for the tab container
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isAddRideSelected = true; // Select "Add Ride"
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: _isAddRideSelected
                                  ? Color(0xFF8B5E3B).withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "Add Ride",
                                style: TextStyle(
                                  color: _isAddRideSelected
                                      ? Color(0xFF5A3D1F)
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isAddRideSelected = false; // Select "Available Rides"
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: !_isAddRideSelected
                                  ? Color(0xFF8B5E3B).withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "Available Rides",
                                style: TextStyle(
                                  color: !_isAddRideSelected
                                      ? Color(0xFF5A3D1F)
                                      : Colors.grey[600],
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
                // Conditional content based on selected tab
                Expanded( // Use Expanded to make the content fill the remaining space
                  child: _isAddRideSelected
                      ? SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 16), // Adjust padding as tabs have margin
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                              //  // Add Photos Button
                              //  GestureDetector(
                              //    onTap: _pickImage,
                              //    child: Container(
                              //      width: double.infinity,
                              //      padding: EdgeInsets.all(20),
                              //      decoration: BoxDecoration(
                              //        color: Colors.white,
                              //        borderRadius: BorderRadius.circular(12),
                              //        boxShadow: [
                              //          BoxShadow(
                              //            color: Colors.black26,
                              //            blurRadius: 10,
                              //            offset: Offset(0, 5),
                              //          ),
                              //        ],
                              //      ),
                              //      child: Column(
                              //        children: [
                              //          if (_selectedImage != null)
                              //            Container(
                              //              height: 120,
                              //              width: 120,
                              //              decoration: BoxDecoration(
                              //                image: DecorationImage(
                              //                  image: FileImage(_selectedImage!),
                              //                  fit: BoxFit.cover,
                              //                ),
                              //                borderRadius: BorderRadius.circular(8),
                              //              ),
                              //            )
                              //          else
                              //            Container(
                              //              height: 80,
                              //              width: 80,
                              //              decoration: BoxDecoration(
                              //                color: Color(0xFF8B5E3B).withOpacity(0.1),
                              //                borderRadius: BorderRadius.circular(40),
                              //              ),
                              //              child: Icon(
                              //                Icons.add_a_photo,
                              //                color: Color(0xFF5A3D1F),
                              //                size: 40,
                              //              ),
                              //            ),
                              //          SizedBox(height: 10),
                              //          Text(
                              //            _selectedImage != null
                              //                ? "Change Photo"
                              //                : "Add Photos",
                              //            style: TextStyle(
                              //              color: Color(0xFF5A3D1F),
                              //              fontWeight: FontWeight.bold,
                              //            ),
                              //          ),
                              //        ],
                              //      ),
                              //    ),
                              //  ),
//
                              //  
                              //  SizedBox(height: 20),

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
                                    if (value == null || value.isEmpty || double.parse(value) == 0.0) {
                                      return 'Please select both locations to calculate distance';
                                    }
                                    return null;
                                  },
                                  readOnly: true,
                                ),

                                // Departure Time (Time picker)
                                _buildInputField(
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
                                  readOnly: true, // Make it read-only as it's set by the time picker
                                  onTap: () => _selectTime(context), // Open time picker on tap
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
                                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                      return 'Please enter a valid number greater than 0';
                                    }
                                    return null;
                                  },
                                ),

                                // Total Cost (Numbers only, decimal allowed)
                                _buildInputField(
                                  context,
                                  Icons.attach_money,
                                  "Total Cost",
                                  _totalCostController,
                                  TextInputType.numberWithOptions(decimal: true),
                                  (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter total cost';
                                    }
                                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                      return 'Please enter a valid cost greater than 0';
                                    }
                                    return null;
                                  },
                                ),

                                // Contact (Phone number)
                                _buildInputField(
                                  context,
                                  Icons.phone,
                                  "Contact Number",
                                  _contactController,
                                  TextInputType.phone,
                                  (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter contact number';
                                    }
                                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                      return 'Please enter numbers only';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: 20),

                                // Add Ride Button
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _uploadRideData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF5A3D1F),
                                    padding: EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    minimumSize: Size(double.infinity, 50), // Full width button
                                  ),
                                  child: _isLoading
                                      ? CircularProgressIndicator(color: Colors.white)
                                      : Text(
                                          "Add Ride",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                                SizedBox(height: 20),
                              ],
                            ),
                          ),
                        )
                      : AvailableDriverRides(), // Show AvailableDriverRides when the other tab is selected
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomNavBar(), // Use the new build method for the bottom navigation bar
    );
  }
}
