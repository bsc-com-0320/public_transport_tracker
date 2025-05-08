// fund_account_model.dart

class PaymentsDto {
  final String fullName;
  final String phoneNumber;
  final double amount;
  final String narration;

  PaymentsDto({
    required this.fullName,
    required this.phoneNumber,
    required this.amount,
    required this.narration, required String paymentMethod, required String currency,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'narration': narration,
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
  final dynamic data;

  PaymentResponse({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      statusCode: json['statusCode'],
      message: json['message'],
      data: json['data'],
    );
  }
}
