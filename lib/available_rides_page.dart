import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Commented out as it's not directly used in this widget's logic

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
          // FlutterMap widget to display the map and route
          FlutterMap(
            options: MapOptions(
              // Center the map on pickup or a default location if pickup is null
              center:
                  pickupLatLng ??
                  LatLng(-15.7861, 35.0058), // Default to Zomba, Malawi
              zoom: 13.0,
            ),
            children: [
              // TileLayer for OpenStreetMap tiles
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              // Marker for pickup location if available
              if (pickupLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80,
                      height: 80,
                      point: pickupLatLng!,
                      builder:
                          (ctx) => const Tooltip(
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
              // Marker for dropoff location if available
              if (dropoffLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80,
                      height: 80,
                      point: dropoffLatLng!,
                      builder:
                          (ctx) => const Tooltip(
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
              // Polyline for the route if route points are available
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
          // Positioned Card for route information
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
          // DraggableScrollableSheet for available rides list
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
                      child:
                          isLoadingRides
                              ? const Center(child: CircularProgressIndicator())
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
                                      e.toString(),
                                      context,
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
  }

  // Widget to build an individual ride card in the list
  Widget _buildRideCard(Map<String, dynamic> ride, BuildContext context) {
    DateTime departureTime;
    try {
      departureTime =
          DateTime.tryParse(ride['departure_time']) ?? DateTime.now();
      // If parsing fails, try other common formats
      if (departureTime == DateTime.now()) {
        final formatsToTry = [
          "yyyy-MM-dd HH:mm:ss",
          "dd/MM/yyyy h:mm a",
          "MMM dd, yyyy HH:mm", // Corrected typo here from 'പ്പെടെ' to 'yyyy'
          "yyyy-MM-dd HH:mm",
        ];

        for (final format in formatsToTry) {
          try {
            departureTime = DateFormat(format).parse(ride['departure_time']);
            break;
          } catch (e) {
            // Continue to the next format if parsing fails
            continue;
          }
        }
      }
    } catch (e) {
      // Fallback to current time if all parsing attempts fail
      departureTime = DateTime.now();
    }

    final formattedTime = DateFormat('h:mm a').format(departureTime);
    final totalCapacity = ride['capacity'] is int ? ride['capacity'] : 0;
    final remainingCapacity =
        ride['remaining_capacity'] is int
            ? ride['remaining_capacity']
            : totalCapacity; // Default to total capacity if remaining is not an int
    final isFull = remainingCapacity <= 0;
    final totalCost =
        ride['total_cost'] is num
            ? (ride['total_cost'] as num).toDouble()
            : 0.0; // Default to 0.0 if total_cost is not a num
    final distanceFromUser =
        ride['distance_from_user'] is double
            ? (ride['distance_from_user'] as double).toStringAsFixed(1)
            : 'N/A'; // Default to 'N/A' if distance is not a double

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            () => _showRideDetails(
              context,
              ride,
            ), // Function to show expanded details
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact header row with basic info, price, and capacity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side - Basic info (Ride number and time)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ride #${ride['ride_number']?.toString() ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(
                              0xFF5A3D1F,
                            ), // Darker brown for emphasis
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right side - Price and capacity indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'K${totalCost.toStringAsFixed(2)}', // Display cost with 'K' prefix
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B5E3B), // Brown color for price
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildCompactCapacityIndicator(
                        totalCapacity,
                        remainingCapacity,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Route information in a single line (pickup to dropoff)
              Row(
                children: [
                  Icon(
                    Icons.arrow_right_alt,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${ride['pickup_point']?.toString() ?? 'N/A'} → ${ride['dropoff_point']?.toString() ?? 'N/A'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis, // Truncate long route names
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Bottom row with distance from user and book button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    backgroundColor: Colors.grey[100],
                    label: Text(
                      '$distanceFromUser km away',
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap, // Makes chip smaller
                  ),

                  SizedBox(
                    height: 28, // Smaller height for the button
                    child: ElevatedButton(
                      onPressed:
                          isFull
                              ? null
                              : () => onBookRide(ride), // Disable if full
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isFull
                                ? Colors.grey[400]
                                : const Color(0xFF8B5E3B), // Grey if full
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isFull ? 'FULL' : 'BOOK',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Compact capacity indicator (e.g., "3/5" seats)
  Widget _buildCompactCapacityIndicator(int total, int remaining) {
    final percentage = total > 0 ? (remaining / total) : 0.0;
    final isLowCapacity = percentage < 0.3; // Highlight if capacity is low

    return Row(
      children: [
        Icon(
          Icons.person_outline,
          size: 14,
          color: isLowCapacity ? Colors.orange[400] : const Color(0xFF8B5E3B),
        ),
        const SizedBox(width: 2),
        Text(
          '$remaining/$total',
          style: TextStyle(
            fontSize: 11,
            color: isLowCapacity ? Colors.orange[400] : const Color(0xFF5A3D1F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Function to show expanded ride details in a modal bottom sheet
  void _showRideDetails(BuildContext context, Map<String, dynamic> ride) {
    // Calculate isFull locally within this function
    final totalCapacity = ride['capacity'] is int ? ride['capacity'] : 0;
    final remainingCapacity =
        ride['remaining_capacity'] is int
            ? ride['remaining_capacity']
            : totalCapacity;
    final isFull = remainingCapacity <= 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take full height
      backgroundColor: Colors.transparent, // For rounded corners to show
      builder:
          (context) => Container(
            height:
                MediaQuery.of(context).size.height *
                0.7, // 70% of screen height
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Example of detailed information you might add
                Text(
                  'Ride Details for Ride #${ride['ride_number']?.toString() ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: Icons.person,
                  label: 'Driver:',
                  value: ride['driver_name']?.toString() ?? 'N/A',
                ),
                _buildInfoRow(
                  icon: Icons.directions_car,
                  label: 'Vehicle:',
                  value: ride['vehicle_type']?.toString() ?? 'N/A',
                ),
                _buildInfoRow(
                  icon: Icons.event,
                  label: 'Departure Time:',
                  value: DateFormat('MMM dd, yyyy h:mm a').format(
                    // Corrected typo here
                    DateTime.tryParse(ride['departure_time']) ?? DateTime.now(),
                  ),
                ),
                _buildInfoRow(
                  icon: Icons.location_on,
                  label: 'Pickup:',
                  value: ride['pickup_point']?.toString() ?? 'N/A',
                ),
                _buildInfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Dropoff:',
                  value: ride['dropoff_point']?.toString() ?? 'N/A',
                ),
                _buildInfoRow(
                  icon: Icons.attach_money,
                  label: 'Total Cost:',
                  value:
                      'K${(ride['total_cost'] as num?)?.toStringAsFixed(2) ?? 'N/A'}',
                ),
                _buildInfoRow(
                  icon: Icons.group,
                  label: 'Capacity:',
                  value: '${remainingCapacity}/${totalCapacity} seats',
                ), // Use local variables
                _buildInfoRow(
                  icon: Icons.alt_route,
                  label: 'Distance:',
                  value: '${distanceInKm.toStringAsFixed(1)} km',
                ),
                _buildInfoRow(
                  icon: Icons.timer,
                  label: 'Approx. Duration:',
                  value: '${duration.toStringAsFixed(0)} mins',
                ),
                // Add a book button in the details sheet as well
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        isFull
                            ? null
                            : () {
                              // Use local isFull
                              onBookRide(ride);
                              Navigator.pop(
                                context,
                              ); // Close the modal after booking
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isFull
                              ? Colors.grey[400]
                              : const Color(0xFF8B5E3B), // Use local isFull
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isFull ? 'FULL' : 'BOOK THIS RIDE', // Use local isFull
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // Helper widget for displaying information rows in the details sheet
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF8B5E3B)),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF5A3D1F),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // Capacity indicator with progress bar (not used in the compact card, but kept for potential future use)
  Widget _buildCapacityIndicator(int total, int remaining) {
    final percentage = total > 0 ? (remaining / total) : 0.0;
    final isLowCapacity = percentage < 0.3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Text showing remaining/total
        Text(
          '$remaining/$total seats',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isLowCapacity ? Colors.red[800] : const Color(0xFF5A3D1F),
          ),
        ),
        const SizedBox(height: 4),
        // Progress bar
        Container(
          width: 100,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(3),
          ),
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: constraints.maxWidth * percentage,
                    decoration: BoxDecoration(
                      color:
                          isLowCapacity
                              ? Colors.orange[400]
                              : const Color(0xFF8B5E3B),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Route information row (not used directly in the compact card, but kept for potential future use)
  Widget _buildRouteInfoRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8B5E3B), size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  // Info column for distance/price (not used directly in the compact card, but kept for potential future use)
  Widget _buildInfoColumn({
    required String label,
    required String value,
    bool isRightAligned = false,
  }) {
    return Column(
      crossAxisAlignment:
          isRightAligned ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B5E3B), // Brown color
          ),
        ),
      ],
    );
  }

  // Widget to display an error card
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
