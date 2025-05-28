import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart'; // Keep if you use it elsewhere
import 'package:latlong2/latlong.dart'; // Keep if you use it elsewhere

class DriverRecordsPage extends StatefulWidget {
  @override
  _DriverRecordsPageState createState() => _DriverRecordsPageState();
}

class _DriverRecordsPageState extends State<DriverRecordsPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterType = 'all';
  int _selectedIndex = 2;

  // Navigation routes
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

      final response = await _supabase
          .from('request_ride')
          .select('*')
          .eq('driver_id', userId)
          .order('booking_time', ascending: false);

      setState(() {
        _bookings = List<Map<String, dynamic>>.from(response);
        _filterBookings(); // Apply current filters after fetching new data
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

    // Apply status filter
    if (_filterType != 'all') {
      results =
          results.where((booking) => booking['status'] == _filterType).toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      results =
          results.where((booking) {
            return booking['pickup_point'].toLowerCase().contains(query) ||
                booking['dropoff_point'].toLowerCase().contains(query) ||
                booking['departure_time'].toLowerCase().contains(query) ||
                booking['vehicle_type'].toLowerCase().contains(query);
          }).toList();
    }

    setState(() => _filteredBookings = results);
  }

  // --- Update Booking Status (Confirm Ride) ---
  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    final String actionText = newStatus == 'confirmed' ? 'Confirm' : 'Cancel';
    final String confirmationQuestion =
        newStatus == 'confirmed'
            ? 'Are you sure you want to confirm this ride?'
            : 'Are you sure you want to cancel this ride?';
    final Color buttonColor =
        newStatus == 'confirmed' ? const Color(0xFF5A3D1F) : Colors.red;
    final String buttonLabel =
        newStatus == 'confirmed' ? 'Yes, Confirm' : 'Yes, Cancel';

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
                style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
                child: Text(
                  buttonLabel,
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
            .eq(
              'id',
              bookingId,
            ); // Ensure bookingId is a String for Supabase eq method

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Booking $newStatus successfully!')),
          );
        }
        _fetchBookings(); // Refresh the list to reflect the change
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
                  _buildDetailRow('Pickup Point', booking['pickup_point']),
                  _buildDetailRow('Dropoff Point', booking['dropoff_point']),
                  _buildDetailRow('Vehicle Type', booking['vehicle_type']),
                  _buildDetailRow(
                    'Departure Time',
                    DateFormat(
                      'MMM dd, yyyy - hh:mm a',
                    ).format(DateTime.parse(booking['departure_time'])),
                  ),
                  _buildDetailRow(
                    'Booking Time',
                    DateFormat(
                      'MMM dd, yyyy - hh:mm a',
                    ).format(DateTime.parse(booking['booking_time'])),
                  ),
                  _buildDetailRow('Total Cost', '\$${booking['total_cost']}'),
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
    // Ensure value is converted to String to prevent type errors in Text widget
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

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    // Ensure bookingId is a String
    final String bookingId = booking['id'].toString();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showBookingDetails(booking),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        booking['status'],
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(booking['status']),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      booking['status'].toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(booking['status']),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat(
                      'MMM dd',
                    ).format(DateTime.parse(booking['booking_time'])),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                  size: 16,
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
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                      const Icon(
                        Icons.directions_car,
                        color: Color(0xFF5A3D1F),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        booking['vehicle_type'],
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat(
                      'hh:mm a',
                    ).format(DateTime.parse(booking['departure_time'])),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Show buttons for pending, confirmed, and cancelled statuses
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed:
                          () => _updateBookingStatus(bookingId, 'cancelled'),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A3D1F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed:
                          () => _updateBookingStatus(bookingId, 'confirmed'),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(color: Colors.white),
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
    return SingleChildScrollView(
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
                setState(() => _searchQuery = value);
                _filterBookings();
              },
            ),
          ),
          _buildFilterChips(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  'Total Bookings: ${_filteredBookings.length}',
                  style: const TextStyle(
                    color: Color(0xFF5A3D1F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
                            Icons.history,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No bookings found',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _fetchBookings,
                      color: const Color(0xFF5A3D1F),
                      child: ListView.builder(
                        itemCount: _filteredBookings.length,
                        itemBuilder: (context, index) {
                          return _buildBookingCard(_filteredBookings[index]);
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
