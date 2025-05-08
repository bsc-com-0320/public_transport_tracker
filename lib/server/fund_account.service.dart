// fund_account_service.dart
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

    if (response.statusCode == 200) {
      return PaymentResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to process payment: ${response.body}');
    }
  }

  Future<PaymentResponse> getPaymentStatus(String txRef) async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/status/$txRef'),
    );

    if (response.statusCode == 200) {
      return PaymentResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to retrieve payment status: ${response.body}');
    }
  }

  Future<PaymentResponse> verifyPayment(String txRef) async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/verify/$txRef'),
    );

    if (response.statusCode == 200) {
      return PaymentResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to verify payment: ${response.body}');
    }
  }

  Future<PaymentResponse> initiatePayout(InitiatePayoutDto dto) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/cash-out'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dto.toJson()),
    );

    if (response.statusCode == 200) {
      return PaymentResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to initiate payout: ${response.body}');
    }
  }
}
