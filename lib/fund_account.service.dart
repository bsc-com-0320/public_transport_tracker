// File: lib/server/fund_account.service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:public_transport_tracker/server/fund_account.model.dart'; // Ensure this path is correct

class FundAccountService {
  final String baseUrl;

  FundAccountService({required this.baseUrl});

  // Update your processPayment method in fund_account.service.dart
  Future<PaymentResponse> processPayment(PaymentsDto dto) async {
    final url = Uri.parse('$baseUrl/payments/pay');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dto.toJson()),
      );

      print('processPayment - Status code: ${response.statusCode}');
      print('processPayment - Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final Map<String, dynamic> data = jsonDecode(response.body);
          return PaymentResponse.fromJson(data);
        } catch (e) {
          throw Exception('Failed to parse successful response: $e');
        }
      } else if (response.statusCode >= 500) {
        // Handle server errors specifically
        throw Exception('Server error: ${response.statusCode}');
      } else {
        // Try to parse error message if it's JSON
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'Payment failed');
        } catch (_) {
          throw Exception('Payment failed: ${response.body}');
        }
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<PaymentResponse> getPaymentStatus(String txRef) async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/status/$txRef'),
    );

    print('getPaymentStatus - Status code: ${response.statusCode}');
    print('getPaymentStatus - Response body: ${response.body}');

    if (response.statusCode == 200) {
      return PaymentResponse.fromJson(jsonDecode(response.body));
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(
          'Failed to retrieve payment status: ${error['message'] ?? response.body}',
        );
      } catch (_) {
        throw Exception('Failed to retrieve payment status: ${response.body}');
      }
    }
  }

  Future<PaymentResponse> verifyPayment(String txRef) async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/verify/$txRef'),
    );

    print('verifyPayment - Status code: ${response.statusCode}');
    print('verifyPayment - Response body: ${response.body}');

    if (response.statusCode == 200) {
      return PaymentResponse.fromJson(jsonDecode(response.body));
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(
          'Failed to verify payment: ${error['message'] ?? response.body}',
        );
      } catch (_) {
        throw Exception('Failed to verify payment: ${response.body}');
      }
    }
  }

  Future<PaymentResponse> initiatePayout(InitiatePayoutDto dto) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/cash-out'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dto.toJson()),
    );

    print('initiatePayout - Status code: ${response.statusCode}');
    print('initiatePayout - Response body: ${response.body}');

    if (response.statusCode == 200) {
      return PaymentResponse.fromJson(jsonDecode(response.body));
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(
          'Failed to initiate payout: ${error['message'] ?? response.body}',
        );
      } catch (_) {
        throw Exception('Failed to initiate payout: ${response.body}');
      }
    }
  }
}
