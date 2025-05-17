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
  bool isOrderActive = true;
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  DateTime? selectedDate;

  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  GoogleMapController? _mapController;
  bool _isMapVisible = false;
  bool _selectingPickup = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: Color(0xFF8B5E3B),
        title: Text("Order", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/check'),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildToggleButton("Order", isOrderActive, () {
                    setState(() {
                      isOrderActive = true;
                    });
                  }),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildToggleButton("Book", !isOrderActive, () {
                    setState(() {
                      isOrderActive = false;
                    });
                  }),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: isOrderActive ? buildOrderContent() : buildBookContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLocationField("Pickup Point", _pickupController, true),
        _buildLocationField("Dropoff Point", _dropoffController, false),
        if (_isMapVisible) _buildMapSection(),
        SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            onPressed: () {
              if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Please select pickup and dropoff points"))
                );
              } else {
                Navigator.pushNamed(context, '/accounts');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8B5E3B),
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
            child: Text("Order Now", style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget buildBookContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _selectDateTime(context),
          child: AbsorbPointer(
            child: _buildTextField("Select Date & Time", _dateTimeController),
          ),
        ),
        _buildLocationField("Pickup Point", _pickupController, true),
        _buildLocationField("Dropoff Point", _dropoffController, false),
        if (_isMapVisible) _buildMapSection(),
        SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            onPressed: () {
              if (_pickupController.text.isEmpty || 
                  _dropoffController.text.isEmpty || 
                  _dateTimeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Please fill all fields"))
                );
              } else {
                Navigator.pushNamed(context, '/accounts');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8B5E3B),
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
            child: Text("Book Now", style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField(String label, TextEditingController controller, bool isPickup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.location_on),
                    onPressed: () async {
                      await _requestLocationPermission();
                      setState(() {
                        _isMapVisible = true;
                        _selectingPickup = isPickup;
                      });
                      _moveToCurrentLocation();
                    },
                  ),
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    controller.clear();
                    if (isPickup) {
                      _pickupLocation = null;
                    } else {
                      _dropoffLocation = null;
                    }
                  });
                },
              ),
          ],
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 300,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFF8B5E3B)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: GoogleMap(
          onMapCreated: (controller) => _mapController = controller,
          initialCameraPosition: CameraPosition(
            target: LatLng(0, 0), // Default position, will be updated
            zoom: 14,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          markers: _buildMarkers(),
          onTap: (LatLng location) => _handleMapTap(location),
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};
    if (_pickupLocation != null) {
      markers.add(Marker(
        markerId: MarkerId('pickup'),
        position: _pickupLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Pickup Point'),
      ));
    }
    if (_dropoffLocation != null) {
      markers.add(Marker(
        markerId: MarkerId('dropoff'),
        position: _dropoffLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Dropoff Point'),
      ));
    }
    return markers;
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location services are disabled. Please enable them.'))
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are denied'))
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permissions are permanently denied. Please enable them in app settings.'))
      );
      return;
    }
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get current location: $e'))
      );
    }
  }

  Future<void> _handleMapTap(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = '${place.street}, ${place.locality}, ${place.country}';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get address: $e'))
      );
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      
      if (pickedTime != null) {
        setState(() {
          selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _dateTimeController.text = "${pickedDate.toLocal()}".split(' ')[0] + 
            " at ${pickedTime.format(context)}";
        });
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        SizedBox(height: 10),
      ],
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