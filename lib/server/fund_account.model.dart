/// A data transfer object (DTO) used to encapsulate the necessary information
/// for initiating a payment request. This class is typically used when
/// sending payment details from the client-side application to a backend
/// service or payment gateway.
class PaymentsDto {
  final String fullName;
  final String phoneNumber;
  final double amount;
  final String narration;
  final String paymentMethod;
  final String currency;

  /// Constructs a [PaymentsDto] instance with all the required payment details.
  PaymentsDto({
    required this.fullName,
    required this.phoneNumber,
    required this.amount,
    required this.narration,
    required this.paymentMethod,
    required this.currency,
  });

  /// Converts the [PaymentsDto] instance into a JSON-compatible [Map].
  /// This is essential for sending the payment data over HTTP, typically
  /// in the body of a POST request.
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

/// A data transfer object (DTO) for initiating a payout request.
/// This class specifically holds the information needed to disburse funds
/// to a recipient, typically identified by their phone number and the amount.
class InitiatePayoutDto {
  final String phoneNumber;
  final double amount;

  /// Constructs an [InitiatePayoutDto] instance with the recipient's phone number
  /// and the amount to be paid out.
  InitiatePayoutDto({
    required this.phoneNumber,
    required this.amount,
  });

  /// Converts the [InitiatePayoutDto] instance into a JSON-compatible [Map].
  /// This method is used when serializing payout request data for API calls.
  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'amount': amount,
    };
  }
}

/// Represents the top-level response structure received from a payment API
/// after initiating a payment. It includes the status code, a message,
/// and optional payment session data if the transaction was successful.
class PaymentResponse {
  final int statusCode;
  final String message;
  final PaymentSessionData? data; // Nullable, as 'data' might not always be present

  /// Constructs a [PaymentResponse] instance.
  PaymentResponse({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  /// Factory constructor to create a [PaymentResponse] instance from a JSON [Map].
  /// This is used for deserializing the API response into a Dart object.
  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      statusCode: json['statusCode'],
      message: json['message'],
      // Conditionally parse 'data' if it exists in the JSON, otherwise set to null.
      data: json['data'] != null ? PaymentSessionData.fromJson(json['data']) : null,
    );
  }
}

/// Encapsulates the session-specific data returned by a payment gateway
/// when a payment is successfully initiated. This often includes a checkout URL
/// and detailed transaction information.
class PaymentSessionData {
  final String event;
  final String checkoutUrl;
  final PaymentTransactionDetails details; // Renamed from 'data' to 'details' for clarity as it holds transaction details

  /// Constructs a [PaymentSessionData] instance.
  PaymentSessionData({
    required this.event,
    required this.checkoutUrl,
    required this.details,
  });

  /// Factory constructor to create a [PaymentSessionData] instance from a JSON [Map].
  /// It parses the event, checkout URL, and nested transaction details.
  factory PaymentSessionData.fromJson(Map<String, dynamic> json) {
    return PaymentSessionData(
      event: json['event'],
      checkoutUrl: json['checkout_url'],
      // The nested 'data' key in the JSON contains the transaction details.
      details: PaymentTransactionDetails.fromJson(json['data']),
    );
  }
}

/// Represents the detailed information about a payment transaction.
/// This class holds granular data such as the transaction reference,
/// currency, amount, payment mode, and status.
class PaymentTransactionDetails {
  final String txRef; // Transaction reference
  final String currency;
  final double amount;
  final String mode; // e.g., "live", "test"
  final String status; // e.g., "pending", "successful", "failed"

  /// Constructs a [PaymentTransactionDetails] instance.
  PaymentTransactionDetails({
    required this.txRef,
    required this.currency,
    required this.amount,
    required this.mode,
    required this.status,
  });

  /// Factory constructor to create a [PaymentTransactionDetails] instance from a JSON [Map].
  /// It handles the conversion of the 'amount' from a generic number type to a double.
  factory PaymentTransactionDetails.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionDetails(
      txRef: json['tx_ref'],
      currency: json['currency'],
      amount: (json['amount'] as num).toDouble(), // Ensure amount is a double
      mode: json['mode'],
      status: json['status'],
    );
  }
}