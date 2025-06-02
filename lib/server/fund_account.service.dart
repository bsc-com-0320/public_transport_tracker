/// This file defines the `FundAccountService` class, which is responsible
/// for handling all interactions with the backend API related to payments
/// and payouts. It acts as a service layer, abstracting away the HTTP
/// requests and JSON serialization/deserialization.
///
/// It uses the `http` package for making network requests and relies on
/// the DTOs and response models defined in `fund_account.model.dart`
/// for data structuring.

import 'dart:convert'; // Provides JSON encoding and decoding functionalities.
import 'package:http/http.dart' as http; // HTTP client for making network requests.
import 'package:public_transport_tracker/server/fund_account.model.dart'; // Imports the data models (DTOs and response structures).

/// A service class dedicated to handling financial transactions,
/// including processing payments, checking payment status, verifying payments,
/// and initiating payouts.
///
/// It communicates with a backend API using HTTP requests.
class FundAccountService {
  /// The base URL for the payment API endpoints. This allows the service
  /// to be configured for different environments (e.g., development, production).
  final String baseUrl;

  /// Constructs a [FundAccountService] instance with a specified base URL.
  FundAccountService({required this.baseUrl});

  /// Sends a request to the backend to process a new payment.
  ///
  /// Takes a [PaymentsDto] object containing all the payment details.
  /// It serializes the DTO to JSON and sends it as a POST request.
  ///
  /// Throws an [Exception] if the payment processing fails (non-200/201 status code).
  Future<PaymentResponse> processPayment(PaymentsDto dto) async {
    // Make an HTTP POST request to the '/payments/pay' endpoint.
    final response = await http.post(
      Uri.parse('$baseUrl/payments/pay'),
      // Set the Content-Type header to indicate JSON data.
      headers: {'Content-Type': 'application/json'},
      // Encode the PaymentsDto object to a JSON string for the request body.
      body: jsonEncode(dto.toJson()),
    );

    // Print status code and response body for debugging purposes.
    print('processPayment - Status code: ${response.statusCode}');
    print('processPayment - Response body: ${response.body}');

    // Decode the JSON response body into a Map.
    final Map<String, dynamic> data = jsonDecode(response.body);

    // Check if the request was successful (status code 200 or 201).
    if (response.statusCode == 200 || response.statusCode == 201) {
      // If successful, parse the response data into a PaymentResponse object.
      return PaymentResponse.fromJson(data);
    } else {
      // If not successful, throw an exception with the error message from the response body.
      throw Exception('Failed to process payment: ${response.body}');
    }
  }

  /// Retrieves the current status of a payment using its transaction reference.
  ///
  /// Takes a [txRef] (transaction reference) as input.
  /// It sends a GET request to the '/payments/status/{txRef}' endpoint.
  ///
  /// Throws an [Exception] if retrieving the status fails.
  Future<PaymentResponse> getPaymentStatus(String txRef) async {
    // Make an HTTP GET request to the '/payments/status/{txRef}' endpoint.
    final response = await http.get(
      Uri.parse('$baseUrl/payments/status/$txRef'),
    );

    // Print status code and response body for debugging purposes.
    print('getPaymentStatus - Status code: ${response.statusCode}');
    print('getPaymentStatus - Response body: ${response.body}');

    // Check if the request was successful (status code 200).
    if (response.statusCode == 200) {
      // If successful, parse the response data into a PaymentResponse object.
      return PaymentResponse.fromJson(jsonDecode(response.body));
    } else {
      // If not successful, attempt to parse the error message from the response.
      try {
        final error = jsonDecode(response.body);
        throw Exception('Failed to retrieve payment status: ${error['message'] ?? response.body}');
      } catch (_) {
        // Fallback error message if the response body is not a valid JSON.
        throw Exception('Failed to retrieve payment status: ${response.body}');
      }
    }
  }

  /// Verifies a payment using its transaction reference. This is typically
  /// done after a payment callback or redirect to confirm the final status
  /// of a transaction with the payment gateway.
  ///
  /// Takes a [txRef] (transaction reference) as input.
  /// It sends a GET request to the '/payments/verify/{txRef}' endpoint.
  ///
  /// Throws an [Exception] if the verification fails.
  Future<PaymentResponse> verifyPayment(String txRef) async {
    // Make an HTTP GET request to the '/payments/verify/{txRef}' endpoint.
    final response = await http.get(
      Uri.parse('$baseUrl/payments/verify/$txRef'),
    );

    // Print status code and response body for debugging purposes.
    print('verifyPayment - Status code: ${response.statusCode}');
    print('verifyPayment - Response body: ${response.body}');

    // Check if the request was successful (status code 200).
    if (response.statusCode == 200) {
      // If successful, parse the response data into a PaymentResponse object.
      return PaymentResponse.fromJson(jsonDecode(response.body));
    } else {
      // If not successful, attempt to parse the error message from the response.
      try {
        final error = jsonDecode(response.body);
        throw Exception('Failed to verify payment: ${error['message'] ?? response.body}');
      } catch (_) {
        // Fallback error message if the response body is not a valid JSON.
        throw Exception('Failed to verify payment: ${response.body}');
      }
    }
  }

  /// Initiates a payout (cash-out) request to disburse funds.
  ///
  /// Takes an [InitiatePayoutDto] object containing the recipient's details
  /// and the amount to be paid out.
  /// It serializes the DTO to JSON and sends it as a POST request.
  ///
  /// Throws an [Exception] if the payout initiation fails.
  Future<PaymentResponse> initiatePayout(InitiatePayoutDto dto) async {
    // Make an HTTP POST request to the '/payments/cash-out' endpoint.
    final response = await http.post(
      Uri.parse('$baseUrl/payments/cash-out'),
      // Set the Content-Type header to indicate JSON data.
      headers: {'Content-Type': 'application/json'},
      // Encode the InitiatePayoutDto object to a JSON string for the request body.
      body: jsonEncode(dto.toJson()),
    );

    // Print status code and response body for debugging purposes.
    print('initiatePayout - Status code: ${response.statusCode}');
    print('initiatePayout - Response body: ${response.body}');

    // Check if the request was successful (status code 200).
    if (response.statusCode == 200) {
      // If successful, parse the response data into a PaymentResponse object.
      return PaymentResponse.fromJson(jsonDecode(response.body));
    } else {
      // If not successful, attempt to parse the error message from the response.
      try {
        final error = jsonDecode(response.body);
        throw Exception('Failed to initiate payout: ${error['message'] ?? response.body}');
      } catch (_) {
        // Fallback error message if the response body is not a valid JSON.
        throw Exception('Failed to initiate payout: ${response.body}');
      }
    }
  }
}
