import 'package:dukaan/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'dart:convert'; // For base64 decoding
import 'package:flutter/services.dart' show rootBundle; // For default image handling

class VendorDetailsPage extends StatefulWidget {
  final String vendorName;
  final String vendorAddress;
  final google_maps.LatLng vendorLocation;
  final String vendorId;

  const VendorDetailsPage({
    super.key,
    required this.vendorName,
    required this.vendorAddress,
    required this.vendorLocation,
    required this.vendorId,
  });

  @override
  State<VendorDetailsPage> createState() => _VendorDetailsPageState();
}

class _VendorDetailsPageState extends State<VendorDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  String? businessName;
  String? vendorImage; // To store the decoded image
  String? vendorAddress; // To store the vendor's address
  String? vendorPhone; // To store the vendor's phone number
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVendorDetails();
  }

  // Fetch vendor details including image, address, and phone
  Future<void> _fetchVendorDetails() async {
    try {
      final doc =
          await _firestore.collection('users').doc(widget.vendorId).get();
      if (doc.exists) {
        setState(() {
          businessName = doc.data()?['businessName'];
          vendorImage = doc.data()?['img']; // Fetch base64 encoded image
          vendorAddress = doc.data()?['location']['address']; // Fetch address
          vendorPhone = doc.data()?['phone']; // Fetch phone number
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching vendor details: $e');
      setState(() => _isLoading = false);
    }
  }

  // Fetch inventory for the specific business name
  Stream<QuerySnapshot> _getVendorProducts() {
    if (businessName == null) return const Stream.empty();

    return _firestore
        .collection('inventory')
        .where('businessName', isEqualTo: businessName)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Decode base64 image or use a default placeholder
  Widget _buildVendorImage() {
    if (vendorImage != null && vendorImage!.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(vendorImage!),
          width: 500,
          height: 200,
          fit: BoxFit.cover,
        );
      } catch (e) {
        print('Error decoding image: $e');
      }
    }
    // Return a default placeholder image if no image is found
    return Image.asset(
      'assets/store.png', // Add a default image in your assets
      width: 500,
      height: 200,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (businessName == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Business data not found',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

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
                    // Vendor Image
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildVendorImage(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Vendor Name
                    Text(
                      widget.vendorName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Vendor Address
                    if (vendorAddress != null)
                      Text(
                        vendorAddress!,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color.fromARGB(179, 0, 0, 0),
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Vendor Phone
                    if (vendorPhone != null)
                      Text(
                        "Phone: $vendorPhone",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(179, 0, 0, 0),
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Text(
                      "Available Products:",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: _getVendorProducts(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text(
                            "No products available",
                            style:
                                TextStyle(color: Color.fromARGB(179, 0, 0, 0)),
                          );
                        }

                        return Column(
                          children: snapshot.data!.docs.map((doc) {
                            final product = doc.data() as Map<String, dynamic>;
                            final expiryDate =
                                (product['expiryDate'] as Timestamp).toDate();

                            return ProductCard(
                              vendorname: widget.vendorName,
                              prodname: product['name'] ?? 'Unnamed Product',
                              location: widget.vendorAddress,
                              expirydate: _dateFormat.format(expiryDate),
                              remainingstock:
                                  '${product['quantity']?.toString() ?? '0'} kg',
                              imageUrl: product['imageBase64'],
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
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
                        onPressed: () => _openGoogleMapsDirections(),
                        child: const Text(
                          "Get Directions",
                          style: TextStyle(
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

  void _openGoogleMapsDirections() async {
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

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch maps')),
      );
    }
  }
}