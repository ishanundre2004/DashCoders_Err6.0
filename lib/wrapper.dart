// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dukaan/consumer/consumer_home_page.dart';
import 'package:dukaan/profile_page.dart';
import 'package:dukaan/vendor/vendor_home_page.dart';
import 'package:dukaan/welcome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}
class _WrapperState extends State<Wrapper> {
  Future<Widget> _handleNavigation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return WelcomePage();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        return const ProfilePage();
      }

      final userData = doc.data();
      final isProfileComplete = userData?['isProfileComplete'] ?? false;
      final userRole = userData?['role'] as String?;

      if (!isProfileComplete) {
        return const ProfilePage();
      }

      if (userRole != null) {
        switch (userRole.toLowerCase()) {
          case 'vendor':
            return const VendorHomePage();
          case 'consumer':
            return const ConsumerHomePage();
          default:
            return const ProfilePage();
        }
      }

      return const ProfilePage();
    } catch (e) {
      // Handle any errors by returning to welcome page
      return WelcomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            return FutureBuilder<Widget>(
              future: _handleNavigation(),
              builder: (context, navigationSnapshot) {
                if (navigationSnapshot.connectionState == 
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                return navigationSnapshot.data ?? WelcomePage();
              },
            );
          } else {
            return WelcomePage();
          }
        },
      ),
    );
  }
}