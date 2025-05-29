import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint

class DriverRecordsPage extends StatefulWidget {
  @override
  _DriverRecordsPageState createState() => _DriverRecordsPageState();
}

class _DriverRecordsPageState extends State<DriverRecordsPage> {
  final _supabase = Supabase.instance.client;
  final Distance _distance = Distance();
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterType = 'all';
  String _sortType = 'default';
  int _selectedIndex = 2;
  Position? _currentPosition;

  final List<String> _pages = [
    '/driver-home',
    '/driver-ride',
    '/driver-records',
    '/fund-account',
  ];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not logged in. Cannot fetch bookings.'),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Fetch bookings including user_id (passenger's ID)
      final response = await _supabase
          .from('request_ride')
          .select('''
            *,
            user_id
          ''') // Select all columns and explicitly user_id
          .eq('driver_id', userId)
          .order('booking_time', ascending: false);

      List<Map<String, dynamic>> fetchedBookings =
          List<Map<String, dynamic>>.from(response);

      // Fetch passenger details (name and phone) for each booking
      for (var booking in fetchedBookings) {
        final passengerUserId = booking['user_id'];
        debugPrint(
          'Processing booking for passengerUserId: $passengerUserId',
        ); // Debug print
        if (passengerUserId != null) {
          try {
            final passengerProfile =
                await _supabase
                    .from(
                      'user_profiles',
                    ) // Assuming 'user_profiles' table for passengers
                    .select('full_name, phone') // Select full_name and phone
                    .eq('user_id', passengerUserId)
                    .maybeSingle(); // Use maybeSingle to handle cases where no profile is found

            debugPrint(
              'Passenger profile response for $passengerUserId: $passengerProfile',
            ); // Debug print

            if (passengerProfile != null) {
              booking['passenger_name'] =
                  passengerProfile['full_name']?.toString() ?? 'N/A';
              booking['passenger_phone'] =
                  passengerProfile['phone']?.toString() ?? 'N/A';
            } else {
              booking['passenger_name'] = 'N/A';
              booking['passenger_phone'] = 'N/A';
            }
          } catch (e) {
            debugPrint(
              'Error fetching passenger profile for ID $passengerUserId: $e',
            );
            booking['passenger_name'] = 'Error';
            booking['passenger_phone'] = 'Error';
          }
        } else {
          booking['passenger_name'] = 'N/A';
          booking['passenger_phone'] = 'N/A';
        }
      }

      setState(() {
        _bookings = fetchedBookings;
        _filterBookings();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching bookings: ${e.toString()}')),
        );
      }
    }
  }

  void _filterBookings() {
    List<Map<String, dynamic>> results = _bookings;

    if (_filterType != 'all') {
      results =
          results.where((booking) => booking['status'] == _filterType).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      results =
          results
              .where(
                (booking) =>
                    booking['pickup_point'].toLowerCase().contains(query) ||
                    booking['dropoff_point'].toLowerCase().contains(query) ||
                    booking['departure_time'].toLowerCase().contains(query) ||
                    booking['vehicle_type'].toLowerCase().contains(query) ||
                    (booking['passenger_name']?.toLowerCase().contains(query) ??
                        false) || // Search by passenger name
                    (booking['passenger_phone']?.toLowerCase().contains(
                          query,
                        ) ??
                        false), // Search by passenger phone
              )
              .toList();
    }

    // Apply sorting
    results = _sortBookings(results, _sortType);

    setState(() => _filteredBookings = results);
  }

  List<Map<String, dynamic>> _sortBookings(
    List<Map<String, dynamic>> bookings,
    String sortType,
  ) {
    switch (sortType) {
      case 'pickup':
        return _sortByPickupDistance(bookings);
      case 'dropoff':
        return _sortByDropoffDistance(bookings);
      case 'departure':
        return _sortByDepartureTime(bookings);
      case 'booking':
        return _sortByBookingTime(bookings);
      case 'default':
      default:
        return bookings
          ..sort((a, b) => b['booking_time'].compareTo(a['booking_time']));
    }
  }

  List<Map<String, dynamic>> _sortByPickupDistance(
    List<Map<String, dynamic>> bookings,
  ) {
    if (_currentPosition == null) return bookings;

    bookings.sort((a, b) {
      if (a['pickup_lat'] == null || a['pickup_lng'] == null) return 1;
      if (b['pickup_lat'] == null || b['pickup_lng'] == null) return -1;

      final distanceA = _distance.as(
        LengthUnit.Kilometer,
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        LatLng(a['pickup_lat'], a['pickup_lng']),
      );

      final distanceB = _distance.as(
        LengthUnit.Kilometer,
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        LatLng(b['pickup_lat'], b['pickup_lng']),
      );

      return distanceA.compareTo(distanceB);
    });

    return bookings;
  }

  List<Map<String, dynamic>> _sortByDropoffDistance(
    List<Map<String, dynamic>> bookings,
  ) {
    if (_currentPosition == null) return bookings;

    bookings.sort((a, b) {
      if (a['dropoff_lat'] == null || a['dropoff_lng'] == null) return 1;
      if (b['dropoff_lat'] == null || b['dropoff_lng'] == null) return -1;

      final distanceA = _distance.as(
        LengthUnit.Kilometer,
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        LatLng(a['dropoff_lat'], a['dropoff_lng']),
      );

      final distanceB = _distance.as(
        LengthUnit.Kilometer,
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        LatLng(b['dropoff_lat'], b['dropoff_lng']),
      );

      return distanceA.compareTo(distanceB);
    });

    return bookings;
  }

  List<Map<String, dynamic>> _sortByDepartureTime(
    List<Map<String, dynamic>> bookings,
  ) {
    bookings.sort((a, b) {
      final timeA = DateTime.parse(a['departure_time']);
      final timeB = DateTime.parse(b['departure_time']);
      return timeA.compareTo(timeB);
    });
    return bookings;
  }

  List<Map<String, dynamic>> _sortByBookingTime(
    List<Map<String, dynamic>> bookings,
  ) {
    bookings.sort((a, b) {
      final timeA = DateTime.parse(a['booking_time']);
      final timeB = DateTime.parse(b['booking_time']);
      return timeA.compareTo(timeB);
    });
    return bookings;
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    String actionText = '';
    String confirmationQuestion = '';
    String successMessage = '';

    if (newStatus == 'confirmed') {
      actionText = 'Confirm';
      confirmationQuestion = 'Are you sure you want to confirm this ride?';
      successMessage = 'Booking confirmed successfully!';
    } else if (newStatus == 'cancelled') {
      actionText = 'Cancel';
      confirmationQuestion = 'Are you sure you want to cancel this ride?';
      successMessage = 'Booking cancelled successfully!';
    } else if (newStatus == 'pending') {
      actionText = 'Revert to Pending';
      confirmationQuestion =
          'Are you sure you want to change this ride back to pending?';
      successMessage = 'Booking reverted to pending successfully!';
    } else if (newStatus == 'completed') {
      actionText = 'Complete';
      confirmationQuestion =
          'Are you sure you want to mark this ride as completed?';
      successMessage = 'Booking marked as completed!';
    }

    final Color confirmButtonColor =
        newStatus == 'cancelled' ? Colors.red : const Color(0xFF5A3D1F);
    final String confirmButtonLabel =
        newStatus == 'cancelled' ? 'Yes, Cancel' : 'Yes, Confirm';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('$actionText Ride'),
            content: Text(confirmationQuestion),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmButtonColor,
                ),
                child: Text(
                  confirmButtonLabel,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _supabase
            .from('request_ride')
            .update({'status': newStatus})
            .eq('id', bookingId);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(successMessage)));
        }
        _fetchBookings();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error $actionText booking: ${e.toString()}'),
            ),
          );
        }
      }
    }
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Booking Details',
              style: TextStyle(color: Color(0xFF5A3D1F)),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Status',
                    booking['status'],
                    color: _getStatusColor(booking['status']),
                  ),
                  _buildDetailRow(
                    'Passenger Name',
                    booking['passenger_name'] ?? 'N/A',
                  ), // Display passenger name
                  _buildDetailRow(
                    'Passenger Contact',
                    booking['passenger_phone'] ?? 'N/A',
                  ), // Display passenger phone
                  _buildDetailRow('Pickup Point', booking['pickup_point']),
                  _buildDetailRow('Dropoff Point', booking['dropoff_point']),
                  _buildDetailRow('Vehicle Type', booking['vehicle_type']),
                  _buildDetailRow(
                    'Departure Time',
                    DateFormat(
                      'MMM dd,EEEE - hh:mm a',
                    ).format(DateTime.parse(booking['departure_time'])),
                  ),
                  _buildDetailRow(
                    'Booking Time',
                    DateFormat(
                      'MMM dd,EEEE - hh:mm a',
                    ).format(DateTime.parse(booking['booking_time'])),
                  ),
                  _buildDetailRow(
                    'Total Cost',
                    'K ${booking['total_cost']}',
                  ), // Changed symbol to K
                  if (booking['pickup_lat'] != null &&
                      booking['pickup_lng'] != null)
                    _buildDetailRow(
                      'Pickup Coordinates',
                      '${booking['pickup_lat']}, ${booking['pickup_lng']}',
                    ),
                  if (booking['dropoff_lat'] != null &&
                      booking['dropoff_lng'] != null)
                    _buildDetailRow(
                      'Dropoff Coordinates',
                      '${booking['dropoff_lat']}, ${booking['dropoff_lng']}',
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Color(0xFF5A3D1F)),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value, {Color? color}) {
    final String displayValue = value?.toString() ?? 'N/A';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5A3D1F),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: TextStyle(color: color ?? Colors.grey[700], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Builds a row to display an icon, label, and value for booking information.
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF5A3D1F), size: 18), // Smaller icon
        const SizedBox(width: 8), // Reduced space
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12, // Smaller font
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2), // Reduced space
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13, // Smaller font
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5A3D1F),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final String bookingId = booking['id'].toString();
    final String currentStatus = booking['status'].toLowerCase();
    final String passengerName = booking['passenger_name']?.toString() ?? 'N/A';
    final String passengerPhone =
        booking['passenger_phone']?.toString() ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 12,
      ), // Reduced card margins
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ), // Slightly smaller radius
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showBookingDetails(booking),
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Reduced internal padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6, // Reduced padding
                      vertical: 3, // Reduced padding
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        booking['status'],
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6), // Smaller radius
                      border: Border.all(
                        color: _getStatusColor(booking['status']),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      booking['status'].toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(booking['status']),
                        fontSize: 11, // Smaller font
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat(
                      'MMM dd',
                    ).format(DateTime.parse(booking['booking_time'])),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ), // Smaller font
                  ),
                ],
              ),
              const SizedBox(height: 10), // Reduced space
              // Display Passenger Name and Contact
              _buildInfoRow(Icons.person, 'Passenger Name:', passengerName),
              const SizedBox(height: 6), // Reduced space
              _buildInfoRow(Icons.phone, 'Passenger Contact:', passengerPhone),
              const SizedBox(height: 10), // Reduced space
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFF5A3D1F),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking['pickup_point'],
                      style: const TextStyle(
                        color: Color(0xFF5A3D1F),
                        fontWeight: FontWeight.bold,
                        fontSize: 13, // Smaller font
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 24),
                child: Icon(
                  Icons.arrow_downward,
                  color: Color(0xFF5A3D1F),
                  size: 14, // Smaller icon
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.flag, color: Color(0xFF5A3D1F), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking['dropoff_point'],
                      style: const TextStyle(
                        color: Color(0xFF5A3D1F),
                        fontWeight: FontWeight.bold,
                        fontSize: 13, // Smaller font
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10), // Reduced space
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_car,
                        color: Color(0xFF5A3D1F),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        booking['vehicle_type'],
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ), // Smaller font
                      ),
                    ],
                  ),
                  Text(
                    DateFormat(
                      'hh:mm a',
                    ).format(DateTime.parse(booking['departure_time'])),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ), // Smaller font
                  ),
                ],
              ),
              const SizedBox(height: 10), // Reduced space
              if (currentStatus == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ), // Reduced padding
                        ),
                        onPressed:
                            () => _updateBookingStatus(bookingId, 'cancelled'),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ), // Smaller font
                        ),
                      ),
                    ),
                    const SizedBox(width: 6), // Reduced space
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A3D1F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ), // Reduced padding
                        ),
                        onPressed:
                            () => _updateBookingStatus(bookingId, 'confirmed'),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ), // Smaller font
                        ),
                      ),
                    ),
                  ],
                ),
              if (currentStatus == 'confirmed')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ), // Reduced padding
                        ),
                        onPressed:
                            () => _updateBookingStatus(bookingId, 'cancelled'),
                        child: const Text(
                          'Cancel Ride',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ), // Smaller font
                        ),
                      ),
                    ),
                    const SizedBox(width: 6), // Reduced space
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF5A3D1F)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ), // Reduced padding
                        ),
                        onPressed:
                            () => _updateBookingStatus(bookingId, 'pending'),
                        child: const Text(
                          'Revert to Pending',
                          style: TextStyle(
                            color: Color(0xFF5A3D1F),
                            fontSize: 13,
                          ), // Smaller font
                        ),
                      ),
                    ),
                  ],
                ),
              if (currentStatus == 'cancelled')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A3D1F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ), // Reduced padding
                        ),
                        onPressed:
                            () => _updateBookingStatus(bookingId, 'confirmed'),
                        child: const Text(
                          'Re-Confirm',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ), // Smaller font
                        ),
                      ),
                    ),
                    const SizedBox(width: 6), // Reduced space
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF5A3D1F)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ), // Reduced padding
                        ),
                        onPressed:
                            () => _updateBookingStatus(bookingId, 'pending'),
                        child: const Text(
                          'Revert to Pending',
                          style: TextStyle(
                            color: Color(0xFF5A3D1F),
                            fontSize: 13,
                          ), // Smaller font
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

  Widget _buildFilterChips() {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 16),
              FilterChip(
                label: const Text('All'),
                selected: _filterType == 'all',
                onSelected: (selected) {
                  setState(() => _filterType = 'all');
                  _filterBookings();
                },
                selectedColor: const Color(0xFF5A3D1F).withOpacity(0.2),
                checkmarkColor: const Color(0xFF5A3D1F),
                labelStyle: TextStyle(
                  color:
                      _filterType == 'all'
                          ? const Color(0xFF5A3D1F)
                          : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Pending'),
                selected: _filterType == 'pending',
                onSelected: (selected) {
                  setState(() => _filterType = 'pending');
                  _filterBookings();
                },
                selectedColor: const Color(0xFF5A3D1F).withOpacity(0.2),
                checkmarkColor: const Color(0xFF5A3D1F),
                labelStyle: TextStyle(
                  color:
                      _filterType == 'pending'
                          ? const Color(0xFF5A3D1F)
                          : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Confirmed'),
                selected: _filterType == 'confirmed',
                onSelected: (selected) {
                  setState(() => _filterType = 'confirmed');
                  _filterBookings();
                },
                selectedColor: const Color(0xFF5A3D1F).withOpacity(0.2),
                checkmarkColor: const Color(0xFF5A3D1F),
                labelStyle: TextStyle(
                  color:
                      _filterType == 'confirmed'
                          ? const Color(0xFF5A3D1F)
                          : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Cancelled'),
                selected: _filterType == 'cancelled',
                onSelected: (selected) {
                  setState(() => _filterType = 'cancelled');
                  _filterBookings();
                },
                selectedColor: const Color(0xFF5A3D1F).withOpacity(0.2),
                checkmarkColor: const Color(0xFF5A3D1F),
                labelStyle: TextStyle(
                  color:
                      _filterType == 'cancelled'
                          ? const Color(0xFF5A3D1F)
                          : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 16),
              FilterChip(
                label: const Text('Default'),
                selected: _sortType == 'default',
                onSelected: (selected) {
                  setState(() => _sortType = 'default');
                  _filterBookings();
                },
                selectedColor: const Color(0xFF5A3D1F).withOpacity(0.2),
                checkmarkColor: const Color(0xFF5A3D1F),
                labelStyle: TextStyle(
                  color:
                      _sortType == 'default'
                          ? const Color(0xFF5A3D1F)
                          : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Pickup Proximity'),
                selected: _sortType == 'pickup',
                onSelected: (selected) {
                  setState(() => _sortType = 'pickup');
                  _filterBookings();
                },
                selectedColor: const Color(0xFF5A3D1F).withOpacity(0.2),
                checkmarkColor: const Color(0xFF5A3D1F),
                labelStyle: TextStyle(
                  color:
                      _sortType == 'pickup'
                          ? const Color(0xFF5A3D1F)
                          : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Dropoff Proximity'),
                selected: _sortType == 'dropoff',
                onSelected: (selected) {
                  setState(() => _sortType = 'dropoff');
                  _filterBookings();
                },
                selectedColor: const Color(0xFF5A3D1F).withOpacity(0.2),
                checkmarkColor: const Color(0xFF5A3D1F),
                labelStyle: TextStyle(
                  color:
                      _sortType == 'dropoff'
                          ? const Color(0xFF5A3D1F)
                          : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Departure Time'),
                selected: _sortType == 'departure',
                onSelected: (selected) {
                  setState(() => _sortType = 'departure');
                  _filterBookings();
                },
                selectedColor: const Color(0xFF5A3D1F).withOpacity(0.2),
                checkmarkColor: const Color(0xFF5A3D1F),
                labelStyle: TextStyle(
                  color:
                      _sortType == 'departure'
                          ? const Color(0xFF5A3D1F)
                          : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Booking Time'),
                selected: _sortType == 'booking',
                onSelected: (selected) {
                  setState(() => _sortType = 'booking');
                  _filterBookings();
                },
                selectedColor: const Color(0xFF5A3D1F).withOpacity(0.2),
                checkmarkColor: const Color(0xFF5A3D1F),
                labelStyle: TextStyle(
                  color:
                      _sortType == 'booking'
                          ? const Color(0xFF5A3D1F)
                          : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    Navigator.pushReplacementNamed(context, _pages[index]);
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF5A3D1F),
      unselectedItemColor: Colors.grey[600],
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      elevation: 10,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      items: const [
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
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Booking Records",
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
              // TODO: Implement notification logic
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF5A3D1F)),
            onPressed: _fetchBookings,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search bookings...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF5A3D1F)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterBookings();
                });
              },
            ),
          ),
          _buildFilterChips(),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5A3D1F),
                      ),
                    )
                    : _filteredBookings.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_note,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No matching bookings found.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your filters or search query.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _fetchBookings,
                      color: const Color(0xFF5A3D1F),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = _filteredBookings[index];
                          return _buildBookingCard(booking);
                        },
                      ),
                    ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}
