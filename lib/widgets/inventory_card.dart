import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../consumer/productdetails_page.dart';

class InventoryCard extends StatelessWidget {
  final String prodname;
  final String location;
  final String expirydate;
  final String imageUrl; // This now holds the base64 string
  final String vendorname;
  final String remainingstock;

  const InventoryCard({
    super.key,
    required this.vendorname,
    required this.prodname,
    required this.location,
    required this.expirydate,
    required this.imageUrl,
    required this.remainingstock,
  });

  @override
  Widget build(BuildContext context) {
    // Decode base64 string to image bytes
    Uint8List imageBytes = base64Decode(imageUrl);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFB9E3EE),
          border: Border.all(
            color: const Color(0xFFF3FEBB),
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double cardWidth = constraints.maxWidth;
            double imageSize = cardWidth * 0.3;
            double padding = 15.0;

            return SizedBox(
              height: cardWidth * 0.47,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsPage(
                        vendorName: vendorname,
                        productName: prodname,
                        vendorAddress: location,
                        vendorLocation: LatLng(19.0760, 72.8777),
                        imageUrl: imageUrl,
                        remainingstock: remainingstock,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  shadowColor: const Color(0xFF0E0E29),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.memory(
                          imageBytes,
                          width: imageSize,
                          height: imageSize,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prodname,
                              style: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              location,
                              style: const TextStyle(
                                color: Color.fromARGB(179, 0, 0, 0),
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              expirydate,
                              style: const TextStyle(
                                color: Color.fromARGB(179, 0, 0, 0),
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              remainingstock,
                              style: const TextStyle(
                                color: Color.fromARGB(179, 0, 0, 0),
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
