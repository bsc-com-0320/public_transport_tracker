// OrderPage.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class OrderPage extends StatefulWidget {
  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  // Constants
  static const _primaryColor = Color(0xFF8B5E3B);
  static const _backgroundColor = Color(0xFFF5F5DC);
  static const _buttonPadding = EdgeInsets.symmetric(horizontal: 40, vertical: 12);
  static const _defaultMapZoom = 14.0;

  // State variables
  bool _isOrderActive = true;
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  
  DateTime? _selectedDate;
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  GoogleMapController? _mapController;
  bool _isMapVisible = false;
  bool _selectingPickup = true;
  bool _isLoadingLocation = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildOrderTypeToggle(),
            const SizedBox(height: 20),
            Expanded(
              child: _isOrderActive ? _buildOrderContent() : _buildBookContent(),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _primaryColor,
      title: const Text("Order", style: TextStyle(color: Colors.white)),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () => Navigator.pushNamed(context, '/check'),
        ),
      ],
    );
  }

  Widget _buildOrderTypeToggle() {
    return Row(
      children: [
        Expanded(
          child: _buildToggleButton(
            "Order",
            _isOrderActive,
            () => setState(() => _isOrderActive = true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildToggleButton(
            "Book",
            !_isOrderActive,
            () => setState(() => _isOrderActive = false),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? _primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
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

  Widget _buildOrderContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationField("Pickup Point", _pickupController, true),
          _buildLocationField("Dropoff Point", _dropoffController, false),
          if (_isMapVisible) _buildMapSection(),
          const SizedBox(height: 20),
          _buildActionButton(
            "Order Now",
            _validateOrderFields,
          ),
        ],
      ),
    );
  }

  Widget _buildBookContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateTimeField(),
          _buildLocationField("Pickup Point", _pickupController, true),
          _buildLocationField("Dropoff Point", _dropoffController, false),
          if (_isMapVisible) _buildMapSection(),
          const SizedBox(height: 20),
          _buildActionButton(
            "Book Now",
            _validateBookingFields,
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeField() {
    return GestureDetector(
      onTap: () => _selectDateTime(context),
      child: AbsorbPointer(
        child: _buildTextField(
          "Select Date & Time",
          _dateTimeController,
          Icons.calendar_today,
        ),
      ),
    );
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
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: _isLoadingLocation && _selectingPickup == isPickup
                      ? const CircularProgressIndicator()
                      : IconButton(
                          icon: const Icon(Icons.location_on),
                          onPressed: () => _handleLocationSelection(isPickup),
                        ),
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _clearLocation(controller, isPickup),
              ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 300,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primaryColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: GoogleMap(
          onMapCreated: (controller) => _mapController = controller,
          initialCameraPosition: const CameraPosition(
            target: LatLng(0, 0),
            zoom: _defaultMapZoom,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          markers: _buildMarkers(),
          onTap: _handleMapTap,
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return Center(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          padding: _buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData? icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            suffixIcon: icon != null ? Icon(icon) : null,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    
    if (_pickupLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup Point'),
      ));
    }
    
    if (_dropoffLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: _dropoffLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Dropoff Point'),
      ));
    }
    
    return markers;
  }

  Future<void> _handleLocationSelection(bool isPickup) async {
    setState(() {
      _selectingPickup = isPickup;
      _isLoadingLocation = true;
    });

    try {
      await _requestLocationPermission();
      setState(() => _isMapVisible = true);
      await _moveToCurrentLocation();
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _requestLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Location services are disabled. Please enable them.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar(
        'Location permissions are permanently denied. Please enable them in app settings.',
      );
    }
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      await _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    } catch (e) {
      _showSnackBar('Could not get current location: ${e.toString()}');
    }
  }

  Future<void> _handleMapTap(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = '${place.street}, ${place.locality}, ${place.country}';

        setState(() {
          if (_selectingPickup) {
            _pickupLocation = location;
            _pickupController.text = address;
          } else {
            _dropoffLocation = location;
            _dropoffController.text = address;
          }
          _isMapVisible = false;
        });
      }
    } catch (e) {
      _showSnackBar('Could not get address: ${e.toString()}');
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (pickedTime != null) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        _dateTimeController.text = 
          "${pickedDate.toLocal()}".split(' ')[0] + 
          " at ${pickedTime.format(context)}";
      });
    }
  }

  void _clearLocation(TextEditingController controller, bool isPickup) {
    setState(() {
      controller.clear();
      if (isPickup) {
        _pickupLocation = null;
      } else {
        _dropoffLocation = null;
      }
    });
  }

  void _validateOrderFields() {
    if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
      _showSnackBar("Please select pickup and dropoff points");
    } else {
      Navigator.pushNamed(context, '/accounts');
    }
  }

  void _validateBookingFields() {
    if (_pickupController.text.isEmpty || 
        _dropoffController.text.isEmpty || 
        _dateTimeController.text.isEmpty) {
      _showSnackBar("Please fill all fields");
    } else {
      Navigator.pushNamed(context, '/accounts');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _dateTimeController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}