// AccountsPage.dart
import 'package:flutter/material.dart';

class AccountsPage extends StatelessWidget {
  final double balance = 20.5; // Example balance

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF5A3D1F), // Brown background color
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30),

            // Back Button & Title
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  "Account",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Balance Display
            Row(
              children: [
                Text("Balance",
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                SizedBox(width: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    children: [
                      Text("\MWK",
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                      SizedBox(width: 5),
                      Text("20.5",
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Fund Account Section
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Fund account",
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
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
            SizedBox(height: 20),

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
                      SnackBar(content: Text("Deposit confirmed!"))
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Deposit via $paymentMethod"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: "Amount",
                prefixText: "\$",
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: "Phone Number/Email",
              ),
              keyboardType: TextInputType.text,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Processing $paymentMethod payment..."))
              );
            },
            child: Text("Proceed"),
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
            Image.network(imageUrl, width: 30, height: 30,
                errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.broken_image, color: Colors.grey, size: 30);
            }),
            SizedBox(width: 10),
            Text(title,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      height: 2,
      color: Colors.yellow,
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, {VoidCallback? onPressed}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      icon: Icon(icon, color: color),
      label: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      onPressed: onPressed,
    );
  }

  Widget _buildConfirmButton({VoidCallback? onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      onPressed: onPressed,
      child: Text("Confirm Deposit",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}