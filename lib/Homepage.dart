import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<String> _pages = [
    '/home',
    '/order',
    '/records',
    '/s-fund-account',
  ];
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  String _userName = '';
  String _userEmail = '';
  String _userAddress = '';
  bool _isLoading = true;

  // Statistics variables
  int _totalAvailableRides = 0;
  int _totalBookings = 0;
  double _totalCashToBeSpent = 0;
  int _totalUnfullRides = 0;
  Map<String, dynamic>? _recentBooking;

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_updateCurrentPage);
    _fetchData();
  }

  void _updateCurrentPage() {
    if (mounted) {
      // Check mounted before setState
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    }
  }

  Future<void> _fetchData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Fetch user profile
        final profileResponse =
            await _supabase
                .from('passenger_profiles')
                .select()
                .eq('user_id', user.id)
                .maybeSingle();

        if (mounted) {
          // Check mounted before setState
          if (profileResponse != null) {
            setState(() {
              _userName = profileResponse['full_name']?.toString() ?? '';
              _userEmail = profileResponse['email']?.toString() ?? '';
              _userAddress = profileResponse['address']?.toString() ?? '';
            });
          }
        }

        // Fetch statistics
        await _fetchStatistics(user.id);
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
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

  Future<void> _fetchStatistics(String userId) async {
    try {
      // Total available rides
      final ridesResponse = await _supabase
          .from('ride')
          .select('id'); // Fetch data and get length

      if (mounted) {
        // Check mounted before setState
        setState(() {
          _totalAvailableRides = (ridesResponse as List?)?.length ?? 0;
        });
      }

      // Total bookings for this user
      final bookingsResponse = await _supabase
          .from('request_ride')
          .select('id') // Fetch data and get length
          .eq('user_id', userId);

      if (mounted) {
        // Check mounted before setState
        setState(() {
          _totalBookings = (bookingsResponse as List?)?.length ?? 0;
        });
      }

      // Total cash to be spent
      final cashResponse = await _supabase
          .from('request_ride')
          .select('total_cost')
          .eq('user_id', userId);
      double total = 0;
      if (cashResponse != null && cashResponse is List) {
        for (var item in cashResponse) {
          total += (item['total_cost'] as num?)?.toDouble() ?? 0.0;
        }
      }
      if (mounted) {
        // Check mounted before setState
        setState(() {
          _totalCashToBeSpent = total;
        });
      }

      // Total unfull rides (remaining_capacity > 0)
      final unfullRidesResponse = await _supabase
          .from('ride')
          .select('id') // Fetch data and get length
          .gt('remaining_capacity', 0);

      if (mounted) {
        // Check mounted before setState
        setState(() {
          _totalUnfullRides = (unfullRidesResponse as List?)?.length ?? 0;
        });
      }

      // Most recent booking
      final recentBookingResponse =
          await _supabase
              .from('request_ride')
              .select()
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

      if (mounted) {
        // Check mounted before setState
        if (recentBookingResponse != null) {
          setState(() {
            _recentBooking = recentBookingResponse;
          });
        } else {
          setState(() {
            _recentBooking = null; // Ensure it's null if no booking found
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching statistics: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching statistics: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_updateCurrentPage);
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    if (mounted) {
      // Check mounted before setState
      setState(() => _selectedIndex = index);
    }
    Navigator.pushReplacementNamed(context, _pages[index]);
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
              Divider(height: 20, color: Colors.grey[200]),
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
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF5A3D1F)),
              )
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      _buildWelcomeSection(),
                      const SizedBox(height: 25),
                      _buildDashboardCards(),
                      const SizedBox(height: 25),
                      _buildStatisticsSection(),
                      if (_recentBooking != null) ...[
                        const SizedBox(height: 25),
                        _buildRecentBookingSection(),
                      ],
                    ],
                  ),
                ),
              ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome back,",
          style: TextStyle(
            fontSize: 20,
            color: const Color(0xFF5A3D1F),
            fontWeight: FontWeight.normal,
          ),
        ),
        Text(
          _userName.isNotEmpty ? "$_userName!" : "Passenger!",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5A3D1F),
            letterSpacing: 1.0,
            shadows: [
              Shadow(
                offset: const Offset(1.0, 1.0),
                blurRadius: 3.0,
                color: Colors.black.withOpacity(0.2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_userEmail.isNotEmpty || _userAddress.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF5A3D1F).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF5A3D1F).withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_userEmail.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.email,
                        size: 16,
                        color: Color(0xFF5A3D1F),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _userEmail,
                        style: const TextStyle(color: Color(0xFF5A3D1F)),
                      ),
                    ],
                  ),
                if (_userAddress.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFF5A3D1F),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _userAddress,
                          style: const TextStyle(color: Color(0xFF5A3D1F)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDashboardCards() {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView(
            controller: _pageController,
            padEnds: false,
            children: [
              _buildDashboardCard(
                icon: Icons.directions_car,
                title: "Instant Ride",
                subtitle: "Book now with 1 tap",
                buttonText: "Request Now",
                gradientColors: const [Color(0xFF8B5E3B), Color(0xFF5A3D1F)],
                onTap: () => Navigator.pushNamed(context, '/order'),
              ),
              _buildDashboardCard(
                icon: Icons.history,
                title: "Your Journeys",
                subtitle: "Past trips & receipts",
                buttonText: "View Records",
                gradientColors: const [Color(0xFF5A3D1F), Color(0xFF3A2A15)],
                onTap: () => Navigator.pushNamed(context, '/records'),
              ),
            ],
          ),
        ),
        _buildPageIndicator(),
      ],
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Icon(icon, color: Colors.white, size: 30),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  onPressed: onTap,
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      color: gradientColors.first,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(2, (index) {
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  index == _currentPage
                      ? const Color(0xFF5A3D1F)
                      : Colors.grey[300],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Your Ride Statistics",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A3D1F),
          ),
        ),
        const SizedBox(height: 15),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              icon: Icons.directions_car,
              value: _totalAvailableRides.toString(),
              label: "Available Rides",
              color: const Color(0xFF8B5E3B),
            ),
            _buildStatCard(
              icon: Icons.bookmark,
              value: _totalBookings.toString(),
              label: "Your Bookings",
              color: const Color(0xFF5A3D1F),
            ),
            _buildStatCard(
              icon: Icons.attach_money,
              value: "K ${_totalCashToBeSpent.toStringAsFixed(2)}",
              label: "Total Cost",
              color: const Color(0xFF3A2A15),
            ),
            _buildStatCard(
              icon: Icons.people,
              value: _totalUnfullRides.toString(),
              label: "Unfull Rides",
              color: const Color(0xFF5A3D1F),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10), // Slightly reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // Align to start
        crossAxisAlignment:
            CrossAxisAlignment.center, // Center text horizontally
        children: [
          Icon(icon, size: 28, color: color), // Slightly reduced icon size
          const SizedBox(height: 8), // Reduced spacing
          Text(
            value,
            style: TextStyle(
              fontSize: 16, // Slightly reduced font size
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4), // Reduced spacing
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ), // Slightly reduced font size
            textAlign: TextAlign.center,
            maxLines: 2, // Allow label to wrap
            overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookingSection() {
    if (_recentBooking == null) return const SizedBox.shrink();

    final status = _recentBooking!['status']?.toString() ?? 'unknown';
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = const Color(0xFF5A3D1F);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Booking",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A3D1F),
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Booking #${_recentBooking!['id']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A3D1F),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_recentBooking!['pickup_location'] != null)
                _buildBookingDetailRow(
                  icon: Icons.location_on,
                  label: "From",
                  value: _recentBooking!['pickup_location'].toString(),
                ),
              if (_recentBooking!['destination'] != null)
                _buildBookingDetailRow(
                  icon: Icons.flag,
                  label: "To",
                  value: _recentBooking!['destination'].toString(),
                ),
              if (_recentBooking!['total_cost'] != null)
                _buildBookingDetailRow(
                  icon: Icons.attach_money,
                  label: "Cost",
                  value: "K ${_recentBooking!['total_cost'].toString()}",
                ),
              if (_recentBooking!['created_at'] != null)
                _buildBookingDetailRow(
                  icon: Icons.calendar_today,
                  label: "Booked on",
                  value: _formatDate(_recentBooking!['created_at'].toString()),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF5A3D1F)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5A3D1F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat(
        'dd/MM/yyyy HH:mm',
      ).format(date); // Using DateFormat for consistent formatting
    } catch (e) {
      return dateString;
    }
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
}
