import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint

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
      // Define routes for navigation
      routes: {
        '/home':
            (context) => const Center(
              child: Text('Home Page (Not implemented)'),
            ), // Replace with your actual Home page
        '/order':
            (context) => const Center(
              child: Text('Order Page (Not implemented)'),
            ), // Replace with your actual Order page
        '/records': (context) => const RecordsPage(),
        '/s-fund-account':
            (context) => const Center(
              child: Text('Fund Account Page (Not implemented)'),
            ), // Replace with your actual Fund Account page
        '/profile':
            (context) => const Center(
              child: Text('Profile Page (Not implemented)'),
            ), // Replace with your actual Profile page
        '/login':
            (context) => const Center(
              child: Text('Login Page (Not implemented)'),
            ), // Replace with your actual Login page
      },
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
  int _selectedIndex = 2; // Assuming 'Records' is at index 2
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

  /// Loads the bookings for the current user from Supabase.
  ///
  /// Sets `isLoading` to true before fetching data and to false afterwards.
  /// If no user is logged in, an exception is thrown.
  /// Fetches `id`, `ride_id`, `pickup_point`, `dropoff_point`, `booking_time`,
  /// `departure_time`, `vehicle_type`, `total_cost`, `status`, `type`,
  /// and `driver_id` from the 'request_ride' table.
  /// Then, for each booking, it fetches the driver's 'phone' and 'business_name' from 'driver_profiles'.
  /// Displays a SnackBar with an error message if loading fails.
  Future<void> _loadBookings() async {
    setState(() => isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Fetch bookings including driver_id
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
            type,
            driver_id
          ''')
          .eq('user_id', userId)
          .order('booking_time', ascending: false);

      List<Map<String, dynamic>> fetchedBookings =
          List<Map<String, dynamic>>.from(response);

      // Fetch driver phone numbers and business names for each booking
      for (var booking in fetchedBookings) {
        final driverId = booking['driver_id'];
        debugPrint(
          'Processing booking with driverId: $driverId',
        ); // Debug print
        if (driverId != null) {
          try {
            final driverProfile =
                await supabase
                    .from('driver_profiles')
                    .select(
                      'phone, business_name',
                    ) // Select business_name as well
                    .eq('user_id', driverId)
                    .maybeSingle(); // Use maybeSingle to handle cases where no profile is found

            debugPrint(
              'Driver profile response for $driverId: $driverProfile',
            ); // Debug print

            if (driverProfile != null) {
              booking['driver_phone'] =
                  driverProfile['phone']?.toString() ?? 'N/A';
              booking['driver_business_name'] =
                  driverProfile['business_name']?.toString() ?? 'N/A';
            } else {
              booking['driver_phone'] = 'N/A'; // Default if phone not found
              booking['driver_business_name'] =
                  'N/A'; // Default if business name not found
            }
          } catch (e) {
            debugPrint('Error fetching driver profile for ID $driverId: $e');
            booking['driver_phone'] = 'Error'; // Indicate an error occurred
            booking['driver_business_name'] =
                'Error'; // Indicate an error occurred
          }
        } else {
          booking['driver_phone'] = 'N/A'; // Default if driver_id is null
          booking['driver_business_name'] =
              'N/A'; // Default if driver_id is null
        }
      }

      setState(() {
        bookings = fetchedBookings;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading bookings: $e')));
      }
    }
  }

  /// Cancels a booking by its ID.
  ///
  /// Deletes the booking from the 'request_ride' table in Supabase.
  /// Displays a success message or an error message using a SnackBar.
  /// Reloads the bookings after a successful cancellation.
  Future<void> _cancelBooking(String bookingId) async {
    try {
      setState(() => isLoading = true);
      await supabase.from('request_ride').delete().eq('id', bookingId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
      }
      await _loadBookings();
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to cancel booking: $e')));
      }
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
            onPressed: () {
              // Handle notifications
            },
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

  /// Builds the main body of the page.
  /// Displays a loading indicator if `isLoading` is true.
  /// If `bookings` is empty, displays a message and a refresh button.
  /// Otherwise, displays a list of booking cards with a `RefreshIndicator`.
  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5A3D1F)),
      );
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
                backgroundColor: const Color(0xFF5A3D1F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: const Color(0xFF5A3D1F),
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

  /// Builds the bottom navigation bar for the application.
  ///
  /// Highlights the selected item and navigates to the corresponding page.
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF5A3D1F),
      unselectedItemColor: Colors.grey[600],
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() => _selectedIndex = index);
        Navigator.pushNamed(context, _pages[index]);
      },
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
          icon: Icon(Icons.directions_bus_outlined),
          activeIcon: Icon(Icons.directions_bus),
          label: "Request Ride",
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

  /// Builds an error card to display when there's an issue loading a booking.
  Widget _buildErrorCard(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
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

  /// Builds a `Card` widget to display individual booking details.
  ///
  /// Parses and formats booking time, departure time, and total cost.
  /// Always includes a "Cancel" button.
  Widget _buildBookingCard(Map<String, dynamic> booking) {
    try {
      final bookingTime =
          booking['booking_time'] != null
              ? DateTime.tryParse(booking['booking_time']) ?? DateTime.now()
              : DateTime.now();

      final departureTime =
          booking['departure_time'] != null
              ? DateTime.tryParse(booking['departure_time'])
              : null;

      final formattedBookingDate = DateFormat('MMM d, y').format(bookingTime);
      final formattedBookingTime = DateFormat('h:mm a').format(bookingTime);
      final formattedDeparture =
          departureTime != null
              ? DateFormat('MMM d, h:mm a').format(departureTime)
              : 'Not specified';

      final price =
          booking['total_cost'] != null
              ? NumberFormat.currency(
                symbol: 'K ',
              ).format(booking['total_cost'])
              : 'K 0.00';

      final driverPhone =
          booking['driver_phone']?.toString() ?? 'N/A'; // Get driver phone
      final driverBusinessName =
          booking['driver_business_name']?.toString() ??
          'N/A'; // Get driver business name

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            // Corrected: Removed extra 'box' keyword
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Display Driver's Business Name at the top
              _buildInfoRow(
                Icons.business,
                'Driver Company:',
                driverBusinessName,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.directions_car,
                'Vehicle Type:',
                booking['vehicle_type']?.toString() ?? 'Not specified',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.location_on,
                'Pickup:',
                booking['pickup_point']?.toString() ?? 'Unknown location',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.location_on,
                'Dropoff:',
                booking['dropoff_point']?.toString() ?? 'Unknown location',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.access_time,
                'Departure:',
                formattedDeparture,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.attach_money,
                'Total Cost:',
                price,
              ), // Changed icon to Icons.attach_money
              const SizedBox(height: 12),
              // Display Driver's Phone Number
              _buildInfoRow(Icons.phone, 'Driver Contact:', driverPhone),
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
                  // The cancel button is now always displayed, regardless of status
                  ElevatedButton(
                    onPressed:
                        () =>
                            _showCancelDialog(booking['id']?.toString() ?? ''),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.red),
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

  /// Formats a booking ID for display, truncating long IDs.
  String _formatBookingId(dynamic id) {
    if (id == null) return 'N/A';
    final idStr = id.toString();
    if (idStr.isEmpty) return 'N/A';
    return idStr.length <= 8
        ? idStr
        : '...${idStr.substring(idStr.length - 5)}';
  }

  /// Builds a row to display an icon, label, and value for booking information.
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF5A3D1F), size: 20),
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
                style: const TextStyle(
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

  /// Returns a color based on the booking status.
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

  /// Shows a confirmation dialog for canceling a booking.
  ///
  /// If the user confirms, the `_cancelBooking` method is called.
  Future<void> _showCancelDialog(String bookingId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // User can dismiss by tapping outside
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
                const Text(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFF5A3D1F)),
                        ),
                      ),
                      child: const Text(
                        'No',
                        style: TextStyle(
                          color: Color(0xFF5A3D1F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        _cancelBooking(bookingId); // Perform the cancellation
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
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

  /// Shows a modal bottom sheet with profile options (Profile, Logout).
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

  /// Shows a confirmation dialog for logging out.
  ///
  /// If the user confirms, the `_logout` method is called.
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

  /// Logs the user out from Supabase and navigates to the login page.
  /// Displays a SnackBar with an error message if logout fails.
  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
