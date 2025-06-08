import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({Key? key}) : super(key: key);

  @override
  _DriverHomePageState createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  final _supabase = Supabase.instance.client;
  int _selectedIndex = 0;
  final List<String> _pages = [
    '/driver-home',
    '/driver-ride',
    '/driver-records',
    '/driver-fund-account',
  ];

  String _businessName = '';
  bool _isLoading = true;

  // Stats variables
  int _totalAvailableRides = 0;
  int _totalBookings = 0;
  double _totalDistance = 0;
  int _totalFullRides = 0;
  int _totalUnfullRides = 0;

  // Ride status counts
  int _cancelledRides = 0;
  int _confirmedRides = 0;
  int _pendingRides = 0;

  @override
  void initState() {
    super.initState();
    _fetchDriverData();
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
        _fetchRideStatusCounts(user.id),
      ]);
    } catch (e) {
      debugPrint('Error fetching driver data: $e');
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchTotalAvailableRides(String userId) async {
    final response = await _supabase
        .from('ride')
        .select('id')
        .eq('driver_id', userId);

    if (mounted) {
      setState(() {
        _totalAvailableRides = (response as List?)?.length ?? 0;
      });
    }
  }

  Future<void> _fetchTotalBookings(String userId) async {
    final response = await _supabase
        .from('request_ride')
        .select('id')
        .eq('driver_id', userId);

    if (mounted) {
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
    if (response != null && response is List) {
      for (var ride in response) {
        total += (ride['distance'] as num?)?.toDouble() ?? 0.0;
      }
    }

    if (mounted) {
      setState(() {
        _totalDistance = total;
      });
    }
  }

  Future<void> _fetchRideCapacityStats(String userId) async {
    final fullRidesResponse = await _supabase
        .from('ride')
        .select('id')
        .eq('driver_id', userId)
        .eq('remaining_capacity', 0);

    final unfullRidesResponse = await _supabase
        .from('ride')
        .select('id')
        .eq('driver_id', userId)
        .gt('remaining_capacity', 0);

    if (mounted) {
      setState(() {
        _totalFullRides = (fullRidesResponse as List?)?.length ?? 0;
        _totalUnfullRides = (unfullRidesResponse as List?)?.length ?? 0;
      });
    }
  }

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
        }
      }

      if (mounted) {
        setState(() {
          _cancelledRides = cancelled;
          _confirmedRides = confirmed;
          _pendingRides = pending;
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

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    if (mounted) {
      setState(() => _selectedIndex = index);
    }
    Navigator.pushReplacementNamed(context, _pages[index]);
  }

  @override
  void dispose() {
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
    return Row(
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
          title: "Ride Capacity",
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
      constraints: const BoxConstraints(minHeight: 100),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

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
          crossAxisCount: 2,
          childAspectRatio: 1.5,
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
                onRefresh: _fetchDriverData,
                color: const Color(0xFF5A3D1F),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildWelcomeHeader(),
                      const SizedBox(height: 30),
                      _buildDashboardCards(),
                      const SizedBox(height: 30),
                      const Text(
                        "Your Stats",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5A3D1F),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatsGrid(),
                      const SizedBox(height: 30),
                      _buildRideStatusSection(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
      bottomNavigationBar: BottomNavigationBar(
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
      ),
    );
  }
}
