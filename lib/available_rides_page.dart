import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AvailableRidesPage extends StatefulWidget {
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
  _AvailableRidesPageState createState() => _AvailableRidesPageState();
}

class _AvailableRidesPageState extends State<AvailableRidesPage> {
  final _supabase = Supabase.instance.client;
  Set<String> _bookedRideIds = {};
  bool _isCheckingBookings = true;

  @override
  void initState() {
    super.initState();
    _fetchUserBookings();
  }

  Future<void> _fetchUserBookings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Fetch all active/pending bookings from 'request_ride' for the current user
        // These are the statuses that should prevent a new booking
        final response = await _supabase
            .from('request_ride') // Assuming 'request_ride' is the table name
            .select('ride_id')
            .eq('user_id', user.id)
            .inFilter('status', [
              'pending',
              'confirmed',
              'active',
            ]); // Corrected from .in_ to .inFilter

        setState(() {
          _bookedRideIds = Set.from(
            response.map((r) => r['ride_id'].toString()),
          );
          _isCheckingBookings = false;
        });
      } else {
        setState(() {
          _isCheckingBookings =
              false; // User not logged in, no bookings to check
        });
      }
    } catch (e) {
      setState(() {
        _isCheckingBookings = false;
      });
      debugPrint('Error fetching user bookings: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredRides {
    return widget.availableRides.where((ride) {
      final remainingCapacity =
          ride['remaining_capacity'] is int
              ? ride['remaining_capacity'] as int
              : ride['capacity'] is int
              ? ride['capacity'] as int
              : 0;
      final isFull = remainingCapacity <= 0;
      final isAlreadyBooked = _bookedRideIds.contains(ride['id'].toString());
      // A ride is available if it's not full and not already booked by the user
      return !isFull && !isAlreadyBooked;
    }).toList();
  }

  DateTime _parseDepartureTime(String? timeString) {
    if (timeString == null) return DateTime.now();

    // Try ISO format first
    final isoTime = DateTime.tryParse(timeString);
    if (isoTime != null) return isoTime;

    // Handle time-only format (HH:mm)
    if (RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(timeString)) {
      final now = DateTime.now();
      final timeParts = timeString.split(':');
      return DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    }

    // Try common date/time formats
    final formats = [
      'yyyy-MM-dd HH:mm:ss',
      'MM/dd/yyyy hh:mm a',
      'dd-MM-yyyy HH:mm',
      'h:mm a', // 12-hour format
    ];

    for (final format in formats) {
      try {
        return DateFormat(format).parse(timeString);
      } catch (_) {}
    }

    return DateTime.now();
  }

  Future<void> _handleBooking(
    BuildContext context,
    Map<String, dynamic> ride,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to book a ride.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Step 1: Check for existing active bookings for this user in 'request_ride' table
      // This is the crucial check to ensure only one active booking per user
      final existingBookings = await _supabase
          .from(
            'request_ride',
          ) // Ensure this is the correct table name for active requests
          .select('id')
          .eq('user_id', user.id)
          .inFilter('status', [
            'pending',
            'confirmed',
            'active',
          ]); // Corrected from .in_ to .inFilter

      if (existingBookings.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You already have an active ride request. Please complete or cancel it first.',
            ),
            backgroundColor: Colors.orange, // Use an orange color for warning
          ),
        );
        return; // Prevent booking if an active ride exists
      }

      // If no active bookings, proceed with booking the new ride
      final departureTime = _parseDepartureTime(ride['departure_time']);
      final formattedTime = departureTime.toIso8601String();

      // Create a mutable map to update the departure_time
      final updatedRide = Map<String, dynamic>.from(ride)
        ..['departure_time'] = formattedTime;

      // Call the booking function passed from the parent widget
      await widget.onBookRide(updatedRide);

      // Update local state to reflect the new booking, disabling the card
      setState(() {
        _bookedRideIds.add(ride['id'].toString());
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride booked successfully!')),
      );
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Available Rides',
          style: TextStyle(
            color: Color(0xFF5A3D1F),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5A3D1F)),
      ),
      body: Stack(
        children: [
          _buildMapView(),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildRouteInfoCard(),
          ),
          _buildRidesBottomSheet(context),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return FlutterMap(
      options: MapOptions(
        center: widget.pickupLatLng ?? LatLng(-15.7861, 35.0058),
        zoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        if (widget.pickupLatLng != null)
          MarkerLayer(
            markers: [
              Marker(
                point: widget.pickupLatLng!,
                builder:
                    (ctx) => const Tooltip(
                      message: 'Pickup',
                      child: Icon(
                        Icons.location_pin,
                        color: Color(0xFF8B5E3B),
                        size: 30,
                      ),
                    ),
              ),
            ],
          ),
        if (widget.dropoffLatLng != null)
          MarkerLayer(
            markers: [
              Marker(
                point: widget.dropoffLatLng!,
                builder:
                    (ctx) => const Tooltip(
                      message: 'Dropoff',
                      child: Icon(
                        Icons.location_pin,
                        color: Color(0xFF5A3D1F),
                        size: 30,
                      ),
                    ),
              ),
            ],
          ),
        if (widget.routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.routePoints,
                color: const Color(0xFF8B5E3B).withOpacity(0.7),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                color: Color(0xFF5A3D1F),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  icon: Icons.alt_route,
                  value: '${widget.distanceInKm.toStringAsFixed(1)} km',
                  label: 'Distance',
                ),
                _buildInfoItem(
                  icon: Icons.timer,
                  value: '${widget.duration.toStringAsFixed(0)} mins',
                  label: 'Duration',
                ),
                _buildInfoItem(
                  icon: Icons.directions_car,
                  value: widget.selectedVehicleType ?? 'Any',
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
        Icon(icon, size: 18, color: const Color(0xFF8B5E3B)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Color(0xFF5A3D1F),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF8B5E3B)),
        ),
      ],
    );
  }

  Widget _buildRidesBottomSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15)],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5E3B).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
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
                    Text(
                      '${_filteredRides.length} Available Rides',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5A3D1F),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF5A3D1F),
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    widget.isLoadingRides || _isCheckingBookings
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF8B5E3B),
                          ),
                        )
                        : _filteredRides.isEmpty
                        ? const Center(
                          child: Text(
                            'No available rides found',
                            style: TextStyle(color: Color(0xFF5A3D1F)),
                          ),
                        )
                        : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: _filteredRides.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final ride = _filteredRides[index];
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
    final remainingCapacity =
        ride['remaining_capacity'] is int
            ? ride['remaining_capacity']
            : totalCapacity;
    final totalCost =
        ride['total_cost'] is num
            ? (ride['total_cost'] as num).toDouble()
            : 0.0;
    final distanceFromUser =
        ride['distance_from_user'] is double
            ? (ride['distance_from_user'] as double).toStringAsFixed(1)
            : 'N/A';
    final isAlreadyBooked = _bookedRideIds.contains(ride['id'].toString());

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showRideDetails(context, ride),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF8B5E3B).withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 18,
                        color: Color(0xFF8B5E3B),
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
                            color: Color(0xFF5A3D1F),
                          ),
                        ),
                        Text(
                          ride['vehicle_type']?.toString() ?? 'Vehicle',
                          style: TextStyle(
                            fontSize: 10,
                            color: const Color(0xFF8B5E3B).withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A3D1F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'K${totalCost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF5A3D1F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF8B5E3B),
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 20,
                      color: const Color(0xFF8B5E3B).withOpacity(0.3),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF5A3D1F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride['pickup_point']?.toString() ?? 'Pickup location',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF5A3D1F),
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
                          color: Color(0xFF5A3D1F),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5E3B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    formattedTime,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B5E3B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildCapacityIndicator(totalCapacity, remainingCapacity),
                    const SizedBox(width: 8),
                    Text(
                      '$distanceFromUser km away',
                      style: TextStyle(
                        fontSize: 10,
                        color: const Color(0xFF8B5E3B).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed:
                        isAlreadyBooked
                            ? null
                            : () => _handleBooking(context, ride),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isAlreadyBooked
                              ? Colors.grey[400]
                              : const Color(0xFF5A3D1F),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isAlreadyBooked ? 'BOOKED' : 'BOOK NOW',
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
          color:
              isLowCapacity ? const Color(0xFFD4A76A) : const Color(0xFF8B5E3B),
        ),
        const SizedBox(width: 4),
        Text(
          '$remaining/$total',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color:
                isLowCapacity
                    ? const Color(0xFFD4A76A)
                    : const Color(0xFF8B5E3B),
          ),
        ),
      ],
    );
  }

  void _showRideDetails(BuildContext context, Map<String, dynamic> ride) {
    final departureTime = _parseDepartureTime(ride['departure_time']);
    final totalCapacity = ride['capacity'] is int ? ride['capacity'] : 0;
    final remainingCapacity =
        ride['remaining_capacity'] is int
            ? ride['remaining_capacity']
            : totalCapacity;
    final isAlreadyBooked = _bookedRideIds.contains(ride['id'].toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5E3B).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF8B5E3B).withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        size: 24,
                        color: Color(0xFF8B5E3B),
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
                            color: Color(0xFF5A3D1F),
                          ),
                        ),
                        Text(
                          ride['vehicle_type']?.toString() ?? 'Vehicle',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF8B5E3B).withOpacity(0.7),
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
                        color: const Color(0xFF5A3D1F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'K${(ride['total_cost'] as num?)?.toStringAsFixed(2) ?? 'N/A'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF5A3D1F),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0E6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildRoutePoint(
                        icon: Icons.location_pin,
                        iconColor: const Color(0xFF8B5E3B),
                        title: 'Pickup',
                        subtitle: ride['pickup_point']?.toString() ?? 'N/A',
                        time: DateFormat('h:mm a').format(departureTime),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        margin: const EdgeInsets.only(left: 12),
                        height: 20,
                        width: 2,
                        color: const Color(0xFF8B5E3B).withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      _buildRoutePoint(
                        icon: Icons.location_pin,
                        iconColor: const Color(0xFF5A3D1F),
                        title: 'Dropoff',
                        subtitle: ride['dropoff_point']?.toString() ?? 'N/A',
                        time: DateFormat('h:mm a').format(
                          departureTime.add(
                            Duration(minutes: widget.duration.toInt()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
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
                      value: DateFormat('MMM dd,yyyy').format(departureTime),
                    ),
                    _buildDetailItem(
                      icon: Icons.people,
                      title: 'Capacity',
                      value: '$remainingCapacity/$totalCapacity',
                    ),
                    _buildDetailItem(
                      icon: Icons.speed,
                      title: 'Distance',
                      value: '${widget.distanceInKm.toStringAsFixed(1)} km',
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        isAlreadyBooked
                            ? null
                            : () {
                              _handleBooking(context, ride);
                              Navigator.pop(context);
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isAlreadyBooked
                              ? Colors.grey[400]
                              : const Color(0xFF5A3D1F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isAlreadyBooked ? 'ALREADY BOOKED' : 'CONFIRM BOOKING',
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
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF8B5E3B).withOpacity(0.7),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A3D1F),
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
            color: Color(0xFF8B5E3B),
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
          Icon(icon, size: 18, color: const Color(0xFF8B5E3B)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF8B5E3B).withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A3D1F),
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
      color: const Color(0xFFF5E6E6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFD4A76A)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Error loading ride: $error',
                style: const TextStyle(color: Color(0xFF8B5E3B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
