import 'package:flutter/material.dart';
import 'package:public_transport_tracker/server/fund_account.model.dart';
import 'package:public_transport_tracker/server/fund_account.service.dart';

class AccountsPage extends StatefulWidget {
  @override
  _AccountsPageState createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _narrationController = TextEditingController();

  final FundAccountService fundService =
      FundAccountService(baseUrl: "https://dashboard.render.com/d/dpg-d0b8jdp5pdvs73cf9a9g-a");

  void _cancel() {
    _fullNameController.clear();
    _phoneController.clear();
    _amountController.clear();
    _narrationController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Form cleared")),
    );
  }

  Future<void> _confirmDeposit() async {
    if (_formKey.currentState!.validate()) {
      try {
        final payment = PaymentsDto(
          fullName: _fullNameController.text,
          phoneNumber: _phoneController.text,
          amount: double.parse(_amountController.text),
          narration: _narrationController.text,
          paymentMethod: "Mpamba",
          currency: "MWK",
        );

        final response = await fundService.processPayment(payment);
        _showDialog("Success", response.message);
      } catch (e) {
        _showDialog("Error", e.toString());
        print(e.toString());
      }
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF8B5E3B),
        title: Text(title, style: TextStyle(color: Colors.white)),
        content: Text(message, style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            child: Text("OK", style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF5A3D1F),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text("Account",
                      style: TextStyle(color: Colors.white, fontSize: 24)),
                ],
              ),
              SizedBox(height: 20),

              // Payment Options UI
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

                
                  ],
                ),
              ),

              SizedBox(height: 20),
              _buildTextField(_fullNameController, "Full Name"),
              _buildTextField(_phoneController, "Phone Number"),
              _buildTextField(_amountController, "Amount",
                  keyboardType: TextInputType.number),
              _buildTextField(_narrationController, "Narration"),
              SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.cancel, color: Colors.red),
                    label: Text("Cancel", style: TextStyle(color: Colors.red)),
                    onPressed: _cancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton(
                    child: Text("Confirm Deposit",
                        style: TextStyle(color: Colors.white)),
                    onPressed: _confirmDeposit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          filled: true,
          fillColor: Color(0xFF8B5E3B),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? "Please enter $label" : null,
      ),
    );
  }

  Widget _buildPaymentOption(String title, String imageUrl) {
    return Padding(
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
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      height: 2,
      color: Colors.yellow,
    );
  }
}
