import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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
      if (userId == null) return;

      final response = await _supabase
          .from('request_ride')
          .select('*')
          .eq('driver_id', userId)
          .order('booking_time', ascending: false);

      setState(() {
        _bookings = List<Map<String, dynamic>>.from(response);
        _filteredBookings = _bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching bookings: ${e.toString()}')),
      );
    }
  }

  void _filterBookings() {
    List<Map<String, dynamic>> results = _bookings;

    // Apply status filter
    if (_filterType != 'all') {
      results = results.where((booking) => booking['status'] == _filterType).toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      results = results.where((booking) {
        return booking['pickup_point'].toLowerCase().contains(query) ||
               booking['dropoff_point'].toLowerCase().contains(query) ||
               booking['departure_time'].toLowerCase().contains(query) ||
               booking['vehicle_type'].toLowerCase().contains(query);
      }).toList();
    }

    setState(() => _filteredBookings = results);
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      await _supabase
          .from('request_ride')
          .update({'status': status})
          .eq('id', bookingId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking $status successfully!')),
      );
      _fetchBookings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating booking: ${e.toString()}')),
      );
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      await _supabase
          .from('request_ride')
          .delete()
          .eq('id', bookingId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking cancelled successfully!')),
      );
      _fetchBookings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling booking: ${e.toString()}')),
      );
    }
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Booking Details', style: TextStyle(color: Color(0xFF5A3D1F))),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Status', booking['status'], 
                color: _getStatusColor(booking['status'])),
              _buildDetailRow('Pickup Point', booking['pickup_point']),
              _buildDetailRow('Dropoff Point', booking['dropoff_point']),
              _buildDetailRow('Vehicle Type', booking['vehicle_type']),
              _buildDetailRow('Departure Time', 
                DateFormat('MMM dd, yyyy - hh:mm a').format(
                  DateTime.parse(booking['departure_time']))),
              _buildDetailRow('Booking Time', 
                DateFormat('MMM dd, yyyy - hh:mm a').format(
                  DateTime.parse(booking['booking_time']))),
              _buildDetailRow('Total Cost', '\$${booking['total_cost']}'),
              if (booking['pickup_lat'] != null && booking['pickup_lng'] != null)
                _buildDetailRow('Pickup Coordinates', 
                  '${booking['pickup_lat']}, ${booking['pickup_lng']}'),
              if (booking['dropoff_lat'] != null && booking['dropoff_lng'] != null)
                _buildDetailRow('Dropoff Coordinates', 
                  '${booking['dropoff_lat']}, ${booking['dropoff_lng']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Color(0xFF5A3D1F))),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Color(0xFF5A3D1F),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.grey[700],
              fontSize: 16,
            ),
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
      default:
        return Colors.grey;
    }
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking['status']).withOpacity(0.2),
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
                    DateFormat('MMM dd').format(
                      DateTime.parse(booking['booking_time'])),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, color: Color(0xFF5A3D1F), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking['pickup_point'],
                      style: TextStyle(
                        color: Color(0xFF5A3D1F),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(left: 24),
                child: Icon(Icons.arrow_downward, color: Color(0xFF5A3D1F), size: 16),
              ),
              Row(
                children: [
                  Icon(Icons.flag, color: Color(0xFF5A3D1F), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking['dropoff_point'],
                      style: TextStyle(
                        color: Color(0xFF5A3D1F),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_car, color: Color(0xFF5A3D1F), size: 16),
                      SizedBox(width: 4),
                      Text(
                        booking['vehicle_type'],
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat('hh:mm a').format(
                      DateTime.parse(booking['departure_time'])),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              SizedBox(height: 12),
              if (booking['status'] == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _cancelBooking(booking['id']),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5A3D1F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _updateBookingStatus(
                          booking['id'], 'confirmed'),
                        child: Text(
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
          SizedBox(width: 16),
          FilterChip(
            label: Text('All'),
            selected: _filterType == 'all',
            onSelected: (selected) {
              setState(() => _filterType = 'all');
              _filterBookings();
            },
            selectedColor: Color(0xFF5A3D1F).withOpacity(0.2),
            checkmarkColor: Color(0xFF5A3D1F),
            labelStyle: TextStyle(
              color: _filterType == 'all' ? Color(0xFF5A3D1F) : Colors.grey[700],
            ),
          ),
          SizedBox(width: 8),
          FilterChip(
            label: Text('Pending'),
            selected: _filterType == 'pending',
            onSelected: (selected) {
              setState(() => _filterType = 'pending');
              _filterBookings();
            },
            selectedColor: Color(0xFF5A3D1F).withOpacity(0.2),
            checkmarkColor: Color(0xFF5A3D1F),
            labelStyle: TextStyle(
              color: _filterType == 'pending' ? Color(0xFF5A3D1F) : Colors.grey[700],
            ),
          ),
          SizedBox(width: 8),
          FilterChip(
            label: Text('Confirmed'),
            selected: _filterType == 'confirmed',
            onSelected: (selected) {
              setState(() => _filterType = 'confirmed');
              _filterBookings();
            },
            selectedColor: Color(0xFF5A3D1F).withOpacity(0.2),
            checkmarkColor: Color(0xFF5A3D1F),
            labelStyle: TextStyle(
              color: _filterType == 'confirmed' ? Color(0xFF5A3D1F) : Colors.grey[700],
            ),
          ),
          SizedBox(width: 8),
          FilterChip(
            label: Text('Cancelled'),
            selected: _filterType == 'cancelled',
            onSelected: (selected) {
              setState(() => _filterType = 'cancelled');
              _filterBookings();
            },
            selectedColor: Color(0xFF5A3D1F).withOpacity(0.2),
            checkmarkColor: Color(0xFF5A3D1F),
            labelStyle: TextStyle(
              color: _filterType == 'cancelled' ? Color(0xFF5A3D1F) : Colors.grey[700],
            ),
          ),
          SizedBox(width: 16),
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
        title: Text(
          "Booking Records",
          style: TextStyle(
            color: Color(0xFF5A3D1F),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Color(0xFF5A3D1F)),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF5A3D1F)),
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
                prefixIcon: Icon(Icons.search, color: Color(0xFF5A3D1F)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _filterBookings();
              },
            ),
          ),
          _buildFilterChips(),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  'Total Bookings: ${_filteredBookings.length}',
                  style: TextStyle(
                    color: Color(0xFF5A3D1F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Color(0xFF5A3D1F)))
                : _filteredBookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 48, color: Colors.grey[400]),
                            SizedBox(height: 16),
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
                        color: Color(0xFF5A3D1F),
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