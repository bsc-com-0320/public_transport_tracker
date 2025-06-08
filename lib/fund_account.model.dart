// File: lib/server/fund_account.model.dart
import 'dart:convert';

class PaymentsDto {
  final String fullName;
  final String phoneNumber;
  final double amount;
  final String narration;
  final String paymentMethod;
  final String currency;

  PaymentsDto({
    required this.fullName,
    required this.phoneNumber,
    required this.amount,
    required this.narration,
    required this.paymentMethod,
    required this.currency,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'narration': narration,
      'paymentMethod': paymentMethod,
      'currency': currency,
    };
  }
}

class InitiatePayoutDto {
  final String phoneNumber;
  final double amount;

  InitiatePayoutDto({
    required this.phoneNumber,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'amount': amount,
    };
  }
}

class PaymentResponse {
  final int statusCode;
  final String message;
  final PaymentSessionData? data;

  PaymentResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      statusCode: json['statusCode'],
      message: json['message'],
      data: json['data'] != null ? PaymentSessionData.fromJson(json['data']) : null,
    );
  }
}

class PaymentSessionData {
  final String event;
  final String checkoutUrl;
  final PaymentTransactionDetails details;

  PaymentSessionData({
    required this.event,
    required this.checkoutUrl,
    required this.details,
  });

  factory PaymentSessionData.fromJson(Map<String, dynamic> json) {
    return PaymentSessionData(
      event: json['event'],
      checkoutUrl: json['checkout_url'],
      details: PaymentTransactionDetails.fromJson(json['data']),
    );
  }
}

class PaymentTransactionDetails {
  final String txRef;
  final String currency;
  final double amount;
  final String mode;
  final String status;

  PaymentTransactionDetails({
    required this.txRef,
    required this.currency,
    required this.amount,
    required this.mode,
    required this.status,
  });

  factory PaymentTransactionDetails.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionDetails(
      txRef: json['tx_ref'],
      currency: json['currency'],
      amount: (json['amount'] as num).toDouble(),
      mode: json['mode'],
      status: json['status'],
    );
  }
}