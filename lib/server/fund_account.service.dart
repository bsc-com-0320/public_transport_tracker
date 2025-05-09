import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:public_transport_tracker/server/fund_account.model.dart';

class FundAccountService {
  final String baseUrl;

  FundAccountService({required this.baseUrl});

  Future<PaymentResponse> processPayment(PaymentsDto dto) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/pay'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dto.toJson()),
    );

    print('processPayment - Status code: ${response.statusCode}');
    print('processPayment - Response body: ${response.body}');

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return PaymentResponse.fromJson(data);
    } else {
      throw Exception('Failed to process payment: ${response.body}');
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
        throw Exception('Failed to retrieve payment status: ${error['message'] ?? response.body}');
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
        throw Exception('Failed to verify payment: ${error['message'] ?? response.body}');
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
        throw Exception('Failed to initiate payout: ${error['message'] ?? response.body}');
      } catch (_) {
        throw Exception('Failed to initiate payout: ${response.body}');
      }
    }
  }
}
