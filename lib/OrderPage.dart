import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_map/flutter_map.dart';

class OrderPage extends StatefulWidget {
  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  late TextEditingController _pickupController;
  late TextEditingController _dropoffController;
  late TextEditingController _dateTimeController;
  late MapController _mapController;

  DateTime? selectedDateTime;
  bool isOrderActive = true;
  String confirmationMessage = "";
  bool showAvailableRides = false;
  List<Map<String, dynamic>> availableRides = [];
  bool isLoadingRides = false;
  List<LatLng> _routePoints = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  double _distanceInKm = 0.0;
  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;

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

  @override
  void initState() {
    super.initState();
    _pickupController = TextEditingController();
    _dropoffController = TextEditingController();
    _dateTimeController = TextEditingController();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _dateTimeController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pushNamed(context, _pages[index]);
  }

Future<Map<String, dynamic>> _drawRoute() async {
  if (!mounted) return {};

  try {
    // Validate coordinates
    if (_pickupLatLng == null || _dropoffLatLng == null) {
      if (!mounted) return {};
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both locations')),
      );
      return {};
    }

    print('Calculating route between:');
    print('Pickup: ${_pickupLatLng!.latitude},${_pickupLatLng!.longitude}');
    print('Dropoff: ${_dropoffLatLng!.latitude},${_dropoffLatLng!.longitude}');

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${_pickupLatLng!.longitude},${_pickupLatLng!.latitude};'
      '${_dropoffLatLng!.longitude},${_dropoffLatLng!.latitude}'
      '?overview=full&alternatives=false&steps=false',
    );

    print('OSRM API URL: $url');

    final response = await http.get(url).timeout(const Duration(seconds: 15));

