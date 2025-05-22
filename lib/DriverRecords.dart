import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase - replace with your actual credentials
  await Supabase.initialize(
    url: 'https://your-supabase-url.supabase.co',
    anonKey: 'your-anon-key',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Driver Booking Records',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      // Define your routes here
      initialRoute: '/driver-records', // Set the initial route
      routes: {
        '/': (context) => const HomePage(), // Placeholder for Home
        '/driver-home': (context) => const HomePage(), // Explicit route for home
        '/driver-ride':
            (context) => const DriverRidePage(), // Placeholder for Add Ride
        '/driver-records':
            (context) => const DriverRecordsPage(), // Your existing page
        '/fund-account':
            (context) => const FundAccountPage(), // Placeholder for Fund Account (renamed for clarity)
      },
    );
  }
}

class DriverRecordsPage extends StatefulWidget {
  const DriverRecordsPage({Key? key}) : super(key: key);

  @override
  _RecordsPageState createState() => _RecordsPageState();
}

class _RecordsPageState extends State<DriverRecordsPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> bookings = [];
  bool isLoading = true;
  // Set initial selected index to match '/driver-records'
  // The index for 'Records' is 2 in your _BottomNavBar.
  final int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from('request_ride')
          .select('''
            id,
            ride_id,
            pickup,
            dropoff,
            booking_time,
            type,
            vehicle_type,
            departure_time,
            total_cost
          ''')
          .order('booking_time', ascending: false);

      setState(() {
        bookings = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading bookings: $e')));
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      setState(() => isLoading = true);
      await supabase.from('request_ride').delete().eq('id', bookingId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled successfully')),
      );
      await _loadBookings();
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to cancel booking: $e')));
    }
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
          'Driver Bookings',
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
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: CircleAvatar(
              backgroundColor: Color(0xFF5A3D1F).withOpacity(0.1),
              child: Icon(Icons.person, color: Color(0xFF5A3D1F)),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _BottomNavBar(selectedIndex: _selectedIndex), // Use the reusable widget
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: Color(0xFF5A3D1F)));
    }

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No bookings found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new bookings',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadBookings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5A3D1F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Refresh', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: Color(0xFF5A3D1F),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          try {
            return _buildBookingCard(booking);
          } catch (e) {
            return _buildErrorCard(e.toString());
          }
        },
      ),
    );
  }

  // Remove the local _buildBottomNavBar() method from here
  // Widget _buildBottomNavBar() { ... }

  Widget _buildErrorCard(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[400]),
                const SizedBox(width: 8),
                Text(
                  'Error loading booking',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(error, style: TextStyle(color: Colors.red[400])),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    try {
      // Parse dates
      final bookingTime =
          booking['booking_time'] != null
              ? DateTime.parse(booking['booking_time'])
              : DateTime.now();
      final departureTime =
          booking['departure_time'] != null
              ? DateTime.parse(booking['departure_time'])
              : null;

      // Format dates
      final formattedBookingDate = DateFormat('MMM d, y').format(bookingTime);
      final formattedBookingTime = DateFormat('h:mm a').format(bookingTime);
      final formattedDeparture =
          departureTime != null
              ? DateFormat('MMM d, h:mm a').format(departureTime)
              : 'Not specified';

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Booking #${booking['id']?.toString().substring(0, 8) ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking['type'] ?? 'book'),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (booking['type'] ?? 'book').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.directions_car,
                'Vehicle Type:',
                booking['vehicle_type'] ?? 'Unknown',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.location_on,
                'Pickup:',
                booking['pickup'] ?? 'Unknown location',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.location_on,
                'Dropoff:',
                booking['dropoff'] ?? 'Unknown location',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.access_time,
                'Departure:',
                formattedDeparture,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.monetization_on,
                'Total Cost:',
                '\K${booking['total_cost']?.toStringAsFixed(2) ?? '0.00'}',
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booked on $formattedBookingDate',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      Text(
                        'at $formattedBookingTime',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _showCancelDialog(booking['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.red),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return _buildErrorCard(e.toString());
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Color(0xFF5A3D1F), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
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

  Color _getStatusColor(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return Color(0xFF8B5E3B);
      case 'book':
        return Color(0xFF5A3D1F);
      default:
        return Colors.orange;
    }
  }

  Future<void> _showCancelDialog(String bookingId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cancel Booking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A3D1F),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to cancel this booking?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Color(0xFF5A3D1F)),
                        ),
                      ),
                      child: Text(
                        'No',
                        style: TextStyle(
                          color: Color(0xFF5A3D1F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _cancelBooking(bookingId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Yes, Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- Placeholder Pages ---

// Placeholder for the Home page
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Color(0xFF5A3D1F),
      ),
      body: const Center(
        child: Text(
          'Welcome to the Home Page!',
          style: TextStyle(fontSize: 24, color: Color(0xFF5A3D1F)),
        ),
      ),
      bottomNavigationBar: _BottomNavBar(selectedIndex: 0),
    );
  }
}

// Placeholder for the Driver Ride (Add Ride) page
class DriverRidePage extends StatelessWidget {
  const DriverRidePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Ride'),
        backgroundColor: Color(0xFF5A3D1F),
      ),
      body: const Center(
        child: Text(
          'This is where you can add a new ride.',
          style: TextStyle(fontSize: 24, color: Color(0xFF5A3D1F)),
        ),
      ),
      bottomNavigationBar: _BottomNavBar(selectedIndex: 1),
    );
  }
}

// Placeholder for the Fund Account page (formerly "Rides")
class FundAccountPage extends StatelessWidget {
  const FundAccountPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fund Account'),
        backgroundColor: Color(0xFF5A3D1F),
      ),
      body: const Center(
        child: Text(
          'Manage your account funds here.',
          style: TextStyle(fontSize: 24, color: Color(0xFF5A3D1F)),
        ),
      ),
      bottomNavigationBar: _BottomNavBar(selectedIndex: 3),
    );
  }
}

// Reusable Bottom Navigation Bar to avoid duplication
class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const _BottomNavBar({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    // Define the same _pages list as in MaterialApp routes
    final List<String> pages = [
      '/driver-home', // Index 0
      '/driver-ride', // Index 1
      '/driver-records', // Index 2
      '/fund-account', // Index 3
    ];

    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF5A3D1F),
      unselectedItemColor: Colors.grey[600],
      currentIndex: selectedIndex,
      onTap: (index) {
        // Use pushReplacementNamed to prevent stacking pages on top of each other
        // and to navigate to the desired route.
        Navigator.pushReplacementNamed(context, pages[index]);
      },
      type: BottomNavigationBarType.fixed,
      elevation: 10,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
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
}