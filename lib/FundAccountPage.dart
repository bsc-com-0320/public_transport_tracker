import 'package:flutter/material.dart';

class FundAccountPage extends StatefulWidget {
  const FundAccountPage({Key? key}) : super(key: key);

  @override
  State<FundAccountPage> createState() => _FundAccountPageState();
}

class _FundAccountPageState extends State<FundAccountPage> {
  final TextEditingController _amountController = TextEditingController();
  String? _selectedPaymentMethod;

  // --- Navigation related state and methods ---
  int _selectedIndex = 3; // Set initial index to 3 for 'Fund Account' tab
  // Make sure these routes correspond to your actual defined routes in main.dart
  final List<String> _pages = [
    '/driver-home', // Index 0: Home
    '/driver-ride', // Index 1: Add Ride
    '/driver-records', // Index 2: Records
    '/fund-account' // Index 3: Fund Account (this page)
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      // If the same tab is tapped, do nothing or scroll to top if applicable
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
    // Navigate to the corresponding page using named routes.
    // pushReplacementNamed is good for bottom navigation to avoid deep stacks.
    Navigator.pushReplacementNamed(context, _pages[index]);
  }
  // --- End Navigation related ---

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // Placeholder for when funding functionality is added back
  void _onFundAccountPressed() {
    final amount = double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      _showSnackBar('Please enter a valid amount to fund.', Colors.red);
      return;
    }
    if (_selectedPaymentMethod == null) {
      _showSnackBar('Please select a payment method.', Colors.red);
      return;
    }

    // --- No actual payment processing here ---
    // This is where your PayChangu integration logic would go in the future.
    // For now, we'll just show a success-like message.
    _showSnackBar(
      'Attempting to fund K${amount.toStringAsFixed(2)} via $_selectedPaymentMethod. (Functionality removed)',
      Colors.blueAccent,
    );
    // You might clear the text field here as well:
    // _amountController.clear();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Consistent with the theme
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Fund Account",
          style: TextStyle(
            color: Color(0xFF5A3D1F), // Your theme color
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 25),
              Text(
                "Add Funds",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A3D1F),
                ),
              ),
              const SizedBox(height: 15),
              _buildAmountInputField(),
              const SizedBox(height: 20),
              Text(
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
      bottomNavigationBar: _buildBottomNavBar(), // Added bottom navigation bar
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5E3B), Color(0xFF5A3D1F)], // Theme gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black26.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Current Balance",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "K 5,500.00", // Static for UI purposes
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Last updated: 10:30 AM", // Static for UI purposes
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
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
        hintText: 'e.g., 5000.00',
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

  Widget _buildPaymentMethodSelection() {
    return Column(
      children: [
        _buildPaymentMethodOption(
          title: 'Mobile Money (Airtel Money, TNM Mpamba)',
          value: 'Mobile Money',
          icon: Icons.phone_android,
        ),
        const SizedBox(height: 10),
        _buildPaymentMethodOption(
          title: 'Credit/Debit Card',
          value: 'Card',
          icon: Icons.credit_card,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: _selectedPaymentMethod == value ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _selectedPaymentMethod == value ? const Color(0xFF8B5E3B) : Colors.grey[300]!,
          width: _selectedPaymentMethod == value ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedPaymentMethod = value;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: _selectedPaymentMethod == value ? const Color(0xFF5A3D1F) : Colors.grey[600],
                size: 30,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _selectedPaymentMethod == value ? const Color(0xFF5A3D1F) : Colors.grey[700],
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
          backgroundColor: const Color(0xFF5A3D1F), // Your theme color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onPressed: _onFundAccountPressed, // Now calls the local placeholder
        icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
        label: const Text(
          'Fund Account',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- New Bottom Navigation Bar Widget ---
  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF5A3D1F),
      unselectedItemColor: Colors.grey[600],
      currentIndex: _selectedIndex, // Use the state variable for current index
      onTap: _onItemTapped, // Call the navigation method
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
}