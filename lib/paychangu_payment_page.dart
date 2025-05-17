import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PayChanguPaymentPage extends StatefulWidget {
  const PayChanguPaymentPage({super.key});

  @override
  State<PayChanguPaymentPage> createState() => _PayChanguPaymentPageState();
}

class _PayChanguPaymentPageState extends State<PayChanguPaymentPage> {
  void _startPayment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PayChanguWebView(
          checkoutUrl: 'https://test-checkout.paychangu.com', // Replace with real session URL
        ),
      ),
    );

    if (result == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Payment successful!")),
      );
    } else if (result == "cancel") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Payment cancelled.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pay with PayChangu")),
      body: Center(
        child: ElevatedButton(
          onPressed: _startPayment,
          child: const Text("Pay Now"),
        ),
      ),
    );
  }
}

class PayChanguWebView extends StatefulWidget {
  final String checkoutUrl;

  const PayChanguWebView({required this.checkoutUrl, super.key});

  @override
  State<PayChanguWebView> createState() => _PayChanguWebViewState();
}

class _PayChanguWebViewState extends State<PayChanguWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (url.contains("success")) {
              Navigator.pop(context, "success");
            } else if (url.contains("cancel")) {
              Navigator.pop(context, "cancel");
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Payment')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
