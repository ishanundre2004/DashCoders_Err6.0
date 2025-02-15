

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dukaan/vendor/inventory_page.dart';
import 'package:dukaan/widgets/inventory_card.dart';
import 'package:dukaan/widgets/stats_card.dart';
import 'package:dukaan/widgets/vegetable_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VendorHomePage extends StatefulWidget {
  const VendorHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ConsumerHomePageState createState() => _ConsumerHomePageState();
}

class _ConsumerHomePageState extends State<VendorHomePage> {
  int _selectedIndex = 0;
  bool _isDropdownOpen = false;
  String businessName = "";
  String username = "";
  String locationAddress = "";

  @override
  void initState() {
    super.initState();
    _fetchVendorData();
  }

  Future<void> _fetchVendorData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (snapshot.exists) {
          setState(() {
            username = snapshot.data()?['name'] ?? "Unnamed User";
            businessName =
                snapshot.data()?['businessName'] ?? "Unnamed Business";
            locationAddress =
                snapshot.data()?['Location address'] ?? "Unknown Location";
          });
        }
      }
    } catch (e) {
      print('Error fetching vendor data: $e');
    }
  }

  Stream<QuerySnapshot> _getVendorProducts() {
    if (businessName.isEmpty) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('inventory')
        .where('businessName', isEqualTo: businessName)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> _getExpiringSoonProducts() {
    if (businessName.isEmpty) return const Stream.empty();

    final now = DateTime.now();
    final threeDaysLater = now.add(const Duration(days: 3));

    return FirebaseFirestore.instance
        .collection('inventory')
        .where('businessName', isEqualTo: businessName)
        .where('expiryDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('expiryDate',
            isLessThanOrEqualTo: Timestamp.fromDate(threeDaysLater))
        .orderBy('expiryDate', descending: false)
        .snapshots();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 1:
        Navigator.pushNamed(context, '/leaderboard');
        break;
      case 2:
        Navigator.pushNamed(context, '/adddonation');
        break;
    }
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color(0xFF52B6ED),
                    Color(0xFFB4E0CC),
                    Color(0xFFF3FEBB),
                  ],
                  transform: GradientRotation(3.14 / 4),
                ),
              ),
            ),
            // Container(
            //   color: Colors.black.withOpacity(0.5),
            // ),
            SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.only(left: 25.0, right: 25.0, top: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$businessName",
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Color.fromARGB(255, 0, 0, 0)),
                            ),
                          ],
                        ),
                        // Hamburger button to show dropdown
                        IconButton(
                          icon: Icon(Icons.menu,
                              color: const Color.fromARGB(255, 0, 0, 0)),
                          onPressed: () {
                            setState(() {
                              _isDropdownOpen = !_isDropdownOpen;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_isDropdownOpen)
                      Positioned(
                        top: 80,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              TextButton(
                                onPressed: _navigateToProfile,
                                child: const Text(
                                  'Profile',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 0, 0, 0),
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _logout,
                                child: const Text(
                                  'Logout',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 0, 0, 0),
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        "Hello, $username",
                        style: TextStyle(
                          fontSize: 30,
                          color: const Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    StatsCard(
                      title: 'Total Income',
                      value: '₹1500',
                      description: 'Total income this month',
                      valueColor: Colors.green,
                    ),
                    StatsCard(
                      title: 'Bookings Today',
                      value: '30',
                      description: 'Number of bookings today',
                      valueColor: Colors.blue,
                    ),
                    StatsCard(
                      title: 'Pending Bookings',
                      value: '5',
                      description: 'Pending bookings to be confirmed',
                      valueColor: Colors.orange,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Expiring Soon",
                            style: TextStyle(
                              fontSize: 20,
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          StreamBuilder<QuerySnapshot>(
                            stream: _getExpiringSoonProducts(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}',
                                    style: const TextStyle(color: Colors.red));
                              }
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Text(
                                  "No products expiring soon",
                                  style: TextStyle(color: Colors.white70),
                                );
                              }

                              return SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.30,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: snapshot.data!.docs.map((doc) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      return VegetableCard(
                                        name: data['name'] ?? 'Unnamed Product',
                                        price:
                                            data['price']?.toStringAsFixed(2) ??
                                                '0.00',
                                        quantity: '${data['quantity'] ?? 0} kg',
                                        vendor: businessName,
                                        imageUrl: data['imageBase64'],
                                        isBase64: true,
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          "My Inventory",
                          style: TextStyle(
                            fontSize: 20,
                            color: const Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(), // This pushes the button to the right
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () {
                              // Navigate to the Featured screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      InventoryPage(), // Replace with your actual screen widget
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 15),
                              child: const Text(
                                "See All",
                                style: TextStyle(
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Dynamic Inventory Cards
                    StreamBuilder<QuerySnapshot>(
                      stream: _getVendorProducts(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text(
                            "No products found in inventory",
                            style:
                                TextStyle(color: Color.fromARGB(179, 0, 0, 0)),
                          );
                        }

                        return Column(
                          children: snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final expiryDate =
                                (data['expiryDate'] as Timestamp).toDate();

                            return InventoryCard(
                              vendorname: businessName,
                              prodname: data['name'] ?? 'Unnamed Product',
                              location: locationAddress,
                              expirydate:
                                  DateFormat('dd/MM/yyyy').format(expiryDate),
                              imageUrl: data[
                                  'imageBase64'], // Pass base64 string directly
                              remainingstock:
                                  '${data['quantity']?.toString() ?? '0'} kg',
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/addProduct'),
        elevation: 15,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Color.fromARGB(255, 0, 0, 0)),
      ),
    );
  }
}
