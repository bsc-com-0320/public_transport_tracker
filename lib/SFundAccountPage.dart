// File: lib/s_fund_account_page.dart (Your main page)
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Import for launching URLs
import 'package:public_transport_tracker/server/fund_account.model.dart'; // Ensure this path is correct
import 'package:public_transport_tracker/server/fund_account.service.dart'; // Ensure this path is correct
import 'package:http/http.dart' as http; // Import http with an alias

class SFundAccountPage extends StatefulWidget {
  const SFundAccountPage({Key? key}) : super(key: key);

  @override
  State<SFundAccountPage> createState() => _SFundAccountPageState(); // Renamed state class for clarity
}

class _SFundAccountPageState extends State<SFundAccountPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _narrationController =
      TextEditingController(); // Added for narration
  String? _selectedPaymentMethod = 'PayChangu'; // Default to PayChangu

  final FundAccountService _fundAccountService = FundAccountService(
    baseUrl: "https://unimatherapyapplication.com/publictransporttracker",
  );

  // User details
  String _userName = 'Guest';
  String _userPhone = 'N/A';

  // Navigation
  int _selectedIndex = 3; // Corresponds to 'Fund Account' in the BottomNavBar

  final List<String> _pages = [
    '/home',
    '/order',
    '/records',
    '/s-fund-account',
  ];

  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _narrationController.text = 'Fund Account'; // Set a default narration
    _loadUserProfile(); // Load user profile on initialization
  }

  Future<void> _loadUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _userName = 'Not Logged In';
        _userPhone = 'N/A';
      });
      return;
    }

    try {
      // First try to get from driver_profiles
      final driverResponse =
          await supabase
              .from('driver_profiles')
              .select('business_name, phone')
              .eq('user_id', user.id)
              .maybeSingle();

      if (driverResponse != null && driverResponse.isNotEmpty) {
        setState(() {
          _userName = (driverResponse['business_name'] ?? 'Driver').toString();
          _userPhone = (driverResponse['phone']?.toString() ?? 'Unknown Phone');
        });
      } else {
        // If not found in driver_profiles, try passenger_profiles
        final passengerResponse =
            await supabase
                .from('passenger_profiles')
                .select('full_name, phone')
                .eq('user_id', user.id)
                .maybeSingle();

        if (passengerResponse != null && passengerResponse.isNotEmpty) {
          setState(() {
            _userName =
                (passengerResponse['full_name'] ?? 'Passenger').toString();
            _userPhone =
                (passengerResponse['phone']?.toString() ?? 'Unknown Phone');
          });
        } else {
          setState(() {
            _userName = 'User Profile Not Found';
            _userPhone = 'N/A';
          });
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        _userName = 'Error Loading Profile';
        _userPhone = 'N/A';
      });
      _showSnackBar('Failed to load user profile details.', Colors.red);
    }
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
            style: TextStyle(color: Colors.grey),
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
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Logout failed: ${e.toString()}', Colors.red);
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

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    Navigator.pushReplacementNamed(context, _pages[index]);
  }

  Future<void> _fundAccount() async {
    final amount = double.tryParse(_amountController.text);
    final narration = _narrationController.text.trim();

    // Validate amount
    if (amount == null || amount <= 0) {
      _showSnackBar('Please enter a valid amount to fund.', Colors.red);
      return;
    }

    // Validate narration
    if (narration.isEmpty) {
      _showSnackBar('Please enter a narration for the payment.', Colors.red);
      return;
    }

    // Check user authentication
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showSnackBar(
        'User not logged in. Please log in to fund your account.',
        Colors.red,
      );
      return;
    }

    String fullName = 'Guest User';
    String phoneNumber = '265XXXXXXXXX';

    try {
      // Debug print
      print('Fetching user profile for user ID: ${user.id}');

      // First try to get from driver_profiles
      final driverResponse =
          await supabase
              .from('driver_profiles')
              .select('business_name, phone')
              .eq('user_id', user.id)
              .maybeSingle();

      if (driverResponse != null && driverResponse.isNotEmpty) {
        print('Found driver profile: $driverResponse');
        fullName = (driverResponse['business_name'] ?? 'Driver').toString();
        phoneNumber = (driverResponse['phone']?.toString() ?? 'Unknown Phone');
      } else {
        // If not found in driver_profiles, try passenger_profiles
        final passengerResponse =
            await supabase
                .from('passenger_profiles')
                .select('full_name, phone')
                .eq('user_id', user.id)
                .maybeSingle();

        if (passengerResponse != null && passengerResponse.isNotEmpty) {
          print('Found passenger profile: $passengerResponse');
          fullName = (passengerResponse['full_name'] ?? 'Passenger').toString();
          phoneNumber =
              (passengerResponse['phone']?.toString() ?? 'Unknown Phone');
        }
      }

      print('Using payment details - Name: $fullName, Phone: $phoneNumber');
    } catch (e) {
      print('Error fetching user profile: $e');
      _showSnackBar(
        'Could not retrieve user details for payment. Using default values.',
        Colors.orange,
      );
    }

    try {
      // Prepare payment data
      final payment = PaymentsDto(
        fullName: fullName,
        phoneNumber: phoneNumber,
        amount: amount,
        narration: narration,
        paymentMethod: _selectedPaymentMethod!,
        currency: "MWK",
      );

      // Debug print
      print('Sending payment request: ${payment.toJson()}');

      _showSnackBar('Initiating PayChangu payment...', Colors.blueAccent);

      // Process payment
      final paymentResponse = await _fundAccountService.processPayment(payment);

      // Debug print
      print(
        'Payment response: ${paymentResponse.statusCode} - ${paymentResponse.message}',
      );

      if (paymentResponse.statusCode == 200 ||
          paymentResponse.statusCode == 201) {
        if (paymentResponse.data != null &&
            paymentResponse.data!.checkoutUrl.isNotEmpty) {
          // Debug print
          print('Checkout URL: ${paymentResponse.data!.checkoutUrl}');

          await _launchURL(paymentResponse.data!.checkoutUrl);
          _showSnackBar('Redirecting to PayChangu for payment.', Colors.green);

          // Clear fields after successful initiation
          _amountController.clear();
          _narrationController.clear();
        } else {
          _showSnackBar(
            'Payment initiated but no checkout URL received. Please contact support.',
            Colors.orange,
          );
        }
      } else {
        _showSnackBar('Payment failed: ${paymentResponse.message}', Colors.red);
      }
    } on http.ClientException catch (e) {
      // Network-related errors
      print('Network error: $e');
      _showSnackBar(
        'Network error: Please check your internet connection and try again.',
        Colors.red,
      );
    } on FormatException catch (e) {
      // JSON parsing errors
      print('Format error: $e');
      _showSnackBar(
        'Server returned invalid data. Please try again later.',
        Colors.red,
      );
    } on Exception catch (e) {
      // All other errors
      print('Payment error: $e');

      String errorMessage = 'Payment failed';
      if (e.toString().contains('500')) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.toString().contains('timed out')) {
        errorMessage = 'Request timed out. Please check your connection.';
      }

      _showSnackBar(errorMessage, Colors.red);
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(
            seconds: 3,
          ), // Increased duration for better visibility
        ),
      );
    }
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF5A3D1F).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Color(0xFF5A3D1F), size: 28),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A3D1F),
                ),
              ),
              Text(
                _userPhone,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Use a deeper, richer gradient for more impact
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5A3D1F), // Darker brown
            Color(0xFF8B5E3B), // Lighter brown
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20), // More rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3), // Stronger shadow
            blurRadius: 15, // Larger blur
            offset: const Offset(0, 8), // More pronounced offset
          ),
        ],
      ),
      child: Stack(
        // Use Stack to add overlay elements if desired
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.account_balance_wallet,
              size: 100,
              color: Colors.white.withOpacity(0.1), // Subtle watermark icon
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Current Balance",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9), // Slightly brighter
                  fontSize: 18, // Slightly larger
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12), // Increased spacing
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    "MWK", // Currency code
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24, // Consistent with currency
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "0.00", // This should ideally come from a state or backend call
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42, // Significantly larger for balance
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2, // A bit of letter spacing
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15), // Increased spacing
              Text(
                "Last updated: ${DateFormat("hh:mm a, dd MMM").format(DateTime.now())}", // More detailed date/time
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13, // Slightly larger
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInputField() {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Amount to Fund (MWK)',
        hintText: 'e.g., 55000.00',
        labelStyle: const TextStyle(color: Color(0xFF5A3D1F)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5A3D1F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B5E3B), width: 2),
        ),
        prefixIcon: const Icon(Icons.money, color: Color(0xFF8B5E3B)),
        filled: true,
        fillColor: Colors.white,
      ),
      style: const TextStyle(color: Color(0xFF5A3D1F)),
    );
  }

  Widget _buildNarrationInputField() {
    return TextField(
      controller: _narrationController,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: 'Narration (e.g., "Top-up for rides")',
        hintText: 'e.g., Top-up for daily commute',
        labelStyle: const TextStyle(color: Color(0xFF5A3D1F)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5A3D1F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B5E3B), width: 2),
        ),
        prefixIcon: const Icon(Icons.notes, color: Color(0xFF8B5E3B)),
        filled: true,
        fillColor: Colors.white,
      ),
      style: const TextStyle(color: Color(0xFF5A3D1F)),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return _buildPaymentMethodOption(
      title: 'PayChangu',
      value: 'PayChangu',
      icon:
          Icons
              .payments, // You can replace this with an actual image if you have one
    );
  }

  Widget _buildPaymentMethodOption({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation:
          _selectedPaymentMethod == value
              ? 6
              : 2, // Increased elevation for selected
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // More rounded corners
        side: BorderSide(
          color:
              _selectedPaymentMethod == value
                  ? const Color(0xFF8B5E3B)
                  : Colors.grey[300]!,
          width:
              _selectedPaymentMethod == value
                  ? 2.5
                  : 1, // Thicker border for selected
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          setState(() {
            _selectedPaymentMethod = value;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(18.0), // Slightly more padding
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    _selectedPaymentMethod == value
                        ? const Color(0xFF5A3D1F)
                        : Colors.grey[600],
                size: 32, // Slightly larger icon
              ),
              const SizedBox(width: 20), // Increased spacing
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18, // Slightly larger text
                    fontWeight: FontWeight.w600, // Bolder text
                    color:
                        _selectedPaymentMethod == value
                            ? const Color(0xFF5A3D1F)
                            : Colors.grey[700],
                  ),
                ),
              ),
              Radio<String>(
                value: value,
                groupValue: _selectedPaymentMethod,
                onChanged: (String? val) {
                  setState(() {
                    _selectedPaymentMethod = val;
                  });
                },
                activeColor: const Color(0xFF5A3D1F),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFundAccountButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5A3D1F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // More rounded corners
          ),
          padding: const EdgeInsets.symmetric(vertical: 18), // Taller button
          elevation: 5, // Added elevation
        ),
        onPressed: _fundAccount,
        icon: const Icon(
          Icons.account_balance_wallet,
          color: Colors.white,
          size: 28,
        ), // Larger icon
        label: const Text(
          'Fund Account',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20, // Larger font size
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8, // Subtle letter spacing
          ),
        ),
      ),
    );
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

  @override
  void dispose() {
    _amountController.dispose();
    _narrationController.dispose();
    super.dispose();
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
          "Fund Account",
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(), // Display logged-in user's name and phone
              const SizedBox(height: 20),
              _buildBalanceCard(),
              const SizedBox(height: 25),
              const Text(
                "Add Funds",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A3D1F),
                ),
              ),
              const SizedBox(height: 15),
              _buildAmountInputField(),
              const SizedBox(height: 15), // Added spacing
              _buildNarrationInputField(), // Added narration input field
              const SizedBox(height: 20),
              const Text(
                "Select Payment Method",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A3D1F),
                ),
              ),
              const SizedBox(height: 10),
              _buildPaymentMethodSelection(),
              const SizedBox(height: 30),
              _buildFundAccountButton(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}
