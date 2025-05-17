import 'package:flutter/material.dart';
import 'package:public_transport_tracker/RecordsPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<String> _pages = ['/', '/order', '/records', '/rides'];
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  bool _showAlert = true;

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    Navigator.pushNamed(context, _pages[index]);
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
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
          title: Text(
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
              child: Text("Cancel", style: TextStyle(color: Color(0xFF5A3D1F))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5A3D1F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout();
              },
              child: Text("Logout", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
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

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 5,
                margin: EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              _buildMenuOption(
                icon: Icons.person,
                title: "Profile",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              Divider(height: 20, color: Colors.grey[200]),
              _buildMenuOption(
                icon: Icons.logout,
                title: "Logout",
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog();
                },
                isLogout: true,
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Color(0xFF5A3D1F)),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : Color(0xFF5A3D1F),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
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
          "Transport",
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
            child: // After (wrapped in GestureDetector)
                GestureDetector(
              onTap: _showProfileMenu, // Added this
              child: Padding(
                padding: EdgeInsets.only(right: 10),
                child: CircleAvatar(
                  backgroundColor: Color(0xFF5A3D1F).withOpacity(0.1),
                  child: Icon(Icons.person, color: Color(0xFF5A3D1F)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fast Alert Banner
              if (_showAlert) _buildAlertBanner(),

              SizedBox(height: 20),

              // User Summary
              _buildUserSummary(),
              SizedBox(height: 25),

              // Action Cards
              _buildDashboardCards(),
              SizedBox(height: 25),

              // Quick Stats
              _buildQuickStats(),
              SizedBox(height: 25),

              // Recent Activity
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color(0xFF8B5E3B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.flash_on, color: Color(0xFF5A3D1F)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Express rides available! (Will add some Instant notification here)",
              style: TextStyle(
                color: Color(0xFF5A3D1F),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _showAlert = false),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome back!",
          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.directions_car,
                value: "3",
                label: "Active Rides",
                color: Color(0xFF8B5E3B),
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.history,
                value: "12",
                label: "Past Trips",
                color: Color(0xFF5A3D1F),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCards() {
    return Column(
      children: [
        SizedBox(
          height: 200, // Reduced from 220 to prevent overflow
          child: PageView(
            controller: _pageController,
            padEnds: false,
            children: [
              _buildDashboardCard(
                iconUrl:
                    'https://cdn-icons-png.flaticon.com/512/3663/3663360.png',
                title: "Instant Ride",
                subtitle: "Book now with 1 tap",
                buttonText: "Book Now",
                gradientColors: [Color(0xFF8B5E3B), Color(0xFF5A3D1F)],
                onTap: () => Navigator.pushNamed(context, '/order'),
              ),
              _buildDashboardCard(
                iconUrl:
                    'https://cdn-icons-png.flaticon.com/512/3132/3132693.png',
                title: "Your Journeys",
                subtitle: "Past trips & receipts",
                buttonText: "View History",
                gradientColors: [Color(0xFF5A3D1F), Color(0xFF3A2A15)],
                onTap: () => Navigator.pushNamed(context, '/records'),
              ),
              _buildDashboardCard(
                iconUrl:
                    'https://cdn-icons-png.flaticon.com/512/1570/1570887.png',
                title: "Driver Portal",
                subtitle: "Manage vehicles",
                buttonText: "Dashboard",
                gradientColors: [Color(0xFF3A2A15), Color(0xFF1A120B)],
                onTap: () => Navigator.pushNamed(context, '/driver-records'),
              ),
            ],
          ),
        ),
        _buildPageIndicator(),
      ],
    );
  }

  Widget _buildDashboardCard({
    required String iconUrl,
    required String title,
    required String subtitle,
    required String buttonText,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
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
            padding: EdgeInsets.all(15), // Reduced padding from 20
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // Better space distribution
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50, // Reduced from 60
                  height: 50, // Reduced from 60
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Image.network(
                      iconUrl,
                      width: 30, // Reduced from 40
                      height: 30, // Reduced from 40
                      errorBuilder:
                          (_, __, ___) => Icon(
                            Icons.directions_car,
                            color: Colors.white,
                            size: 24, // Reduced from 30
                          ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18, // Reduced from 20
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4), // Reduced from 5
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13, // Reduced from 14
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10), // Reduced from 15
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Reduced from 10
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16, // Reduced from 20
                      vertical: 8, // Reduced from 10
                    ),
                  ),
                  onPressed: onTap,
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      color: gradientColors.first,
                      fontWeight: FontWeight.bold,
                      fontSize: 14, // Added font size for consistency
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

  //
  Widget _buildPageIndicator() {
    return Padding(
      padding: EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return Container(
            width: 8,
            height: 8,
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  index == _currentPage ? Color(0xFF5A3D1F) : Colors.grey[300],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Monthly Stats",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A3D1F),
          ),
        ),
        SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.attach_money,
                value: "K 4,250",
                label: "Total Spent",
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: _buildStatItem(
                icon: Icons.directions_walk,
                value: "87 km",
                label: "Distance",
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: _buildStatItem(
                icon: Icons.access_time,
                value: "12.5 hrs",
                label: "Ride Time",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Color(0xFF8B5E3B), size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5A3D1F),
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent Activity",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A3D1F),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                "See all",
                style: TextStyle(color: Color(0xFF8B5E3B)),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        ...List.generate(3, (index) => _buildActivityItem(index)),
      ],
    );
  }

  Widget _buildActivityItem(int index) {
    final activities = [
      {
        "icon": Icons.local_taxi,
        "title": "Taxi Ride Completed",
        "subtitle": "City Center to Airport",
        "time": "2 hours ago",
        "color": Color(0xFF8B5E3B),
      },
      {
        "icon": Icons.directions_bus,
        "title": "Bus Ride Scheduled",
        "subtitle": "Main Station to University",
        "time": "Yesterday",
        "color": Color(0xFF5A3D1F),
      },
      {
        "icon": Icons.payment,
        "title": "Payment Received",
        "subtitle": "K 1,200 for ride #4582",
        "time": "2 days ago",
        "color": Color(0xFF3A2A15),
      },
    ];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: activities[index]["color"] as Color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              activities[index]["icon"] as IconData,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activities[index]["title"] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A3D1F),
                  ),
                ),
                Text(
                  activities[index]["subtitle"] as String,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            activities[index]["time"] as String,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
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
          icon: Icon(Icons.add_circle_outline),
          activeIcon: Icon(Icons.add_circle),
          label: "Add Ride",
        ),
      ],
    );
  }
}
