import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // For date and time formatting
import 'package:flutter/foundation.dart'; // Import for debugPrint

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({Key? key}) : super(key: key);

  @override
  _DriverHomePageState createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  final _supabase = Supabase.instance.client;
  int _selectedIndex = 0; // Retained as per your provided code
  final List<String> _pages = [
    '/driver-home',
    '/driver-ride',
    '/driver-records',
    '/fund-account',
  ];
  // PageController is no longer used in _buildDashboardCards, but kept if it's used elsewhere
  // final PageController _pageController = PageController(viewportFraction: 0.85);
  // int _currentPage = 0; // No longer needed if PageView is not used with a listener

  String _businessName = '';
  bool _isLoading = true; // Unified loading state

  // Stats variables
  int _totalAvailableRides = 0;
  int _totalBookings = 0;
  double _totalDistance = 0;
  int _totalFullRides = 0;
  int _totalUnfullRides = 0;
  Map<String, dynamic>? _nearestRide;
  Map<String, dynamic>? _recentBooking;

  // New state variables for ride status counts
  int _cancelledRides = 0;
  int _confirmedRides = 0;
  int _pendingRides = 0;
  // Removed _inProgressRides as per your clarification

  @override
  void initState() {
    super.initState();
    _fetchDriverData();
    // Removed _pageController listener as PageView is now a Row with fixed children
    // If you reintroduce PageView with dynamic children, you might need this listener again.
  }

  Future<void> _fetchDriverData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    try {
      // Fetch business name
      final profileResponse =
          await _supabase
              .from('driver_profiles')
              .select('business_name')
              .eq('user_id', user.id)
              .single();

      if (mounted) {
        // Check mounted before setState
        setState(() {
          _businessName =
              profileResponse['business_name']?.toString() ?? 'Your Business';
        });
      }

      // Fetch all stats data concurrently
      await Future.wait([
        _fetchTotalAvailableRides(user.id),
        _fetchTotalBookings(user.id),
        _fetchTotalDistance(user.id),
        _fetchRideCapacityStats(user.id),
        _fetchNearestRide(user.id),
        _fetchRecentBooking(user.id),
        _fetchRideStatusCounts(user.id), // Fetch new ride status counts
      ]);
    } catch (e) {
      print('Error fetching driver data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        // Check mounted before setState
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchTotalAvailableRides(String userId) async {
    final response = await _supabase
        .from('ride')
        .select('id') // Select a column to get a list
        .eq('driver_id', userId);

    if (mounted) {
      // Check mounted before setState
      setState(() {
        _totalAvailableRides = (response as List?)?.length ?? 0;
      });
    }
  }

  Future<void> _fetchTotalBookings(String userId) async {
    final response = await _supabase
        .from('request_ride')
        .select('id') // Select a column to get a list
        .eq('driver_id', userId);

    if (mounted) {
      // Check mounted before setState
      setState(() {
        _totalBookings = (response as List?)?.length ?? 0;
      });
    }
  }

  Future<void> _fetchTotalDistance(String userId) async {
    final response = await _supabase
        .from('ride')
        .select('distance')
        .eq('driver_id', userId);

    double total = 0;
    // Ensure response is a List before iterating
    if (response != null && response is List) {
      for (var ride in response) {
        total += (ride['distance'] as num?)?.toDouble() ?? 0.0;
      }
    }

    if (mounted) {
      // Check mounted before setState
      setState(() {
        _totalDistance = total;
      });
    }
  }

  Future<void> _fetchRideCapacityStats(String userId) async {
    final fullRidesResponse = await _supabase
        .from('ride')
        .select('id') // Select a column to get a list
        .eq('driver_id', userId)
        .eq('remaining_capacity', 0);

    final unfullRidesResponse = await _supabase
        .from('ride')
        .select('id') // Select a column to get a list
        .eq('driver_id', userId)
        .gt('remaining_capacity', 0);

    if (mounted) {
      // Check mounted before setState
      setState(() {
        _totalFullRides = (fullRidesResponse as List?)?.length ?? 0;
        _totalUnfullRides = (unfullRidesResponse as List?)?.length ?? 0;
      });
    }
  }

  /// Fetches the number of cancelled, confirmed, and pending rides
  /// for the logged-in driver from the 'request_ride' table.
  Future<void> _fetchRideStatusCounts(String userId) async {
    debugPrint('Fetching ride status counts for driver_id: $userId');
    try {
      final response = await _supabase
          .from('request_ride')
          .select('status')
          .eq('driver_id', userId);

      debugPrint('Supabase response for ride status: $response');

      int cancelled = 0;
      int confirmed = 0;
      int pending = 0;
      // Removed inProgress as per your clarification

      if (response != null && response is List) {
        for (var booking in response) {
          final status = booking['status']?.toLowerCase();
          if (status == 'cancelled') {
            cancelled++;
          } else if (status == 'confirmed') {
            confirmed++;
          } else if (status == 'pending') {
            pending++;
          }
          // Removed 'in_progress' check
        }
      }

      if (mounted) {
        setState(() {
          _cancelledRides = cancelled;
          _confirmedRides = confirmed;
          _pendingRides = pending;
          // Removed _inProgressRides from setState
        });
        debugPrint(
          'Updated ride status counts: Confirmed: $_confirmedRides, Pending: $_pendingRides, Cancelled: $_cancelledRides',
        );
      }
    } catch (e) {
      debugPrint('Error fetching ride status counts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching ride status: $e')),
        );
      }
    }
  }

  Future<void> _fetchNearestRide(String userId) async {
    final now = DateTime.now().toIso8601String();

    final response = await _supabase
        .from('ride')
        .select('*')
        .eq('driver_id', userId)
        .gte('departure_time', now)
        .order('departure_time', ascending: true)
        .limit(1);

    if (mounted) {
      // Check mounted before setState
      if (response != null && response is List && response.isNotEmpty) {
        setState(() {
          _nearestRide = response[0];
        });
      } else {
        setState(() {
          _nearestRide = null; // Ensure it's null if no ride found
        });
      }
    }
  }

  Future<void> _fetchRecentBooking(String userId) async {
    // First, fetch the recent booking without trying to join user_profiles
    final bookingResponse = await _supabase
        .from('request_ride')
        .select('*, user_id') // Select user_id to fetch user profile separately
        .eq('driver_id', userId)
        .order('created_at', ascending: false)
        .limit(1);

    if (mounted) {
      // Check mounted before setState
      if (bookingResponse != null &&
          bookingResponse is List &&
          bookingResponse.isNotEmpty) {
        final recentBookingData = bookingResponse[0];
        final passengerUserId = recentBookingData['user_id']?.toString();

        String? passengerBusinessName = 'Passenger'; // Default value

        if (passengerUserId != null) {
          try {
            // Fetch passenger profile from 'driver_profiles' as requested
            final userProfileResponse =
                await _supabase
                    .from('driver_profiles') // Changed to 'driver_profiles'
                    .select(
                      'business_name',
                    ) // Changed to business_name as requested
                    .eq('user_id', passengerUserId)
                    .maybeSingle(); // Use maybeSingle for nullable result

            passengerBusinessName =
                userProfileResponse?['business_name']?.toString() ??
                'Passenger';
          } catch (e) {
            print('Error fetching passenger profile for recent booking: $e');
            // Fallback if user profile fetch fails
            passengerBusinessName = 'Unknown Passenger';
          }
        }

        // Create a combined map for the recent booking
        setState(() {
          _recentBooking = {
            ...recentBookingData,
            // Use 'user_profiles' as the key for UI consistency, but value is business_name
            'user_profiles': {'full_name': passengerBusinessName},
          };
        });
      } else {
        setState(() {
          _recentBooking = null; // Ensure it's null if no booking found
        });
      }
    }
  }

  // This _onItemTapped is for the BottomNavigationBar
  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    if (mounted) {
      // Check mounted before setState
      setState(() => _selectedIndex = index);
    }
    Navigator.pushReplacementNamed(context, _pages[index]);
  }

  @override
  void dispose() {
    // Removed _pageController.dispose() as it's no longer a state variable
    super.dispose();
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
          content: Text(
            "Are you sure you want to logout?",
            style: TextStyle(color: Colors.grey[700]),
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
      await _supabase.auth.signOut();
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

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  style: TextStyle(color: Color(0xFF5A3D1F)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              Divider(height: 20, color: Colors.grey[200]),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
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

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome,",
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _businessName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A3D1F),
            letterSpacing: 1.0,
            shadows: [
              Shadow(
                offset: Offset(1.0, 1.0),
                blurRadius: 3.0,
                color: Colors.black12,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardCards() {
    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 5.0),
              child: _buildActionCard(
                title: "Add Ride",
                subtitle: "Create a new ride offer",
                icon: Icons.add_road_rounded,
                color: const Color(0xFF8B5E3B),
                onTap: () => Navigator.pushNamed(context, '/driver-ride'),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 5.0),
              child: _buildActionCard(
                title: "View Records",
                subtitle: "See your bookings",
                icon: Icons.history_rounded,
                color: const Color(0xFF5A3D1F),
                onTap: () => Navigator.pushNamed(context, '/driver-records'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 150),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16, // Slightly reduced font size
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ), // Slightly reduced font size
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      padding: const EdgeInsets.all(0),
      children: [
        _buildStatCard(
          title: "Available Rides",
          value: _totalAvailableRides.toString(),
          icon: Icons.directions_car,
          color: const Color(0xFF8B5E3B),
        ),
        _buildStatCard(
          title: "Total Bookings",
          value: _totalBookings.toString(),
          icon: Icons.bookmark,
          color: const Color(0xFF5A3D1F),
        ),
        _buildStatCard(
          title: "Total Distance",
          value: "${_totalDistance.toStringAsFixed(1)} km",
          icon: Icons.linear_scale,
          color: const Color(0xFF3A2A15),
        ),
        _buildStatCard(
          title: "Ride Capacity", // Changed title for clarity
          value: "$_totalFullRides Full / $_totalUnfullRides Open",
          icon: Icons.people,
          color: const Color(0xFF6D4C3D),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 150),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18, // Slightly reduced font size
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ), // Slightly reduced font size
                maxLines: 1, // Ensure title doesn't overflow
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a section to display the counts of rides by their status.
  Widget _buildRideStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Booking Status Overview",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A3D1F),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, // Display two cards per row
          childAspectRatio: 1.5, // Adjust aspect ratio for better display
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          padding: const EdgeInsets.all(0),
          children: [
            _buildStatCard(
              title: "Confirmed Rides",
              value: _confirmedRides.toString(),
              icon: Icons.check_circle_outline,
              color: Colors.green,
            ),
            _buildStatCard(
              title: "Pending Rides",
              value: _pendingRides.toString(),
              icon: Icons.hourglass_empty,
              color: Colors.orange,
            ),
            // Removed 'In Progress Rides' card
            _buildStatCard(
              title: "Cancelled Rides",
              value: _cancelledRides.toString(),
              icon: Icons.cancel_outlined,
              color: Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpcomingRideCard() {
    if (_nearestRide == null) return const SizedBox.shrink();

    final departureTime = DateTime.parse(_nearestRide!['departure_time']);
    final formattedTime = DateFormat('MMM dd, hh:mm a').format(departureTime);
    final remainingTime = _formatRemainingTime(departureTime);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF5A3D1F).withOpacity(0.9),
            const Color(0xFF8B5E3B).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                "Upcoming Ride",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            // Ensure these keys exist in your 'ride' table
            "${_nearestRide!['pickup_point'] ?? 'N/A'} to ${_nearestRide!['dropoff_point'] ?? 'N/A'}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            // Using Wrap to handle potential overflow in detail items
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildRideDetailItem(
                icon: Icons.calendar_today,
                text: formattedTime,
              ),
              _buildRideDetailItem(icon: Icons.timelapse, text: remainingTime),
              _buildRideDetailItem(
                icon: Icons.people,
                text:
                    "${(_nearestRide!['capacity'] as int? ?? 0) - (_nearestRide!['remaining_capacity'] as int? ?? 0)}/${_nearestRide!['capacity']?.toString() ?? '0'} seats",
              ),
              _buildRideDetailItem(
                icon: Icons.attach_money,
                text:
                    "K ${_nearestRide!['total_cost']?.toStringAsFixed(2) ?? '0.00'}",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookingCard() {
    if (_recentBooking == null) return const SizedBox.shrink();

    final bookingTime = DateTime.parse(_recentBooking!['created_at']);
    final formattedTime = DateFormat('MMM dd, hh:mm a').format(bookingTime);
    // Use 'full_name' key for UI consistency, but its value is now 'business_name' from driver_profiles
    final passengerName =
        _recentBooking!['user_profiles']?['full_name']?.toString() ??
        'Passenger';

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minWidth: double.infinity),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF5A3D1F), size: 20),
              const SizedBox(width: 8),
              Text(
                "Recent Booking",
                style: const TextStyle(
                  color: Color(0xFF5A3D1F),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Booked by $passengerName",
            style: const TextStyle(
              color: Color(0xFF5A3D1F),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            // Using Wrap to handle potential overflow in detail items
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildBookingDetailItem(
                icon: Icons.calendar_today,
                text: formattedTime,
                color: const Color(0xFF8B5E3B),
              ),
              _buildBookingDetailItem(
                icon: Icons.location_on,
                text: _recentBooking!['pickup_point']?.toString() ?? 'N/A',
                color: const Color(0xFF5A3D1F),
              ),
              _buildBookingDetailItem(
                icon: Icons.flag,
                text: _recentBooking!['dropoff_point']?.toString() ?? 'N/A',
                color: const Color(0xFF3A2A15),
              ),
              _buildBookingDetailItem(
                icon: Icons.attach_money,
                text:
                    "K ${_recentBooking!['total_cost']?.toStringAsFixed(2) ?? '0.00'}",
                color: const Color(0xFF6D4C3D),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRideDetailItem({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildBookingDetailItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return SizedBox(
      width: 120, // Give a fixed width to allow wrapping within the item
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Expanded(
            // Ensure text expands within the SizedBox
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
              ), // Smaller font for detail items
              overflow: TextOverflow.ellipsis,
              maxLines: 2, // Allow text to wrap if needed
            ),
          ),
        ],
      ),
    );
  }

  String _formatRemainingTime(DateTime departureTime) {
    final now = DateTime.now();
    final difference = departureTime.difference(now);

    if (difference.isNegative) {
      return "Departed";
    } else if (difference.inDays > 0) {
      return "${difference.inDays}d ${difference.inHours.remainder(24)}h left";
    } else if (difference.inHours > 0) {
      return "${difference.inHours}h ${difference.inMinutes.remainder(60)}m left";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes}m left";
    } else {
      return "Departing soon";
    }
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF5A3D1F),
      unselectedItemColor: Colors.grey[600],
      currentIndex: _selectedIndex, // Use _selectedIndex here
      onTap: _onItemTapped, // Use the defined _onItemTapped
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
          "EasyRide",
          style: TextStyle(
            color: Color(0xFF5A3D1F),
            fontWeight: FontWeight.bold,
            fontSize: 28,
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
                backgroundColor: const Color(
                  0xFF5A3D1F,
                ).withAlpha((255 * 0.1).round()),
                child: const Icon(Icons.person, color: Color(0xFF5A3D1F)),
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A3D1F)),
                ),
              )
              : RefreshIndicator(
                onRefresh: _fetchDriverData, // Refresh all data
                color: const Color(0xFF5A3D1F),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeHeader(),
                        const SizedBox(height: 20),
                        _buildDashboardCards(),
                        const SizedBox(height: 20),
                        _buildStatsGrid(),
                        const SizedBox(height: 20),
                        _buildRideStatusSection(), // New section for ride status counts
                        if (_nearestRide != null) ...[
                          const SizedBox(height: 20),
                          _buildUpcomingRideCard(),
                        ],
                        if (_recentBooking != null) ...[
                          const SizedBox(height: 20),
                          _buildRecentBookingCard(),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}
