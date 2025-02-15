import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailsPage extends StatefulWidget {
  final String productName;
  final String vendorName;
  final String vendorAddress;
  final LatLng vendorLocation;
  final String imageUrl;
  final String remainingstock;

  const ProductDetailsPage({
    super.key,
    required this.productName,
    required this.vendorName,
    required this.vendorAddress,
    required this.vendorLocation,
    required this.imageUrl,
    required this.remainingstock,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int quantity = 1;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _incrementQuantity() {
    setState(() {
      quantity++;
    });
  }

  void _decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  Future<void> addToCart() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to add items to cart'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final cartRef =
          _firestore.collection('users').doc(user.uid).collection('cart');

      final existingItem = await cartRef
          .where('productName', isEqualTo: widget.productName)
          .where('vendorName',
              isEqualTo: widget.vendorName) // Ensure vendor name is used
          .get();

      if (existingItem.docs.isNotEmpty) {
        await cartRef.doc(existingItem.docs.first.id).update({
          'quantity': FieldValue.increment(quantity),
        });
      } else {
        await cartRef.add({
          'productName': widget.productName,
          'vendorName': widget.vendorName, // Store vendor name
          'quantity': quantity,
          'price': 60.0, // Replace with actual price
          'imageUrl': widget.imageUrl,
          'vendorAddress': widget.vendorAddress,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to cart successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding to cart: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> createPreBooking({
    required String inventoryId,
    required String productName,
    required String businessName,
    required int quantity,
    required double price,
    required String vendorId,
  }) async {
    try {
      // Get reference to Firestore
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Create a new document in 'prebookings' collection with auto-generated ID
      await firestore.collection('prebookings').add({
        'inventoryId': inventoryId,
        'productName': productName,
        'businessName': businessName,
        'orderedQuantity': quantity,
        'pricePerUnit': price,
        'totalPrice': price * quantity,
        'vendorId': vendorId,
        'status': 'pending', // You can use this to track booking status
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating pre-booking: $e');
      rethrow;
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
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF52B6ED),
                    Color(0xFFB4E0CC),
                    Color(0xFFF3FEBB),
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          widget.imageUrl,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.productName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.remainingstock,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(179, 0, 0, 0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sold by: ${widget.vendorName}",
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xB3000000),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.vendorAddress,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(179, 0, 0, 0),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Quantity Counter
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Quantity:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            onPressed: _decrementQuantity,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.teal,
                            iconSize: 30,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              quantity.toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _incrementQuantity,
                            icon: const Icon(Icons.add_circle_outline),
                            color: Colors.teal,
                            iconSize: 30,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          final Uri googleMapsUrl = Uri(
                            scheme: 'https',
                            host: 'www.google.com',
                            path: 'maps/dir/',
                            queryParameters: {
                              'api': '1',
                              'destination':
                                  '${widget.vendorLocation.latitude},${widget.vendorLocation.longitude}'
                            },
                          );
                          _launchUrl(googleMapsUrl);
                        },
                        child: const Text(
                          "Get Directions",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () async {
                          try {
                            await addToCart();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: Text(
                          "Pre-Book $quantity kg Now",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchUrl(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}
