// AccountsPage.dart
import 'package:flutter/material.dart';

class AccountsPage extends StatelessWidget {
  final double balance = 20.5; // Example balance

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5A3D1F), // Brown background color
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),

            // Back Button & Title
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "Account",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Balance Display
            Row(
              children: [
                const Text("Balance",
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    children: [
                      const Text("MWK",
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 5),
                      Text(balance.toStringAsFixed(2),
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Fund Account Section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Fund account",
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentOption(
                    "PayChangu",
                    "https://media.licdn.com/dms/image/v2/D4D0BAQF2Ld1BM13bJw/company-logo_200_200/company-logo_200_200/0/1701797651143?e=2147483647&v=beta&t=q73UegsYU7-KzXOg6UOOW3LKpb6La6RPtRDfFO01G4w",
                    onTap: () => _showPaymentDialog(context, "PayChangu"),
                  ),
                  _buildDivider(),
                  _buildPaymentOption(
                    "Mpamba",
                    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQUlIBNIBotAQLDwweIrWX3-MTWKh252P6Wng&s",
                    onTap: () => _showPaymentDialog(context, "Mpamba"),
                  ),
                  _buildDivider(),
                  _buildPaymentOption(
                    "Airtel Money",
                    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRq-C4fZedloKuw_auDwwHJSDj6ynHFro-beQ&s",
                    onTap: () => _showPaymentDialog(context, "Airtel Money"),
                  ),
                  _buildDivider(),
                  _buildPaymentOption(
                    "PayPal",
                    "https://www.top-bank.ch/images/logo_540/paypal.png",
                    onTap: () => _showPaymentDialog(context, "PayPal"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(
                  Icons.cancel, 
                  "Cancel", 
                  Colors.red,
                  onPressed: () => Navigator.pop(context),
                ),
                _buildConfirmButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Deposit confirmed!"))
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, String paymentMethod) {
    final amountController = TextEditingController();
    final contactController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Deposit via $paymentMethod"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: "Amount",
                prefixText: "MWK ",
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: contactController,
              decoration: const InputDecoration(
                labelText: "Phone Number/Email",
              ),
              keyboardType: TextInputType.text,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isEmpty || contactController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill all fields"))
                );
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Processing $paymentMethod payment..."))
              );
            },
            child: const Text("Proceed"),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String title, String imageUrl, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            Image.network(
              imageUrl, 
              width: 30, 
              height: 30,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, color: Colors.grey, size: 30);
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

  Widget _buildActionButton(IconData icon, String label, Color color, {VoidCallback? onPressed}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      icon: Icon(icon, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildConfirmButton({VoidCallback? onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      onPressed: onPressed,
      child: const Text(
        "Confirm Deposit",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}