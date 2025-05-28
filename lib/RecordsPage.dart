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
      title: 'Booking Records',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: const RecordsPage(),
    );
  }
}

class RecordsPage extends StatefulWidget {
  const RecordsPage({Key? key}) : super(key: key);

  @override
  _RecordsPageState createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> bookings = [];
  bool isLoading = true;
  int _selectedIndex = 2;
  final List<String> _pages = [
    '/home',
    '/order',
    '/records',
    '/s-fund-account',
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => isLoading = true);

    try {
      // Get current user ID
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await supabase
          .from('request_ride')
          .select('''
            id,
            ride_id,
            pickup_point,
            dropoff_point,
            booking_time,
            departure_time,
            vehicle_type,
            total_cost,
            status,
            type
          ''')
          .eq('user_id', userId) // Filter by current user's ID
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
          'My Bookings',
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
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: _showProfileMenu,
              child: CircleAvatar(
                backgroundColor: const Color(0xFF5A3D1F).withOpacity(0.1),
                child: const Icon(Icons.person, color: Color(0xFF5A3D1F)),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
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
              'Your booking history will appear here',
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

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF5A3D1F),
      unselectedItemColor: Colors.grey[600],
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() => _selectedIndex = index);
        Navigator.pushNamed(context, _pages[index]);
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
          icon: Icon(Icons.directions_bus_outlined),
          activeIcon: Icon(Icons.directions_bus),
          label: "Order",
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
      // Safely parse dates with null checks
      final bookingTime =
          booking['booking_time'] != null
              ? DateTime.tryParse(booking['booking_time']) ?? DateTime.now()
              : DateTime.now();

      final departureTime =
          booking['departure_time'] != null
              ? DateTime.tryParse(booking['departure_time'])
              : null;

      // Format dates safely
      final formattedBookingDate = DateFormat('MMM d, y').format(bookingTime);
      final formattedBookingTime = DateFormat('h:mm a').format(bookingTime);
      final formattedDeparture =
          departureTime != null
              ? DateFormat('MMM d, h:mm a').format(departureTime)
              : 'Not specified';

      // Safely format price with null check
      final price =
          booking['total_cost'] != null
              ? NumberFormat.currency(
                symbol: '\$',
              ).format(booking['total_cost'])
              : '\$0.00';

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
              // Booking header with ID and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Booking #${_formatBookingId(booking['id'])}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking['status'] ?? 'pending'),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (booking['status'] ?? 'pending').toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Vehicle Type
              _buildInfoRow(
                Icons.directions_car,
                'Vehicle Type:',
                booking['vehicle_type']?.toString() ?? 'Not specified',
              ),
              const SizedBox(height: 12),

              // Pickup Point
              _buildInfoRow(
                Icons.location_on,
                'Pickup:',
                booking['pickup_point']?.toString() ?? 'Unknown location',
              ),
              const SizedBox(height: 12),

              // Dropoff Point
              _buildInfoRow(
                Icons.location_on,
                'Dropoff:',
                booking['dropoff_point']?.toString() ?? 'Unknown location',
              ),
              const SizedBox(height: 12),

              // Departure Time
              _buildInfoRow(
                Icons.access_time,
                'Departure:',
                formattedDeparture,
              ),
              const SizedBox(height: 12),

              // Total Cost
              _buildInfoRow(Icons.monetization_on, 'Total Cost:', price),
              const SizedBox(height: 16),

              // Divider
              Divider(height: 1, color: Colors.grey[300]),
              const SizedBox(height: 12),

              // Footer with booking time and cancel button
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
                  if ((booking['status'] ?? 'pending') == 'pending')
                    ElevatedButton(
                      onPressed:
                          () => _showCancelDialog(
                            booking['id']?.toString() ?? '',
                          ),
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
    } catch (e, stackTrace) {
      debugPrint('Error building booking card: $e');
      debugPrint('Stack trace: $stackTrace');
      return _buildErrorCard('Failed to load booking details. Tap to retry.');
    }
  }

  String _formatBookingId(dynamic id) {
    if (id == null) return 'N/A';
    final idStr = id.toString();
    if (idStr.isEmpty) return 'N/A';
    return idStr.length <= 8
        ? idStr
        : '...${idStr.substring(idStr.length - 5)}';
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
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

  Future<void> _showProfileMenu() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 5,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF5A3D1F)),
                title: const Text(
                  "Profile",
                  style: TextStyle(
                    color: Color(0xFF5A3D1F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              const Divider(height: 20, color: Colors.grey),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Logout",
            style: TextStyle(
              color: Color(0xFF5A3D1F),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "Are you sure you want to logout?",
            style: TextStyle(color: Color.fromARGB(255, 120, 119, 119)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Color(0xFF5A3D1F)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A3D1F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout();
              },
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
