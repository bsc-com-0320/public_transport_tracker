import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class RideSearchPage extends StatefulWidget {
  final LatLng userLocation;

  const RideSearchPage({Key? key, required this.userLocation}) : super(key: key);

  @override
  _RideSearchPageState createState() => _RideSearchPageState();
}

class _RideSearchPageState extends State<RideSearchPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _availableRides = [];
  bool _isLoading = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadAvailableRides();
  }

  Future<void> _loadAvailableRides() async {
    try {
      final response = await _supabase.from('ride').select('*');
      final rides = List<Map<String, dynamic>>.from(response);
      
      // Sort rides by proximity to user
      rides.sort((a, b) {
        final distanceA = _calculateDistanceToUser(a);
        final distanceB = _calculateDistanceToUser(b);
        return distanceA.compareTo(distanceB);
      });

      setState(() {
        _availableRides = rides;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading rides: ${e.toString()}')),
      );
    }
  }

  double _calculateDistanceToUser(Map<String, dynamic> ride) {
    try {
      final rideLat = ride['pickup_lat'] as double?;
      final rideLng = ride['pickup_lng'] as double?;
      
      if (rideLat == null || rideLng == null) {
        return double.infinity; // Put rides without location at the end
      }

      return _coordinateDistance(
        widget.userLocation.latitude,
        widget.userLocation.longitude,
        rideLat,
        rideLng,
      );
    } catch (e) {
      return double.infinity;
    }
  }

  double _coordinateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = pi / 180;
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // Returns distance in km
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Rides'),
        backgroundColor: Color(0xFF5A3D1F),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _availableRides.isEmpty
              ? Center(child: Text('No available rides found'))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _availableRides.length,
                  itemBuilder: (context, index) {
                    final ride = _availableRides[index];
                    final distance = _calculateDistanceToUser(ride);
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ride #${ride['ride_number']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text('Vehicle: ${ride['vehicle_type']}'),
                            Text('Capacity: ${ride['capacity']}'),
                            Text('Departure: ${ride['departure_time']}'),
                            Text('Pickup: ${ride['pickup_point']}'),
                            Text('Dropoff: ${ride['dropoff_point']}'),
                            SizedBox(height: 8),
                            Text(
                              'Distance: ${distance.toStringAsFixed(1)} km away',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}