    print('OSRM Response: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (!mounted) return {};

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['routes'] == null || data['routes'].isEmpty) {
        print('No routes found in response');
        if (!mounted) return {};
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No route found between these points')),
        );
        return {};
      }

      final route = data['routes'][0];
      final geometry = route['geometry'];
      final distance = route['distance'] / 1000; // km
      final duration = route['duration'] / 60; // minutes

      print('Route calculated: $distance km, $duration mins');

      final points = _decodePolyline(geometry);
      if (points.isEmpty) {
        print('Decoded polyline is empty');
        return {};
      }

      if (!mounted) return {};

      setState(() {
        _routePoints = points;
        _distanceInKm = distance;
        _polylines = {
          Polyline(
            points: points,
            color: Colors.blue.withOpacity(0.7),
            strokeWidth: 4.0,
          ),
        };
      });

      return {
        'distance': distance,
        'duration': duration,
        'points': points,
      };
    } else {
      print('OSRM API error: ${response.statusCode}');
      if (!mounted) return {};
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Routing service error: ${response.statusCode}')),
      );
      return {};
    }
  } catch (e) {
    print('Routing error: $e');
    if (!mounted) return {};
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to calculate route. Please try again')),
    );
    return {};
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

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
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
    if (!mounted) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Location services are disabled')));
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permissions are permanently denied')),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      if (!mounted) return;

      // First set the text to "Getting location..." while we fetch the address
      setState(() {
        _pickupLatLng = LatLng(position.latitude, position.longitude);
        _pickupController.text = "Getting location...";
      });

      // Get the actual address name
      final address = await getLocationName(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _pickupController.text = address;

        // Clear existing pickup marker by type
        _markers.removeWhere((marker) {
          final child = marker.builder(context);
          return child is Tooltip && child.message == 'Pickup';
        });

        _markers.add(
          Marker(
            width: 80,
            height: 80,
            point: _pickupLatLng!,
            builder:
                (context) => Tooltip(
                  message: 'Pickup',
                  child: Icon(
                    Icons.location_pin,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
          ),
        );
      });

      if (_dropoffLatLng != null && mounted) {
        await _drawRoute();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: ${e.toString()}')),
      );
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
                itemBuilder:
                    (context, suggestion) => ListTile(title: Text(suggestion)),
                onSelected: (suggestion) async {
                  _pickupController.text = suggestion;
                  final coords = await _getCoordinatesFromAddress(suggestion);
                  if (coords != null) {
                    setState(() {
                      _pickupLatLng = coords;
                      _markers.add(
                        Marker(
                          width: 80,
                          height: 80,
                          point: coords,
                          builder:
                              (ctx) => Tooltip(
                                message: 'Pickup',
                                child: Icon(
                                  Icons.location_pin,
                                  color: Colors.green,
                                  size: 40,
                                ),
                              ),
                        ),
                      );
                    });
                    _drawRoute(); // Draw route immediately after setting coordinates
                  }
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

  Widget _buildDropoffField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Dropoff point",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TypeAheadField<String>(
                controller: _dropoffController,
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
                itemBuilder:
                    (context, suggestion) => ListTile(title: Text(suggestion)),
                onSelected: (suggestion) async {
                  _dropoffController.text = suggestion;
                  _dropoffLatLng = await _getCoordinatesFromAddress(suggestion);
                },
              ),
            ),
            SizedBox(width: 8),
            PopupMenuButton(
              icon: Icon(Icons.more_vert, color: Color(0xFF8B5E3B)),
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      child: Text("Select on map"),
                      onTap: () => _selectDropoff(),
                    ),
                  ],
            ),
          ],
        ),
      ],
    );
  }

  void _selectPickup() async {
    try {
      final result = await Navigator.pushNamed(context, '/map') as LatLng?;
      if (result != null) {
        setState(() {
          _pickupLatLng = result;
          _pickupController.text = "Getting location...";
        });

        final locationName = await getLocationName(
          result.latitude,
          result.longitude,
        );
        setState(() {
          _pickupController.text = locationName;
        });

        // Draw route if dropoff is already set
        if (_dropoffLatLng != null) {
          await _drawRoute();
        }
      }
    } catch (e) {
      print("Error selecting pickup: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error selecting pickup location")),
      );
    }
  }

  void _selectDropoff() async {
    try {
      final result = await Navigator.pushNamed(context, '/map') as LatLng?;
      if (result != null) {
        setState(() {
          _dropoffLatLng = result;
          _dropoffController.text = "Getting location...";
        });

        final locationName = await getLocationName(
          result.latitude,
          result.longitude,
        );
        setState(() {
          _dropoffController.text = locationName;
        });

        // Draw route if pickup is already set
        if (_pickupLatLng != null) {
          await _drawRoute();
        }
      }
    } catch (e) {
      print("Error selecting dropoff: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error selecting dropoff location")),
      );
    }
  }

