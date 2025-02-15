import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dukaan/consumer/featured_page.dart';
import 'package:dukaan/consumer/objectdetector_page.dart';
import 'package:dukaan/consumer/order_page.dart';
import 'package:dukaan/consumer/search_page.dart';
import 'package:dukaan/osm_map.dart';
import 'package:dukaan/profile_page.dart';
import 'package:dukaan/vendor/addproduct_page.dart';
import 'package:dukaan/widgets/vegetable_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../widgets/vendor_card.dart';

class ConsumerHomePage extends StatefulWidget {
  const ConsumerHomePage({super.key});

  @override
  _ConsumerHomePageState createState() => _ConsumerHomePageState();
}

class _ConsumerHomePageState extends State<ConsumerHomePage> {
  String username = "";
  String address = "Fetching location...";
  int _selectedIndex = 0;
  bool _isDropdownOpen = false;
  bool _isLoading = true;
  Position? _currentPosition;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _currentIndex = 0;
  final List<Widget> _pages = [
    Center(child: Text('', style: TextStyle(fontSize: 24))),
    Center(child: Text('', style: TextStyle(fontSize: 24))),
    Center(child: Text('', style: TextStyle(fontSize: 24))),
    Center(child: Text('', style: TextStyle(fontSize: 24))),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _fetchUsername();
    _fetchLocation();
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('Location permissions are permanently denied');
      return;
    }
  }

  Future<void> _fetchUsername() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot =
            await _firestore.collection('users').doc(user.uid).get();
        if (snapshot.exists) {
          setState(() {
            username = snapshot.data()?['name'] ?? "Unnamed User";
          });
        }
      }
    } catch (e) {
      print('Error fetching username: $e');
      _showSnackBar('Error fetching user information');
    }
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentPosition = position;
      });

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        setState(() {
          address = "${placemarks[0].name}, ${placemarks[0].locality}, "
              "${placemarks[0].administrativeArea}";
        });
      }
    } catch (e) {
      print('Error fetching location: $e');
      _showSnackBar('Error fetching location');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371e3; // Earth radius in meters
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c / 1000; // Return distance in kilometers
  }

  Stream<List<QueryDocumentSnapshot>> _getNearbyVendors() {
    return _firestore
        .collection('users')
        .where('role', whereIn: ['Vendor', 'vendor'])
        .snapshots()
        .map((snapshot) {
          print('Number of vendors found: ${snapshot.docs.length}');

          return snapshot.docs.where((doc) {
            if (_currentPosition == null) {
              print('Current position is null');
              return false;
            }

            final vendorData = doc.data() as Map<String, dynamic>;
            print('Vendor data: $vendorData');

            final coords = vendorData['location']['coordinates']?.split(',');
            if (coords?.length != 2) {
              print('Invalid coordinates for vendor: ${vendorData['name']}');
              return false;
            }

            final vendorLat = double.tryParse(coords![0]);
            final vendorLng = double.tryParse(coords[1]);
            if (vendorLat == null || vendorLng == null) {
              print(
                  'Could not parse coordinates for vendor: ${vendorData['name']}');
              return false;
            }

            final distance = _calculateDistance(_currentPosition!.latitude,
                _currentPosition!.longitude, vendorLat, vendorLng);

            print('Distance to ${vendorData['name']}: $distance km');
            return distance <= 20; // Filter vendors within 20 km
          }).toList();
        });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
      _showSnackBar('Error logging out');
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
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  address,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                              ],
                            ),
                          ),
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
                        Container(
                          width: double.infinity,
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
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _logout,
                                child: const Text(
                                  'Logout',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        "Hello, $username",
                        style: const TextStyle(
                          fontSize: 30,
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSearchBar(),
                      const SizedBox(height: 20),
                      const Text(
                        "Recommended",
                        style: TextStyle(
                          fontSize: 20,
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: VegetableList(),
                      ),
                      Row(
                        children: [
                          const Text(
                            "Featured",
                            style: TextStyle(
                              fontSize: 20,
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const FeaturedPage(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 15),
                              child: const Text(
                                "See All",
                                style: TextStyle(
                                  color: Color.fromARGB(255, 58, 57, 57),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      StreamBuilder<List<QueryDocumentSnapshot>>(
                        stream: _getNearbyVendors(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text(
                              "Error: ${snapshot.error}",
                              style: const TextStyle(color: Colors.red),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text(
                              "No nearby vendors found",
                              style: TextStyle(color: Colors.white70),
                            );
                          }

                          return Column(
                            children: snapshot.data!.map((vendorDoc) {
                              final vendorData =
                                  vendorDoc.data() as Map<String, dynamic>;
                              final coords = vendorData['location']
                                      ['coordinates']
                                  .split(',');
                              final distance = _calculateDistance(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                  double.parse(coords[0]),
                                  double.parse(coords[1]));

                              return VendorCard(
                                vendorId: vendorDoc.id,
                                name: vendorData['name'] ?? '',
                                address:
                                    vendorData['location']['address'] ?? '',
                                distance: distance,
                                businessName: vendorData['businessName'] ?? '',
                                coordinates: LatLng(double.parse(coords[0]),
                                    double.parse(coords[1])),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OSMMapScreen(),
                            ),
                          );
                        },
                        child: Text("Open Map"),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                            20), // Adjust the radius as needed
                        child: SizedBox(
                          height: 300, // Adjust height as needed
                          width: double.infinity, // Take full width of screen
                          child: OSMMapScreen(),
                        ),
                      ),
                      SizedBox(
                        height: 90,
                      ),
                    ],
                  ),
                ),
              ),
            _pages[_currentIndex],
            Align(
              alignment: Alignment.bottomCenter,
              child: _navBar(),
            ),
          ],
        ),
      ),
      // floatingActionButton: Padding(
      //   padding: const EdgeInsets.only(bottom: 80.0),
      //   child: FloatingActionButton(
      //     onPressed: () {
      //       Navigator.pushNamed(context, '/cart');
      //     },
      //     backgroundColor: const Color(0xFF52B6ED),
      //     elevation: 8,
      //     shape: RoundedRectangleBorder(
      //       borderRadius: BorderRadius.circular(30),
      //     ),
      //     child: Stack(
      //       children: [
      //         const Icon(
      //           Icons.shopping_cart,
      //           color: Colors.white,
      //           size: 28,
      //         ),
      //         // Optional: Add a badge for cart items count
      //         Positioned(
      //           right: 0,
      //           top: 0,
      //           child: Container(
      //             padding: const EdgeInsets.all(2),
      //             decoration: BoxDecoration(
      //               color: Colors.red,
      //               borderRadius: BorderRadius.circular(10),
      //             ),
      //             constraints: const BoxConstraints(
      //               minWidth: 16,
      //               minHeight: 16,
      //             ),
      //             child: const Text(
      //               '0', // Replace with actual cart items count
      //               style: TextStyle(
      //                 color: Colors.white,
      //                 fontSize: 10,
      //               ),
      //               textAlign: TextAlign.center,
      //             ),
      //           ),
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
      floatingActionButton: _floatingCartButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildSearchBar() {
    return Material(
      elevation: 15,
      borderRadius: BorderRadius.circular(30.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFB9E3EE),
          borderRadius: BorderRadius.circular(30.0),
          border: Border.all(
            color: const Color(0xFFF3FEBB).withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle:
                      const TextStyle(color: Color.fromARGB(179, 0, 0, 0)),
                  border: InputBorder.none,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 15.0),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.mic, color: Color.fromARGB(255, 0, 0, 0)),
              onPressed: () {
                print('Mic clicked');
              },
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner,
                  color: Color.fromARGB(255, 0, 0, 0)),
              onPressed: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     // builder: (context) => const ObjectdetectorPage(),
                //   ),
                // );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _navBar() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(
        right: 24,
        left: 24,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        color: Colors.black, // Background color as per your image
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 75, 75, 75),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navBarItem(Icons.home, 0),
          _navBarItem(Icons.search, 1),
          _floatingAddButton(), // Floating Add Button
          _navBarItem(Icons.history, 3), // Orders
          _navBarItem(Icons.person, 4), // Profile
        ],
      ),
    );
  }

  Widget _navBarItem(IconData icon, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Icon(
        icon,
        color: _currentIndex == index ? Colors.blue : Colors.white,
        size: 28,
      ),
    );
  }

  Widget _floatingAddButton() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color.fromARGB(255, 0, 0, 0),
      ),
      child: IconButton(
        icon: const Icon(Icons.add,
            color: Color.fromARGB(255, 0, 0, 0), size: 32),
        onPressed: () {
          setState(() {
            _currentIndex = 2;
          });
        },
      ),
    );
  }

  Widget _floatingCartButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50.0),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/cart');
        },
        backgroundColor: const Color(0xFF52B6ED),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(80),
        ),
        child: Stack(
          children: [
            const Icon(
              Icons.shopping_cart,
              color: Colors.white,
              size: 30,
            ),
            // Optional: Add a badge for cart items count
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: const Text(
                  '0', // Replace with actual cart items count
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
