import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:public_transport_tracker/AccountPage.dart';
import 'package:public_transport_tracker/AccountsPage.dart';
import 'package:public_transport_tracker/CheckPage.dart';
import 'package:public_transport_tracker/EditProfilePage.dart';
import 'package:public_transport_tracker/GPSPage.dart';
import 'package:public_transport_tracker/OrderPage.dart';
import 'package:public_transport_tracker/RidesPage.dart';
import 'package:public_transport_tracker/map_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Homepage.dart';
import 'LoginPage.dart';
import 'SignUpPage.dart';
import 'BookPage.dart';
import 'GoogleMap.dart';
import 'OrderPage.dart';


const supabaseUrl = 'https://oilotmwaixynjaupkucd.supabase.co';
const supabaseKey =
 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pbG90bXdhaXh5bmphdXBrdWNkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI4MzMyMzcsImV4cCI6MjA1ODQwOTIzN30.iQcQ1FxZz5jollXQgkAflSuIUFoPHgfbc6_L8c66QwM';


void main()  async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl,anonKey:supabaseKey );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Public_transport_tracker',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        
      ),
      initialRoute: '/login', 
      routes: {
        '/': (context) => HomePage(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
       '/book': (context) => BookPage(),
       ///'/rides': (context) => RidesPage(),
       '/order': (context) => OrderPage(),
       '/accounts': (context) => AccountsPage(),
        '/account': (context) => AccountPage(),
        '/check': (context) => CheckPage(),
         '/editprofile': (context) => EditProfilePage(),
         '/gps': (context) => GPSPage(),
         '/map': (context) => MapScreen(),



      
    
        
      },
    );
  }
  //
  
}


