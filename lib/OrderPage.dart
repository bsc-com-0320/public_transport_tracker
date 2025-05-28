import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:public_transport_tracker/available_rides_page.dart';
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
  bool _isProcessingBooking = false;

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
  final List<String> _pages = [
    '/home',
    '/order',
    '/records',
    '/s-fund-account',
  ];

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
      print(
        'Dropoff: ${_dropoffLatLng!.latitude},${_dropoffLatLng!.longitude}',
      );

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
            const SnackBar(
              content: Text('No route found between these points'),
            ),
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

        return {'distance': distance, 'duration': duration, 'points': points};
      } else {
        print('OSRM API error: ${response.statusCode}');
        if (!mounted) return {};
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Routing service error: ${response.statusCode}'),
          ),
        );
        return {};
      }
    } catch (e) {
      print('Routing error: $e');
      if (!mounted) return {};
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to calculate route. Please try again'),
        ),
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
      // First get user's current location
      Position? userPosition;
      try {
        userPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
      } catch (e) {
        print("Error getting user position: $e");
      }

      // Fetch all rides
      var query = supabase.from('ride').select('*');

      if (_selectedVehicleType != null && _selectedVehicleType != 'All') {
        query = query.eq('vehicle_type', _selectedVehicleType!);
      }

      final response = await query.order('departure_time', ascending: true);

      List<Map<String, dynamic>> rides = List<Map<String, dynamic>>.from(
        response,
      );

      // If we have user location, sort by proximity
      if (userPosition != null) {
        rides = await _sortRidesByProximity(rides, userPosition);
      }

      setState(() {
        availableRides = rides;
        isLoadingRides = false;
      });
    } catch (e) {
      setState(() => isLoadingRides = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading rides: $e')));
    }
  }

  Future<List<Map<String, dynamic>>> _sortRidesByProximity(
    List<Map<String, dynamic>> rides,
    Position userPosition,
  ) async {
    // Create a list of rides with their distance from user
    List<Map<String, dynamic>> ridesWithDistance = [];

    for (var ride in rides) {
      try {
        // Get pickup coordinates from ride
        double? pickupLat = ride['pickup_lat']?.toDouble();
        double? pickupLng = ride['pickup_lng']?.toDouble();

        if (pickupLat == null || pickupLng == null) {
          // If no coordinates, try to geocode the address
          if (ride['pickup_point'] != null) {
            List<Location> locations = await locationFromAddress(
              ride['pickup_point'],
            );
            if (locations.isNotEmpty) {
              pickupLat = locations.first.latitude;
              pickupLng = locations.first.longitude;
            }
          }
        }

        // Calculate distance if we have coordinates
        if (pickupLat != null && pickupLng != null) {
          double distance = _coordinateDistance(
            userPosition.latitude,
            userPosition.longitude,
            pickupLat,
            pickupLng,
          );

          ridesWithDistance.add({...ride, 'distance_from_user': distance});
        } else {
          // If no coordinates, assign a large distance
          ridesWithDistance.add({
            ...ride,
            'distance_from_user': double.maxFinite,
          });
        }
      } catch (e) {
        print("Error calculating distance for ride: $e");
        ridesWithDistance.add({
          ...ride,
          'distance_from_user': double.maxFinite,
        });
      }
    }

    // Sort by distance (nearest first)
    ridesWithDistance.sort(
      (a, b) => (a['distance_from_user'] as double).compareTo(
        b['distance_from_user'] as double,
      ),
    );

    return ridesWithDistance;
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A3D1F),
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
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
                child: TypeAheadField<String>(
                  controller: _pickupController,
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
                      final url = Uri.parse(
                        "https://nominatim.openstreetmap.org/search?format=json&q=$pattern&limit=5",
                      );
                      final response = await http.get(url);
                      if (response.statusCode == 200) {
                        final data = json.decode(response.body) as List;
                        return data
                            .map<String>(
                              (item) => item['display_name'] as String,
                            )
                            .toList();
                      }
                      return [];
                    } catch (e) {
                      return [];
                    }
                  },
                  itemBuilder:
                      (context, suggestion) =>
                          ListTile(title: Text(suggestion)),
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
                      _drawRoute();
                    }
                  },
                ),
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
                    builder:
                        (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: Icon(Icons.my_location),
                              title: Text("Use current location"),
                              onTap: () {
                                Navigator.pop(context);
                                _getCurrentLocation();
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.map),
                              title: Text("Select on map"),
                              onTap: () {
                                Navigator.pop(context);
                                _selectPickup();
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

  Widget _buildDropoffField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Dropoff point",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A3D1F),
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
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
                child: TypeAheadField<String>(
                  controller: _dropoffController,
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
                      final url = Uri.parse(
                        "https://nominatim.openstreetmap.org/search?format=json&q=$pattern&limit=5",
                      );
                      final response = await http.get(url);
                      if (response.statusCode == 200) {
                        final data = json.decode(response.body) as List;
                        return data
                            .map<String>(
                              (item) => item['display_name'] as String,
                            )
                            .toList();
                      }
                      return [];
                    } catch (e) {
                      return [];
                    }
                  },
                  itemBuilder:
                      (context, suggestion) =>
                          ListTile(title: Text(suggestion)),
                  onSelected: (suggestion) async {
                    _dropoffController.text = suggestion;
                    final coords = await _getCoordinatesFromAddress(suggestion);
                    if (coords != null) {
                      setState(() {
                        _dropoffLatLng = coords;
                        _markers.add(
                          Marker(
                            width: 80,
                            height: 80,
                            point: coords,
                            builder:
                                (ctx) => Tooltip(
                                  message: 'Dropoff',
                                  child: Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                          ),
                        );
                      });
                      _drawRoute();
                    }
                  },
                ),
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
                    builder:
                        (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: Icon(Icons.map),
                              title: Text("Select on map"),
                              onTap: () {
                                Navigator.pop(context);
                                _selectDropoff();
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

  Widget _buildDateTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select date & time",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A3D1F),
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDateTime,
          child: AbsorbPointer(
            child: Container(
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
              child: TextField(
                controller: _dateTimeController,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.calendar_today,
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
                  hintText: 'Select date and time',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                ),
              ),
            ),
          ),
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
      if (routeInfo.isEmpty ||
          routeInfo['distance'] == null ||
          routeInfo['duration'] == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not calculate route information'),
          ),
        );
        return;
      }

      final distance = routeInfo['distance']?.toDouble() ?? 0.0;
      final duration = routeInfo['duration']?.toDouble() ?? 0.0;
      final routePoints = routeInfo['points'] as List<LatLng>? ?? [];

      // Ensure we have valid coordinates
      if (_pickupLatLng == null && _pickupController.text.isNotEmpty) {
        _pickupLatLng = await _getCoordinatesFromAddress(
          _pickupController.text,
        );
        if (!mounted) return;
      }
      if (_dropoffLatLng == null && _dropoffController.text.isNotEmpty) {
        _dropoffLatLng = await _getCoordinatesFromAddress(
          _dropoffController.text,
        );
        if (!mounted) return;
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => AvailableRidesPage(
                availableRides: availableRides,
                isLoadingRides: isLoadingRides,
                pickupLatLng: _pickupLatLng,
                dropoffLatLng: _dropoffLatLng,
                routePoints: routePoints,
                distanceInKm: distance,
                duration: duration,
                onBookRide: _bookRide,
                isOrderActive: isOrderActive,
                selectedVehicleType: _selectedVehicleType,
              ),
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

  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Logout",
            style: TextStyle(
              color: Color(0xFF5A3D1F),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "Are you sure you want to logout?",
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Color(0xFF5A3D1F)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A3D1F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout();
              },
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
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

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 5,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF5A3D1F)),
                title: const Text(
                  "Profile",
                  style: TextStyle(
                    color: Color(0xFF5A3D1F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Assuming you have a '/profile' route, otherwise update this
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              const Divider(height: 20, color: Colors.grey),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  _showLogoutDialog(); // Show the confirmation dialog
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading:
            false, // Prevents a back button if you don't want one
        backgroundColor: Colors.white, // Set AppBar background to white
        elevation: 0, // Remove shadow
        title: const Text(
          "Order Ride", // Changed title for OrderPage
          style: TextStyle(
            color: Color(0xFF5A3D1F),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: Color(0xFF5A3D1F),
            ),
            onPressed: () {
              // Handle notifications tap
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap:
                  _showProfileMenu, // This calls the function to show the bottom sheet
              child: CircleAvatar(
                backgroundColor: const Color(0xFF5A3D1F).withOpacity(0.1),
                child: const Icon(Icons.person, color: Color(0xFF5A3D1F)),
              ),
            ),
          ),
        ],
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
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
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
                      inactiveThumbColor: Colors.grey[400],
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
                          color: Color(0xFF5A3D1F),
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
                                    label: Text(
                                      type,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Color(0xFF5A3D1F),
                                      ),
                                    ),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedVehicleType =
                                            selected ? type : null;
                                      });
                                    },
                                    selectedColor: Color(0xFF8B5E3B),
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: Color(
                                          0xFF5A3D1F,
                                        ).withOpacity(0.3),
                                      ),
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
                          color:
                              confirmationMessage.contains("Error")
                                  ? Colors.red
                                  : Colors.green,
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
          _buildConfirmButton(
            isOrderActive ? "View Rides to Request" : "View Rides to Book",
          ),
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
          _buildDateTimeField(),
          SizedBox(height: 24),
          _buildConfirmButton(
            isOrderActive ? "View Rides to Request" : "View Rides to Book",
          ),
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
      final distanceFromUser =
          ride['distance_from_user'] is double
              ? (ride['distance_from_user'] as double).toStringAsFixed(1)
              : 'N/A';

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
                      ride['pickup_point']?.toString() ?? 'No pickup specified',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.flag, color: Color(0xFF8B5E3B), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride['dropoff_point']?.toString() ??
                          'No dropoff specified',
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distance from you:',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '$distanceFromUser km',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B5E3B),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total Cost:', style: TextStyle(fontSize: 12)),
                      Text(
                        '\K${totalCost.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B5E3B),
                        ),
                      ),
                    ],
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
    return Container(
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
      child:
          isLoadingRides
              ? Center(child: CircularProgressIndicator())
              : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5A3D1F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  if (_selectedVehicleType == null) {
                    setState(
                      () =>
                          confirmationMessage = "Please select a vehicle type",
                    );
                    return;
                  }
                  if (_pickupController.text.isEmpty ||
                      _dropoffController.text.isEmpty) {
                    setState(
                      () =>
                          confirmationMessage =
                              "Please select pickup and dropoff locations",
                    );
                    return;
                  }
                  if (!isOrderActive && _dateTimeController.text.isEmpty) {
                    setState(
                      () => confirmationMessage = "Please select date and time",
                    );
                    return;
                  }

                  setState(() {
                    confirmationMessage = "";
                    isLoadingRides = true;
                  });
                  _loadAvailableRides().then((_) {
                    _showFullScreenMapWithRides();
                    setState(() => isLoadingRides = false);
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
              ),
    );
  }

  Future<void> _bookRide(Map<String, dynamic> ride) async {
    if (_isProcessingBooking) return; // Prevent multiple bookings

    setState(() => _isProcessingBooking = true); // Show loading

    // Show loading snackbar
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

    try {
      // Get the current user's ID
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (!mounted) return; // Check if the widget is still mounted
        throw Exception('User not logged in');
      }

      // Get the ride ID from the ride data
      final rideId = ride['id'];
      if (rideId == null) {
        if (!mounted) return;
        throw Exception('Ride ID not found');
      }

      // Extract the driver_id from the 'ride' map
      final String? driverId = ride['driver_id'] as String?;
      if (driverId == null) {
        if (!mounted) return;
        throw Exception(
          'Driver ID not found for this ride. Cannot book without a driver.',
        );
      }

      // Create booking data
      final bookingData = {
        'ride_id': rideId,
        'user_id': userId,
        'pickup_point':
            _pickupController
                .text, // Ensure this column exists in request_ride table
        'pickup_lat': _pickupLatLng?.latitude,
        'pickup_lng': _pickupLatLng?.longitude,
        'dropoff_point':
            _dropoffController
                .text, // Ensure this column exists in request_ride table
        'dropoff_lat': _dropoffLatLng?.latitude,
        'dropoff_lng': _dropoffLatLng?.longitude,
        'booking_time': DateTime.now().toIso8601String(),
        'departure_time': ride['departure_time'],
        'type': isOrderActive ? 'order' : 'book',
        'vehicle_type': _selectedVehicleType ?? ride['vehicle_type'],
        'total_cost': ride['total_cost'],
        'status': 'pending',
        'driver_id': driverId, // Explicitly add the driver_id here
      };

      // Insert booking into 'request_ride' table
      await supabase.from('request_ride').insert(bookingData);

      // Update ride capacity in 'ride' table
      if (ride['capacity'] != null && ride['capacity'] > 0) {
        print(
          'Attempting to decrement capacity for ride $rideId. Old: ${ride['capacity']}, New: ${ride['capacity'] - 1}',
        );
        try {
          await supabase
              .from('ride')
              .update({'capacity': ride['capacity'] - 1})
              .eq('id', rideId);
        } catch (updateError) {
          print('Supabase update failed for capacity decrement: $updateError');
          // You might want to handle this error more gracefully,
          // perhaps by rolling back the booking or notifying the user.
        }
      } else {
        print(
          'Ride capacity is null or not greater than 0. Not decrementing capacity.',
        );
      }

      if (!mounted) return;
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Ride booked successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Reload available rides to reflect capacity change
      _loadAvailableRides();

      // Optionally navigate back after successful booking
      Navigator.pop(context);
    } on PostgrestException catch (e) {
      print('Failed to book ride: $e');
      if (!mounted) return;
      String errorMessage = 'Failed to book ride. Please try again.';
      if (e.code == '23502') {
        errorMessage =
            'Missing required information. Check if all fields are filled.';
      } else if (e.message?.contains("'driver_id' column") == true) {
        errorMessage =
            'Driver information is missing or invalid. Please select another ride.';
      } else if (e.message?.contains("'dropoff_point' column") == true) {
        errorMessage =
            "Database error: 'dropoff_point' column missing. Please contact support.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Unexpected error booking ride: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ An unexpected error occurred: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isProcessingBooking = false); // Hide loading
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
