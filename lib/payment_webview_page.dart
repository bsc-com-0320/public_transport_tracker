import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String paymentUrl;

  const PaymentWebViewPage({Key? key, required this.paymentUrl})
    : super(key: key);

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                // Update loading state based on webview progress
                setState(() {
                  _isLoading = progress < 100;
                });
              },
              onPageStarted: (String url) {
                debugPrint('Page started loading: $url');
              },
              onPageFinished: (String url) {
                debugPrint('Page finished loading: $url');
              },
              onNavigationRequest: (NavigationRequest request) {
                // Check for payment completion URLs to pop the page and indicate success
                if (request.url.contains('success') ||
                    request.url.contains('completed') ||
                    request.url.contains('status=success')) {
                  Navigator.pop(context, true); // Return success status
                  return NavigationDecision
                      .prevent; // Prevent further navigation in the webview
                }
                return NavigationDecision.navigate; // Allow normal navigation
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Enhanced title for better visibility and style
        title: const Row(
          mainAxisAlignment:
              MainAxisAlignment.center, // Center the title and icon
          mainAxisSize: MainAxisSize.min, // Keep the row size minimal
          children: [
            Icon(Icons.payment, color: Colors.white, size: 28), // Payment icon
            SizedBox(width: 10), // Spacing between icon and text
            Text(
              'Complete Payment',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22, // Increased font size
                letterSpacing: 1.2, // Added letter spacing for style
              ),
            ),
          ],
        ),
        centerTitle: true, // Ensure the title is centered in the AppBar
        backgroundColor: const Color(0xFF5A3D1F), // Consistent background color
        elevation: 8, // Added elevation for a subtle shadow effect
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ), // Back arrow icon
          onPressed:
              () =>
                  Navigator.pop(context, false), // Pop with false on back press
        ),
        // Optional: Add a subtle shadow for a more premium feel
        shadowColor: Colors.black.withOpacity(0.4),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          // Show a circular progress indicator while the webview is loading
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
