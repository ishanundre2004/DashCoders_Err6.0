import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../consumer/vendordetails_page.dart';

class VendorCard extends StatelessWidget {
  final String name;
  final String address;
  final double distance;
  final String businessName;
  final LatLng coordinates;
  final String vendorId;

  const VendorCard({
    super.key,
    required this.name,
    required this.address,
    required this.distance,
    required this.businessName,
    required this.coordinates,
    required this.vendorId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFB9E3EE),
          border: Border.all(
            color: const Color(0xFFF3FEBB),
            width: 1.5,
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
            double padding = 15.0;

            return SizedBox(
              height: cardWidth * 0.47,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VendorDetailsPage(
                        vendorName: businessName,
                        vendorAddress: address,
                        vendorLocation: coordinates,
                        vendorId: vendorId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(0, 255, 255, 255),
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
                      const SizedBox(width: 20),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              businessName,
                              style: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              address,
                              style: const TextStyle(
                                color: Color.fromARGB(179, 0, 0, 0),
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${distance.toStringAsFixed(1)} km away',
                              style: const TextStyle(
                                color: Color.fromARGB(255, 1, 110, 57),
                                fontSize: 14,
                              ),
                            ),
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
