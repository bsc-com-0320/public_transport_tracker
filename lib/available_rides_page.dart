import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

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
        backgroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Map Background
          _buildMapView(),
          
          // Route Information Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildRouteInfoCard(),
          ),
          
          // Rides List Bottom Sheet
          _buildRidesBottomSheet(context),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return FlutterMap(
      options: MapOptions(
        center: pickupLatLng ?? LatLng(-15.7861, 35.0058),
        zoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          tileBuilder: (context, widget, tile) {
            return Opacity(
              opacity: 0.9,
              child: widget,
            );
          },
        ),
        if (pickupLatLng != null)
          MarkerLayer(
            markers: [
              Marker(
                width: 40,
                height: 40,
                point: pickupLatLng!,
                builder: (ctx) => const Tooltip(
                  message: 'Pickup',
                  child: Icon(
                    Icons.location_pin,
                    color: Colors.green,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        if (dropoffLatLng != null)
          MarkerLayer(
            markers: [
              Marker(
                width: 40,
                height: 40,
                point: dropoffLatLng!,
                builder: (ctx) => const Tooltip(
                  message: 'Dropoff',
                  child: Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 30,
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
                color: const Color(0xFF3498DB).withOpacity(0.7),
                strokeWidth: 4.0,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRouteInfoCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Route Summary',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  icon: Icons.alt_route,
                  value: '${distanceInKm.toStringAsFixed(1)} km',
                  label: 'Distance',
                ),
                _buildInfoItem(
                  icon: Icons.timer,
                  value: '${duration.toStringAsFixed(0)} mins',
                  label: 'Duration',
                ),
                _buildInfoItem(
                  icon: Icons.directions_car,
                  value: selectedVehicleType ?? 'Any',
                  label: 'Vehicle',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF3498DB)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildRidesBottomSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${availableRides.length} Available Rides',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              // Rides List
              Expanded(
                child: isLoadingRides
                    ? const Center(child: CircularProgressIndicator())
                    : availableRides.isEmpty
                        ? const Center(
                            child: Text('No available rides found'),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: availableRides.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final ride = availableRides[index];
                              try {
                                return _buildRideCard(ride, context);
                              } catch (e) {
                                return _buildErrorCard(e.toString(), context);
                              }
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride, BuildContext context) {
    final departureTime = _parseDepartureTime(ride['departure_time']);
    final formattedTime = DateFormat('h:mm a').format(departureTime);
    final totalCapacity = ride['capacity'] is int ? ride['capacity'] : 0;
    final remainingCapacity = ride['remaining_capacity'] is int
        ? ride['remaining_capacity']
        : totalCapacity;
    final isFull = remainingCapacity <= 0;
    final totalCost = ride['total_cost'] is num
        ? (ride['total_cost'] as num).toDouble()
        : 0.0;
    final distanceFromUser = ride['distance_from_user'] is double
        ? (ride['distance_from_user'] as double).toStringAsFixed(1)
        : 'N/A';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showRideDetails(context, ride),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First row - Driver info and price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Driver info
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF3498DB).withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 18,
                        color: Color(0xFF3498DB),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride['driver_name']?.toString() ?? 'Driver',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          ride['vehicle_type']?.toString() ?? 'Vehicle',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Price
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C3E50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'K${totalCost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Route information
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 20,
                      color: Colors.grey[300],
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 8),
                
                // Locations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride['pickup_point']?.toString() ?? 'Pickup location',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        ride['dropoff_point']?.toString() ?? 'Dropoff location',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Departure time
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3498DB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    formattedTime,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3498DB),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Bottom row - Capacity and action button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Capacity indicator
                Row(
                  children: [
                    _buildCapacityIndicator(totalCapacity, remainingCapacity),
                    const SizedBox(width: 8),
                    Text(
                      '$distanceFromUser km away',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                
                // Book button
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: isFull ? null : () => onBookRide(ride),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFull
                          ? Colors.grey[400]
                          : const Color(0xFF2C3E50),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isFull ? 'FULL' : 'BOOK NOW',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityIndicator(int total, int remaining) {
    final percentage = total > 0 ? (remaining / total) : 0.0;
    final isLowCapacity = percentage < 0.3;

    return Row(
      children: [
        Icon(
          Icons.people_alt_outlined,
          size: 14,
          color: isLowCapacity
              ? Colors.orange
              : const Color(0xFF3498DB),
        ),
        const SizedBox(width: 4),
        Text(
          '$remaining/$total',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isLowCapacity
                ? Colors.orange
                : const Color(0xFF3498DB),
          ),
        ),
      ],
    );
  }

  DateTime _parseDepartureTime(String? departureTime) {
    if (departureTime == null) return DateTime.now();

    try {
      DateTime? parsedTime = DateTime.tryParse(departureTime);
      if (parsedTime != null) return parsedTime;

      final formatsToTry = [
        "yyyy-MM-dd HH:mm:ss",
        "dd/MM/yyyy h:mm a",
        "MMM dd,yyyy HH:mm",
        "yyyy-MM-dd HH:mm",
      ];

      for (final format in formatsToTry) {
        try {
          return DateFormat(format).parse(departureTime);
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      return DateTime.now();
    }

    return DateTime.now();
  }

  void _showRideDetails(BuildContext context, Map<String, dynamic> ride) {
    final departureTime = _parseDepartureTime(ride['departure_time']);
    final totalCapacity = ride['capacity'] is int ? ride['capacity'] : 0;
    final remainingCapacity = ride['remaining_capacity'] is int
        ? ride['remaining_capacity']
        : totalCapacity;
    final isFull = remainingCapacity <= 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            
            // Ride header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3498DB).withOpacity(0.2),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 24,
                    color: Color(0xFF3498DB),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ride #${ride['ride_number']?.toString() ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ride['vehicle_type']?.toString() ?? 'Vehicle',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C3E50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'K${(ride['total_cost'] as num?)?.toStringAsFixed(2) ?? 'N/A'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Route visualization
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildRoutePoint(
                    icon: Icons.location_pin,
                    iconColor: Colors.green,
                    title: 'Pickup',
                    subtitle: ride['pickup_point']?.toString() ?? 'N/A',
                    time: DateFormat('h:mm a').format(departureTime),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    height: 20,
                    width: 2,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  _buildRoutePoint(
                    icon: Icons.location_pin,
                    iconColor: Colors.red,
                    title: 'Dropoff',
                    subtitle: ride['dropoff_point']?.toString() ?? 'N/A',
                    time: DateFormat('h:mm a').format(
                      departureTime.add(Duration(minutes: duration.toInt())),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Details grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 3.5,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDetailItem(
                  icon: Icons.person,
                  title: 'Driver',
                  value: ride['driver_name']?.toString() ?? 'N/A',
                ),
                _buildDetailItem(
                  icon: Icons.calendar_today,
                  title: 'Date',
                  value: DateFormat('MMM dd, yyyy').format(departureTime),
                ),
                _buildDetailItem(
                  icon: Icons.people,
                  title: 'Capacity',
                  value: '$remainingCapacity/$totalCapacity',
                ),
                _buildDetailItem(
                  icon: Icons.speed,
                  title: 'Distance',
                  value: '${distanceInKm.toStringAsFixed(1)} km',
                ),
              ],
            ),
            
            const Spacer(),
            
            // Action button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isFull
                    ? null
                    : () {
                        onBookRide(ride);
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isFull ? Colors.grey[400] : const Color(0xFF2C3E50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isFull ? 'NO SEATS AVAILABLE' : 'CONFIRM BOOKING',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutePoint({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3498DB),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF3498DB)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Error loading ride: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}