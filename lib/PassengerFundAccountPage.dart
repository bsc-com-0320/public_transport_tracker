import 'package:flutter/material.dart';
import 'package:public_transport_tracker/payment_webview_page.dart';
import 'package:public_transport_tracker/server/fund_account.model.dart';
import 'package:public_transport_tracker/fund_account.service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SFundAccountPage extends StatefulWidget {
  const SFundAccountPage({Key? key}) : super(key: key);

  @override
  State<SFundAccountPage> createState() => _SFundAccountPageState();
}

class _SFundAccountPageState extends State<SFundAccountPage> {
  int _selectedIndex = 3;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _narrationController = TextEditingController();
  String _fullName = '';
  String _phoneNumber = '';
  bool _isLoading = true;
  String? _errorMessage; // New state variable to hold specific error messages

  final FundAccountService fundService = FundAccountService(
    baseUrl: "https://unimatherapyapplication.com/publictransporttracker",
  );

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // Fetches the user's full name and phone number from Supabase.
  Future<void> _fetchUserProfile() async {
    setState(() {
      _errorMessage = null; // Clear any previous error messages
      _isLoading = true; // Set loading to true when starting to fetch data
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Changed .single() to .maybeSingle() to handle cases where no profile exists.
        // .maybeSingle() returns null if no row is found, preventing the PGRST116 error.
        final response =
            await Supabase.instance.client
                .from('passenger_profiles') // Confirmed table name
                .select('full_name, phone') // Confirmed column names
                .eq('user_id', user.id)
                .maybeSingle(); // <--- IMPORTANT CHANGE: Use maybeSingle()

        if (mounted) {
          setState(() {
            if (response != null) {
              // Profile found, update state with fetched data
              _fullName =
                  (response['full_name']?.toString() ?? 'Name not found');
              _phoneNumber =
                  (response['phone']?.toString() ?? 'Phone not found');
            } else {
              // No profile found for the current user
              _fullName = 'No profile found';
              _phoneNumber = 'N/A';
              _errorMessage =
                  'No user profile found. Please ensure your profile exists.';
            }
            _isLoading =
                false; // Loading is complete whether a profile was found or not
          });
        }
      } else {
        // If no user is logged in, set loading to false and provide default text
        if (mounted) {
          setState(() {
            _fullName = 'Please log in';
            _phoneNumber = 'N/A';
            _isLoading = false;
            _errorMessage = 'No active user session. Please log in.';
          });
        }
      }
    } catch (e) {
      // On error, set loading to false and display error messages
      if (mounted) {
        setState(() {
          _fullName = 'Failed to load name'; // More generic error for the field
          _phoneNumber =
              'Failed to load phone'; // More generic error for the field
          _errorMessage =
              "Error fetching profile: ${e.toString()}"; // Store the specific error
          _isLoading = false; // Loading is complete even on error
        });
      }
      debugPrint("Error fetching profile: $e");
    }
  }

  // Clears the amount and narration text fields.
  void _cancel() {
    _amountController.clear();
    _narrationController.clear();
  }

