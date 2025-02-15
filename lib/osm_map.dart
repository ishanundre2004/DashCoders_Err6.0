import 'package:dukaan/consumer/vendordetails_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;

class OSMMapScreen extends StatefulWidget {
  @override
  _OSMMapScreenState createState() => _OSMMapScreenState();
}

class _OSMMapScreenState extends State<OSMMapScreen> {
  VendorLocation? selectedMarker;
  LatLng? currentLocation;
  final LatLng defaultLocation = LatLng(19.0760, 72.8777); // Mumbai, India
  List<VendorLocation> vendorLocations = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchVendorLocations();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _fetchVendorLocations() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Vendor')
          .get();

      List<VendorLocation> locations = [];
      for (var doc in querySnapshot.docs) {
        var coordinates = doc['location']['coordinates'];
        var businessName = doc['businessName'] as String? ?? 'Unnamed Store';
        var phone = doc['phone'] as String ?? "No contact details";
        var vendorId = doc.id;

        if (coordinates != null && coordinates is String) {
          List<String> latLng = coordinates.split(', ');
          if (latLng.length == 2) {
            double? lat = double.tryParse(latLng[0].trim());
            double? lng = double.tryParse(latLng[1].trim());
            if (lat != null && lng != null) {
              locations.add(VendorLocation(
                location: LatLng(lat, lng),
                businessName: businessName,
                phone: phone,
                vendorId: vendorId,
              ));
            }
          }
        }
      }

      setState(() {
        vendorLocations = locations;
      });
    } catch (e) {
      print("Error fetching vendor locations: $e");
    }
  }

  void _openInGoogleMaps(LatLng location) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      print('Could not launch $url');
    }
  }

  void _openWhatsAppChat(String phone) async {
    // Remove any non-numeric characters from phone number
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    // WhatsApp URL scheme
    final whatsappUrl = Uri.parse('https://wa.me/$cleanPhone');

    if (!await canLaunchUrl(whatsappUrl)) {
      await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
      );
    } else {
      print('Could not launch WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: currentLocation ?? defaultLocation,
              initialZoom: 12,
              onTap: (_, __) {
                setState(() {
                  selectedMarker = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.ishanundre2004.dukaan',
              ),
              MarkerLayer(
                markers: [
                  // Current Location Marker
                  if (currentLocation != null)
                    Marker(
                      point: currentLocation!,
                      width: 40,
                      height: 40,
                      child:
                          Icon(Icons.my_location, color: Colors.blue, size: 40),
                    ),
                  // Vendor Markers
                  ...vendorLocations.map((vendorLocation) => Marker(
                        point: vendorLocation.location,
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedMarker = vendorLocation;
                            });
                          },
                          child: Icon(Icons.location_pin,
                              color: Colors.red, size: 40),
                        ),
                      )),
                ],
              ),
            ],
          ),

          // Show store details when marker is selected
          if (selectedMarker != null)
            Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VendorDetailsPage(
                          vendorName: selectedMarker!.businessName,
                          vendorAddress:
                              "Vendor Address Here", // Replace with actual address
                          vendorLocation: google_maps.LatLng(
                            selectedMarker!.location.latitude,
                            selectedMarker!.location.longitude,
                          ),
                          vendorId: selectedMarker!.vendorId,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Center(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'assets/store.png',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        selectedMarker!.businessName,
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.star,
                                              color: Colors.amber, size: 18),
                                          Text(" 4.1 (88)",
                                              style: TextStyle(fontSize: 14)),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Open • Closes 10 PM",
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.green),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.phone,
                                              size: 14,
                                              color: Colors.grey[700]),
                                          SizedBox(width: 4),
                                          Text(
                                            selectedMarker!.phone,
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700]),
                                          ),
                                          SizedBox(width: 8),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () =>
                                      _openWhatsAppChat(selectedMarker!.phone),
                                  icon: Icon(Icons.message),
                                  label: Text('WhatsApp'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.green,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _openInGoogleMaps(
                                      selectedMarker!.location),
                                  icon: Icon(Icons.directions),
                                  label: Text('Directions'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

// Model class to hold vendor information
class VendorLocation {
  final LatLng location;
  final String businessName;
  final String phone;
  final String vendorId;

  VendorLocation({
    required this.location,
    required this.businessName,
    required this.phone,
    required this.vendorId,
  });
}
