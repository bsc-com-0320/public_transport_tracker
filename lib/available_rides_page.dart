import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AvailableRidesPage extends StatelessWidget {
  final List<Map<String, dynamic>> availableRides;
  final bool isLoadingRides;
  final LatLng? pickupLatLng;
  final LatLng? dropoffLatLng;
  final List<LatLng> routePoints;
  final double distanceInKm;
  final double duration;
  final Function(Map<String, dynamic>) onBookRide;
  final bool isOrderActive;
  final String? selectedVehicleType;

  const AvailableRidesPage({
    Key? key,
    required this.availableRides,
    required this.isLoadingRides,
    required this.pickupLatLng,
    required this.dropoffLatLng,
    required this.routePoints,
    required this.distanceInKm,
    required this.duration,
    required this.onBookRide,
    required this.isOrderActive,
    required this.selectedVehicleType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Rides'),
        backgroundColor: const Color(0xFF8B5E3B),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: pickupLatLng ?? LatLng(-15.7861, 35.0058),
              zoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              if (pickupLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80,
                      height: 80,
                      point: pickupLatLng!,
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
              if (dropoffLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80,
                      height: 80,
                      point: dropoffLatLng!,
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
                        Text('${distanceInKm.toStringAsFixed(1)} km'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Approximate Time:'),
                        Text('${duration.toStringAsFixed(0)} mins'),
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
                                      return _buildRideCard(ride, context);
                                    } catch (e) {
                                      return _buildErrorCard(
                                          e.toString(), context);
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
  }

  Widget _buildRideCard(Map<String, dynamic> ride, BuildContext context) {
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
        ride['total_cost'] is num ? (ride['total_cost'] as num).toDouble() : 0.0;
    final distanceFromUser = ride['distance_from_user'] is double
        ? (ride['distance_from_user'] as double).toStringAsFixed(1)
        : 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ride #${ride['ride_number']?.toString() ?? 'N/A'}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
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
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.route, color: const Color(0xFF8B5E3B), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ride['pickup_point']?.toString() ?? 'No pickup specified',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.flag, color: const Color(0xFF8B5E3B), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ride['dropoff_point']?.toString() ?? 'No dropoff specified',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: const Color(0xFF8B5E3B),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(formattedDate, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                Icon(Icons.access_time, color: const Color(0xFF8B5E3B), size: 18),
                const SizedBox(width: 8),
                Text(formattedTime, style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distance from you:',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      '$distanceFromUser km',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5E3B),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total Cost:', style: TextStyle(fontSize: 12)),
                    Text(
                      '\K${totalCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5E3B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: isFull ? null : () => onBookRide(ride),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFull ? Colors.grey : const Color(0xFF8B5E3B),
                minimumSize: const Size(double.infinity, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isFull ? 'NO SEATS AVAILABLE' : 'BOOK NOW',
                style: const TextStyle(
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
  }

  Widget _buildErrorCard(String error, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}