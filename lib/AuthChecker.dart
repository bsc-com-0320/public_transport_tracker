import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthChecker extends StatefulWidget {
  const AuthChecker({Key? key}) : super(key: key);

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        _redirectUser();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectUser();
    });
  }

  Future<void> _redirectUser() async {
    // A small delay to ensure the UI is ready before navigation
    await Future.delayed(Duration(milliseconds: 100));

    final user = _supabase.auth.currentUser;

    if (user == null) {
      // User is not logged in, go to login page
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    if (user.emailConfirmedAt == null) {
      // User is logged in but email not confirmed, go to verify email page
      if (mounted) Navigator.pushReplacementNamed(context, '/verify-email');
      return;
    }

    // Determine user role and redirect accordingly
    final role = user.userMetadata?['user_type'] ?? 'passenger';
    if (mounted) {
      if (role == 'driver') {
        Navigator.pushReplacementNamed(context, '/driver-home'); // Navigate to driver's home
      } else {
        Navigator.pushReplacementNamed(context, '/home'); // Navigate to passenger's home (HomePage)
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A3D1F)),
        ),
      ),
    );
  }
}