import 'package:flutter/material.dart';
import 'package:public_transport_tracker/AccountsPage.dart';
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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Public Transport Tracker',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/records': (context) => RecordsPage(),
        '/rides': (context) => RidesPage(),
        '/order': (context) => OrderPage(),
        '/map': (context) => MapScreen(),
        '/account': (context) => AccountsPage(), // 👈 Add this line
      },
    );
  }
}
