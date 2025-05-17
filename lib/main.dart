import 'package:flutter/material.dart';
import 'package:public_transport_tracker/AccountsPage.dart';
import 'package:public_transport_tracker/LoginPage.dart';
import 'package:public_transport_tracker/SignUpPage.dart';
import 'package:public_transport_tracker/forgot_password_page.dart';
import 'package:public_transport_tracker/verify_email_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'homepage.dart';
import 'RecordsPage.dart';
import 'OrderPage.dart';
import 'RidesPage.dart';
import 'map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://oilotmwaixynjaupkucd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pbG90bXdhaXh5bmphdXBrdWNkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI4MzMyMzcsImV4cCI6MjA1ODQwOTIzN30.iQcQ1FxZz5jollXQgkAflSuIUFoPHgfbc6_L8c66QwM',
    
        
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Public Transport Tracker',
      debugShowCheckedModeBanner: false,
      initialRoute: _supabase.auth.currentUser != null ? '/' : '/login',
      routes: {
        '/login': (context) => SignInPage(),
        '/signup': (context) => SignUpPage(),
        '/verify-email': (context) => VerifyEmailPage(),
        '/': (context) => HomePage(),
        '/records': (context) => RecordsPage(),
        '/rides': (context) => RidesPage(),
        '/order': (context) => OrderPage(),
        '/map': (context) => MapScreen(),
        '/account': (context) => AccountsPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
      },
      // Add error handling for unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('Route ${settings.name} not found'),
            ),
          ),
        );
      },
    );
  }
}