import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class RecordsPage extends StatefulWidget {
  final String? selectedVehicleType;

  const RecordsPage({Key? key, this.selectedVehicleType}) : super(key: key);

  @override
  _RecordsPageState createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> availableRides = [];
  bool isLoading = true;
  int _selectedIndex = 3;
  final List<String> _pages = ['/', '/order', '/book', '/records'];

  @override
  void initState() {
    super.initState();
    _loadAvailableRides();
  }

  Future<void> _loadAvailableRides() async {
    setState(() => isLoading = true);
    
    try {
      final response = await supabase
          .from('ride')
          .select('*')
          .order('departure_time', ascending: true);

      setState(() {
        availableRides = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading rides: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: Color(0xFF8B5E3B),
        title: Text('Available Rides', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAvailableRides,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : availableRides.isEmpty
              ? Center(child: Text('No available rides found'))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: availableRides.length,
                  itemBuilder: (context, index) {
                    final ride = availableRides[index];
                    try {
                      return _buildRideCard(ride);
                    } catch (e) {
                      return _buildErrorCard(e.toString());
                    }
                  },
                ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF8B5E3B),
        unselectedItemColor: Color(0xFF5A3D1F),
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          Navigator.pushNamed(context, _pages[index]);
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_bus), label: "Order"),
          BottomNavigationBarItem(icon: Icon(Icons.book_online), label: "Book"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Add Ride"),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      color: Colors.red[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Error loading ride',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride) {
    try {
      // Parse departure time with error handling
      final departureTime = ride['departure_time'] != null
          ? DateTime.parse(ride['departure_time'])
          : DateTime.now();
      
      final formattedDate = DateFormat('EEE, MMM d').format(departureTime);
      final formattedTime = DateFormat('h:mm a').format(departureTime);
      
      // Handle null values for capacity
      final seatsAvailable = ride['capacity'] is int ? ride['capacity'] : 0;
      final isFull = seatsAvailable <= 0;
      
      // Handle null values for total_cost
      final totalCost = ride['total_cost'] is num 
          ? (ride['total_cost'] as num).toDouble() 
          : 0.0;

      return Card(
        elevation: 4,
        margin: EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ride #${ride['ride_number']?.toString() ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
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
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.route, color: Color(0xFF8B5E3B), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride['route']?.toString() ?? 'No route specified',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Color(0xFF8B5E3B), size: 20),
                  SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.access_time, color: Color(0xFF8B5E3B), size: 20),
                  SizedBox(width: 8),
                  Text(
                    formattedTime,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Cost:',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Text(
                    '\$${totalCost.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B5E3B),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: isFull ? null : () => _bookRide(ride),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8B5E3B),
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isFull ? 'NO SEATS AVAILABLE' : 'BOOK THIS RIDE',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Future<void> _bookRide(Map<String, dynamic> ride) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking ride #${ride['ride_number']}...')),
      );
      // Implement your actual booking logic here
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book ride: $e')),
      );
    }
  }
}