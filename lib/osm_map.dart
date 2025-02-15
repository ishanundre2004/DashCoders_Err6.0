import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OSMMapScreen extends StatefulWidget {
  @override
  _OSMMapScreenState createState() => _OSMMapScreenState();
}

class _OSMMapScreenState extends State<OSMMapScreen> {
  LatLng? selectedMarker;
  LatLng? currentLocation;
  final LatLng defaultLocation = LatLng(19.0760, 72.8777); // Mumbai, India
  List<LatLng> vendorLocations = [];

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

      List<LatLng> locations = [];
      for (var doc in querySnapshot.docs) {
        var coordinates = doc['location']['coordinates'];
        if (coordinates != null && coordinates is String) {
          List<String> latLng = coordinates.split(', ');
          if (latLng.length == 2) {
            double? lat = double.tryParse(latLng[0].trim());
            double? lng = double.tryParse(latLng[1].trim());
            if (lat != null && lng != null) {
              locations.add(LatLng(lat, lng));
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
                        point: vendorLocation,
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
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
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
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "S.M. Super Market",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 18),
                              Text(" 4.1 (88)", style: TextStyle(fontSize: 14)),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Supermarket",
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[700]),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Open • Closes 10 PM",
                            style: TextStyle(fontSize: 14, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
