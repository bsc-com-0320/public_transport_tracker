import 'package:flutter/material.dart';
import 'package:public_transport_tracker/AccountsPage.dart';
import 'package:public_transport_tracker/AuthChecker.dart';
import 'package:public_transport_tracker/DriverAddRide.dart';
import 'package:public_transport_tracker/DriverFundAccountPage.dart';
import 'package:public_transport_tracker/DriverHomePage.dart';
import 'package:public_transport_tracker/DriverRecords.dart';
import 'package:public_transport_tracker/LoginPage.dart';
import 'package:public_transport_tracker/SignUpPage.dart';
import 'package:public_transport_tracker/forgot_password_page.dart';
import 'package:public_transport_tracker/profile_page.dart';
import 'package:public_transport_tracker/verify_email_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Use prefixes for ambiguous imports
import 'package:public_transport_tracker/homepage.dart' as app_home; // For your general user home page

import 'RecordsPage.dart';
import 'OrderPage.dart';
import 'SFundAccountPage.dart';
import 'map_screen.dart'; // Make sure this file exists

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
      initialRoute: '/auth-check',
      routes: {
        '/login': (context) => SignInPage(),
        '/signup': (context) => SignUpPage(),
        '/verify-email': (context) => VerifyEmailPage(),
        // Use the prefixed names here
        '/home': (context) => app_home.HomePage(), // This is your general user home page
        '/records': (context) => RecordsPage(),
        '/order': (context) => OrderPage(),
        '/map': (context) => MapScreen(),
        '/account': (context) => AccountsPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/profile': (context) => const ProfilePage(),
        '/auth-check': (context) => const AuthChecker(),
        '/driver-home': (context) => DriverHomePage(),
        '/driver-records': (context) => DriverRecordsPage(),
        '/driver-ride': (context) => DriverAddRide(),
        '/driver-fund-account': (context) => DriverFundAccountPage(),
         '/passenger-fund-account': (context) => SFundAccountPage(),
      },
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