void _showFullScreenMapWithRides() async {
  try {
    // First draw the route and get the distance/duration
    final routeInfo = await _drawRoute();
    if (!mounted) return;

    // Ensure we have valid route information
    if (routeInfo.isEmpty || routeInfo['distance'] == null || routeInfo['duration'] == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not calculate route information')),
      );
      return;
    }

    final distance = routeInfo['distance']?.toStringAsFixed(1) ?? '0.0';
    final duration = routeInfo['duration']?.toStringAsFixed(0) ?? '0';
    final routePoints = routeInfo['points'] as List<LatLng>? ?? [];

    // Ensure we have valid coordinates
    if (_pickupLatLng == null && _pickupController.text.isNotEmpty) {
      _pickupLatLng = await _getCoordinatesFromAddress(_pickupController.text);
      if (!mounted) return;
    }
    if (_dropoffLatLng == null && _dropoffController.text.isNotEmpty) {
      _dropoffLatLng = await _getCoordinatesFromAddress(_dropoffController.text);
      if (!mounted) return;
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          // Create a new MapController for the new route
          final mapController = MapController();
          
          // Fit bounds to the route if we have points
          if (routePoints.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              mapController.fitBounds(
                LatLngBounds.fromPoints(routePoints),
                options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
              );
            });
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Available Rides'),
              backgroundColor: const Color(0xFF8B5E3B),
            ),
            body: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    center: _pickupLatLng ?? LatLng(-15.7861, 35.0058),
                    zoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    if (_pickupLatLng != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 80,
                            height: 80,
                            point: _pickupLatLng!,
                            builder: (ctx) => const Tooltip(
                              message: 'Pickup',
                              child: Icon(
                                Icons.location_pin,
                                color: Colors.green,
                                size: 40,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (_dropoffLatLng != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 80,
                            height: 80,
                            point: _dropoffLatLng!,
                            builder: (ctx) => const Tooltip(
                              message: 'Dropoff',
                              child: Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            color: Colors.blue,
                            strokeWidth: 4.0,
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Route Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Distance:'),
                              Text('$distance km'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Approximate Time:'),
                              Text('$duration mins'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                DraggableScrollableSheet(
                  initialChildSize: 0.3,
                  minChildSize: 0.2,
                  maxChildSize: 0.7,
                  builder: (BuildContext context, ScrollController scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Available Rides',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: isLoadingRides
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : availableRides.isEmpty
                                    ? const Center(
                                        child: Text('No available rides found'),
                                      )
                                    : ListView.builder(
                                        controller: scrollController,
                                        padding: const EdgeInsets.all(16),
                                        itemCount: availableRides.length,
                                        itemBuilder: (context, index) {
                                          final ride = availableRides[index];
                                          try {
                                            return _buildRideCard(ride);
                                          } catch (e) {
                                            return _buildErrorCard(
                                              e.toString(),
                                            );
                                          }
                                        },
                                      ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error showing rides: ${e.toString()}'),
        duration: const Duration(seconds: 2),
      ),
    );
    print('Error in _showFullScreenMapWithRides: $e');
  }
}

  Future<LatLng?> _getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        return LatLng(loc.latitude, loc.longitude);
      }
    } catch (e) {
      print("Error getting coordinates: $e");
    }
    return null;
  }

  Future<LatLng?> _getCoordinates(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      print("Error getting coordinates: $e");
    }
    return null;
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
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 20),
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
                  Expanded(
                    child:
                        isOrderActive
                            ? _buildOrderContent()
                            : _buildBookContent(),
                  ),
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
          _buildPickupField(),
          SizedBox(height: 16),
          _buildDropoffField(),
          SizedBox(height: 16),
          _buildConfirmButton("View Rides to Request"),
        ],
      ),
    );
  }

  Widget _buildBookContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildPickupField(),
          SizedBox(height: 16),
          _buildDropoffField(),
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

  Widget _buildRideCard(Map<String, dynamic> ride) {
    try {
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

  // Update your _buildConfirmButton method to use this new function
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
          _loadAvailableRides().then((_) {
            _showFullScreenMapWithRides();
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

      final bookingData = {
        'ride_id': ride['id'],
        'pickup': _pickupController.text,
        'dropoff': _dropoffController.text,
        'booking_time': DateTime.now().toIso8601String(),
        'type': isOrderActive ? 'order' : 'book',
        'vehicle_type': ride['vehicle_type'],
        'departure_time': departureTime.toIso8601String(),
        'total_cost': ride['total_cost'],
      };

      await supabase.from('request_ride').insert(bookingData);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('🎉 Ride booked successfully!')));

      if (ride['capacity'] > 0) {
        await supabase
            .from('ride')
            .update({'capacity': ride['capacity'] - 1})
            .eq('id', ride['id']);
      }

      _loadAvailableRides();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to book ride: ${e.toString()}')),
      );
    }
  }

  Future<String> getLocationName(double lat, double lon) async {
    try {
      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1",
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'YourAppName/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] != null) {
          print("Nominatim error: ${data['error']}");
          return "Current Location";
        }

        final address = data['address'];
        if (address != null) {
          // Try to build a meaningful address in this order
          final parts =
              [
                address['road'],
                address['neighbourhood'],
                address['suburb'],
                address['city'],
                address['county'],
                address['state'],
                address['country'],
              ].where((part) => part != null).toList();

          // Return the most specific address we can find
          if (parts.isNotEmpty) {
            return parts.take(3).join(', '); // Join first 3 meaningful parts
          }
        }
        return "Current Location";
      } else {
        print("Nominatim API error: ${response.statusCode}");
        return "Current Location";
      }
    } catch (e) {
      print("Error getting location name: $e");
      return "Current Location";
    }
  }
}
