import 'package:camera/camera.dart';
import 'package:dukaan/auth/login_page.dart';
import 'package:dukaan/consumer/cart_page.dart';
import 'package:dukaan/consumer/checkout_page.dart';
import 'package:dukaan/vendor/addproduct_page.dart';
import 'package:dukaan/welcome_page.dart';
import 'package:dukaan/wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // final cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dukaan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 111, 2, 2)),
        useMaterial3: true,
      ),
      home: const Wrapper(),
      routes: {
        '/login': (context) => LoginPage(),
        '/addProduct': (context) => AddProductPage(),
        '/cart': (context) => CartPage(),
        '/checkout': (context) => CheckoutPage()
      },
    );
  }
}