  // Handles the payment confirmation process.
  Future<void> _confirmDeposit() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Show a loading indicator while processing payment.
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );

        final payment = PaymentsDto(
          fullName: _fullName,
          phoneNumber: _phoneNumber,
          amount: double.parse(_amountController.text),
          narration: _narrationController.text,
          paymentMethod:
              "", // This might need to be dynamically set based on user selection
          currency: "MWK",
        );

        final response = await fundService.processPayment(payment);

        // Dismiss the loading indicator.
        if (mounted) Navigator.pop(context);

        if (response.data?.checkoutUrl != null) {
          final Uri url = Uri.parse(response.data!.checkoutUrl);
          // Navigate to the web view for payment.
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentWebViewPage(paymentUrl: url.toString()),
            ),
          );

          // Handle the result after returning from the payment web view.
          if (result == true && mounted) {
            await _showDialog("Success", "Payment completed successfully");
            _cancel(); // Clear fields on successful payment.
          }
        } else {
          if (mounted) {
            await _showDialog("Success", response.message);
          }
        }
      } catch (e) {
        // Dismiss loading indicator and show error dialog on failure.
        if (mounted) Navigator.pop(context);
        if (mounted) {
          await _showDialog(
            "Error",
            "Failed to process payment: ${e.toString()}",
          );
        }
        debugPrint("Payment processing error: ${e.toString()}");
      }
    }
  }

  // Displays a custom alert dialog.
  Future<void> _showDialog(String title, String message) async {
    return showDialog<void>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF5A3D1F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(message, style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                child: const Text("OK", style: TextStyle(color: Colors.amber)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  // Builds the user information card.
  Widget _buildUserInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF5A3D1F),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_circle, size: 40, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Account",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _fullName, // Displays the fetched full name
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _phoneNumber, // Displays the fetched phone number
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_errorMessage != null) // Display error message if present
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Builds the amount input field with styling and validation.
  Widget _buildAmountField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Color(0xFF5A3D1F)),
        decoration: InputDecoration(
          labelText: "Amount (MWK)",
          labelStyle: const TextStyle(color: Color(0xFF5A3D1F)),
          prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF5A3D1F)),
          prefixText: "MWK ",
          prefixStyle: const TextStyle(color: Color(0xFF5A3D1F)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF5A3D1F)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF5A3D1F)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF5A3D1F), width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter an amount";
          }
          final amount = double.tryParse(value);
          if (amount == null) {
            return "Please enter a valid number";
          }
          if (amount < 500) {
            return "Minimum amount is MWK 500";
          }
          return null;
        },
      ),
    );
  }

  // Builds the narration input field with styling.
  Widget _buildNarrationField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _narrationController,
        style: const TextStyle(color: Color(0xFF5A3D1F)),
        decoration: InputDecoration(
          labelText: "Narration (Optional)",
          labelStyle: const TextStyle(color: Color(0xFF5A3D1F)),
          prefixIcon: const Icon(Icons.note, color: Color(0xFF5A3D1F)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF5A3D1F)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF5A3D1F)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF5A3D1F), width: 2),
          ),
        ),
      ),
    );
  }

  final List<String> _pages = [
    '/home',
    '/order',
    '/records',
    '/passenger-fund-account', // Keeping this consistent with the Canvas version
  ];

  // Handles navigation when a bottom navigation bar item is tapped.
  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    Navigator.pushReplacementNamed(context, _pages[index]);
  }

  // Builds the bottom navigation bar.
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
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF5A3D1F).withOpacity(0.1),
              child: const Icon(Icons.person, color: Color(0xFF5A3D1F)),
            ),
          ),
        ],
      ),
      body:
          // Show a circular progress indicator while loading user profile.
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                // Added RefreshIndicator
                onRefresh:
                    _fetchUserProfile, // Call _fetchUserProfile on swipe down
                child: SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(), // Ensure scrollability for refresh
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Info Card with Icon and potential error message
                        _buildUserInfoCard(),
                        const SizedBox(height: 24),

                        // Amount Section with Icon
                        const Row(
                          children: [
                            Icon(
                              Icons.money,
                              color: Color(0xFF5A3D1F),
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Enter Amount",
                              style: TextStyle(
                                color: Color(0xFF5A3D1F),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildAmountField(),
                        const SizedBox(height: 16),

                        // Narration Section with Icon
                        const Row(
                          children: [
                            Icon(
                              Icons.edit_note,
                              color: Color(0xFF5A3D1F),
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Add Narration (Optional)",
                              style: TextStyle(
                                color: Color(0xFF5A3D1F),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildNarrationField(),
                        const SizedBox(height: 32),

                        // Proceed Button with Icon
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.payment,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "PROCEED TO PAYCHANGU",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: _confirmDeposit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5A3D1F),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}
