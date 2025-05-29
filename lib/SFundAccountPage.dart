// File: lib/s_fund_account_page.dart (Your main page)
import 'package:flutter/material.dart';
// Corrected import: Assuming FundAccountService expects PaymentsDto from the 'server' model.
// If your FundAccountService expects the DTO from the non-server model, change this back.
import 'package:public_transport_tracker/server/fund_account.model.dart';
import 'package:public_transport_tracker/fund_account.service.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Keep if Supabase is still used for navigation logic, otherwise remove.

class SFundAccountPage extends StatefulWidget {
  const SFundAccountPage({Key? key}) : super(key: key);

  @override
  State<SFundAccountPage> createState() => _SFundAccountPageState();
}

class _SFundAccountPageState extends State<SFundAccountPage> {
  int _selectedIndex = 3;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _narrationController = TextEditingController();

  final FundAccountService fundService = FundAccountService(
    baseUrl: "https://unimatherapyapplication.com/publictransporttracker",
  );

  void _cancel() {
    _fullNameController.clear();
    _phoneController.clear();
    _amountController.clear();
    _narrationController.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Form cleared")));
  }

  Future<void> _confirmDeposit() async {
    if (_formKey.currentState!.validate()) {
      try {
        final payment = PaymentsDto(
          fullName: _fullNameController.text,
          phoneNumber: _phoneController.text,
          amount: double.parse(_amountController.text),
          narration: _narrationController.text,
          paymentMethod: "", // This might need to be selected by the user
          currency: "MWK",
        );

        // The type error should be resolved now that PaymentsDto is imported consistently.
        final response = await fundService.processPayment(payment);
        _showDialog("Success", response.message);
        _cancel(); // Clear form on successful deposit
      } catch (e) {
        _showDialog("Error", "Failed to process payment: ${e.toString()}");
        debugPrint("Payment processing error: ${e.toString()}");
      }
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF8B5E3B),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: Text(message, style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                child: const Text("OK", style: TextStyle(color: Colors.white)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator, // Added validator parameter
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.brown),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.green),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator:
            validator ??
            (value) =>
                value == null || value.isEmpty ? "Please enter $label" : null,
      ),
    );
  }

  Widget _buildPaymentOption(String title, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Image.network(
            imageUrl,
            width: 30,
            height: 30,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 30,
              );
            },
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      height: 2,
      color: Colors.yellow,
    );
  }

  final List<String> _pages = [
    '/home',
    '/order',
    '/records',
    '/s-fund-account',
  ];

  // Supabase client instance. Ensure Supabase is initialized in your main.dart or a parent widget.
  // Example: await Supabase.initialize(url: 'YOUR_SUPABASE_URL', anonKey: 'YOUR_SUPABASE_ANON_KEY');
  final SupabaseClient supabase = Supabase.instance.client;

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    // This will navigate to the specified route.
    // Ensure these routes are defined in your MaterialApp's routes.
    Navigator.pushReplacementNamed(context, _pages[index]);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Theme background color
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
              // Notification action (currently empty)
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                // Profile menu action (currently empty)
              },
              child: CircleAvatar(
                backgroundColor: const Color(0xFF5A3D1F).withOpacity(0.1),
                child: const Icon(Icons.person, color: Color(0xFF5A3D1F)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Deposit Details",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A3D1F),
                ),
              ),
              const SizedBox(height: 15),
              _buildTextField(_fullNameController, "Full Name"),
              _buildTextField(
                _phoneController,
                "Phone Number",
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                _amountController,
                "Amount (MWK)",
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter an amount";
                  }
                  if (double.tryParse(value) == null) {
                    return "Please enter a valid number";
                  }
                  if (double.parse(value) <= 0) {
                    return "Amount must be greater than zero";
                  }
                  return null;
                },
              ),
              _buildTextField(
                _narrationController,
                "Narration (Optional)",
                validator: (value) => null,
              ), // Narration is optional
              const SizedBox(height: 20),
              const Text(
                "Payment Options",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A3D1F),
                ),
              ),
              const SizedBox(height: 15),
              _buildPaymentOption(
                "Airtel Money",
                "https://placehold.co/30x30/000000/FFFFFF?text=AM",
              ), // Placeholder
              _buildDivider(),
              _buildPaymentOption(
                "Mpamba",
                "https://placehold.co/30x30/000000/FFFFFF?text=MP",
              ), // Placeholder
              _buildDivider(),
              _buildPaymentOption(
                "National Bank",
                "https://placehold.co/30x30/000000/FFFFFF?text=NB",
              ), // Placeholder
              _buildDivider(),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirmDeposit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A3D1F),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Confirm Deposit",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5A3D1F),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: Color(0xFF5A3D1F)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Clear Form",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}
