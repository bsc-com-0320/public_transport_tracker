// CheckPage.dart
import 'package:flutter/material.dart';

class CheckPage extends StatelessWidget {
  final List<Map<String, dynamic>> checks = [
    {
      'id': '#12345',
      'date': 'May 15, 2023',
      'amount': 15.50,
      'status': 'Completed',
    },
    {
      'id': '#12346',
      'date': 'May 10, 2023',
      'amount': 10.00,
      'status': 'Completed',
    },
    {
      'id': '#12347',
      'date': 'May 5, 2023',
      'amount': 8.75,
      'status': 'Failed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF5A3D1F),
      appBar: AppBar(
        backgroundColor: Color(0xFF8B5E3B),
        title: Text("Payment History", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: checks.length,
        itemBuilder: (context, index) {
          final check = checks[index];
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: Icon(Icons.receipt, color: Color(0xFF8B5E3B), size: 36),
              title: Text("Transaction ${check['id']}"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(check['date']),
                  SizedBox(height: 4),
                  Text("\$${check['amount'].toStringAsFixed(2)}"),
                ],
              ),
              trailing: Chip(
                backgroundColor: check['status'] == 'Completed'
                    ? Colors.green[100]
                    : Colors.red[100],
                label: Text(
                  check['status'],
                  style: TextStyle(
                    color: check['status'] == 'Completed'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}