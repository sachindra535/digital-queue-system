import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/screens/login_page.dart';
import 'package:myapp/screens/home_page.dart';
import 'package:myapp/screens/hotels_page.dart';
import 'package:myapp/screens/colleges_page.dart';
import 'package:myapp/screens/orders_page.dart';
import 'package:myapp/screens/admin_panel.dart'; // ✅ Added admin panel import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Token Queue System',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/hotels': (context) => HotelsPage(),
        '/colleges': (context) => CollegesPage(),
        '/orders': (context) => OrdersPage(),
        '/admin': (context) => const AdminPanel(), // ✅ New route added
      },
    );
  }
}
