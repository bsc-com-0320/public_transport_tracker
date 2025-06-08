import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:public_transport_tracker/server/fund_account.model.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String paymentUrl;

  const PaymentWebViewPage({Key? key, required this.paymentUrl})
    : super(key: key);

  @override
  State<PaymentWebViewPage> createState() => _EnhancedPaymentWebViewPageState();
}

class _EnhancedPaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                setState(() {
                  _isLoading = progress < 100;
                });
              },
              onPageStarted: (String url) {
                debugPrint('Page started loading: $url');
              },
              onPageFinished: (String url) {
                debugPrint('Page finished loading: $url');
                _handlePaymentCompletion(url);
              },
              onNavigationRequest: (NavigationRequest request) {
                return _handleNavigation(request);
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  NavigationDecision _handleNavigation(NavigationRequest request) {
    debugPrint('Navigation to: ${request.url}');

    // Handle WhatsApp URL scheme error
    if (request.url.startsWith('whatsapp://')) {
      _showWhatsAppError();
      return NavigationDecision.prevent;
    }

    // Handle payment completion
    if (request.url.contains('success') ||
        request.url.contains('completed') ||
        request.url.contains('status=success')) {
      if (!_paymentCompleted) {
        _paymentCompleted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPaymentSuccessDialog();
        });
      }
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  void _handlePaymentCompletion(String url) {
    if (url.contains('success') ||
        url.contains('completed') ||
        url.contains('status=success')) {
      if (!_paymentCompleted) {
        _paymentCompleted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPaymentSuccessDialog();
        });
      }
    }
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF5A3D1F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Text(
                  'Payment Successful!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your payment has been processed successfully',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Paid To:', 'Public Transport Tracker'),
                _buildDetailRow('Amount:', 'MWK 500.00'),
                _buildDetailRow('Date & Time:', _getFormattedDateTime()),
                const SizedBox(height: 8),
                const LinearProgressIndicator(
                  value: 1.0,
                  backgroundColor: Colors.grey,
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Redirecting...',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, true); // Return to previous screen
                },
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  String _getFormattedDateTime() {
    final now = DateTime.now();
    return '${now.day}th ${_getMonthName(now.month)} ${now.year} at ${_formatTime(now)}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showWhatsAppError() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF4E342E), // Deep brown
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Proceed To EasyRide',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              ' Thank You!',
              style: TextStyle(
                color: Color(0xFFD7CCC8), // Light brown-grey
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF6D4C41), // Medium brown
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payment, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text(
              'Complete Payment',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF5A3D1F),
        elevation: 8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A3D1F)),
              ),
            ),
        ],
      ),
    );
  }
}

// Updated Payment Service with better error handling
class EnhancedFundAccountService {
  final String baseUrl;
  final SupabaseClient supabase;

  EnhancedFundAccountService({required this.baseUrl, required this.supabase});

  Future<PaymentResponse> processPayment(PaymentsDto dto) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/pay'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dto.toJson()),
      );

      debugPrint('Payment Response: ${response.statusCode} - ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PaymentResponse.fromJson(data);
      } else {
        throw PaymentException(
          code: response.statusCode,
          message: data['message'] ?? 'Payment processing failed',
          details: data,
        );
      }
    } catch (e) {
      debugPrint('Payment Error: $e');
      throw PaymentException(
        code: 500,
        message: 'Network error occurred',
        details: {'error': e.toString()},
      );
    }
  }
}

class PaymentException implements Exception {
  final int code;
  final String message;
  final dynamic details;

  PaymentException({required this.code, required this.message, this.details});

  @override
  String toString() => 'PaymentException($code): $message';
}
