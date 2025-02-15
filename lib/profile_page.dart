import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dukaan/consumer/consumer_home_page.dart';
import 'package:dukaan/vendor/vendor_home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _businessNameController = TextEditingController();
  File? _selectedImage;
  String? _base64Image;
  String _role = 'Consumer';
  String? _latLong;
  String? _address;
  bool _isLoading = false;
  bool _isLocationLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _businessNameController.dispose(); // Dispose business name controller
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data();
          setState(() {
            _nameController.text = data?['name'] ?? '';
            _phoneController.text = data?['phone'] ?? '';
            _role = data?['role'] ?? 'Consumer';
            _businessNameController.text = data?['businessName'];
            if (data?['location'] != null) {
              _latLong = data?['location']['coordinates'];
              _address = data?['location']['address'];
              _locationController.text = _address ?? '';
            }
          });
        }
      } catch (e) {
        _showErrorSnackbar('Error loading profile data');
      }
    }
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorSnackbar('Location services are disabled');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorSnackbar('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorSnackbar('Location permissions are permanently denied');
      return false;
    }

    return true;
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLocationLoading = true);

    try {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        setState(() => _isLocationLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      _latLong = "${position.latitude}, ${position.longitude}";

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        _address =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}";

        setState(() {
          _locationController.text = _address ?? _latLong!;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error fetching location: $e');
    } finally {
      setState(() => _isLocationLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackbar('No user signed in');
        return;
      }

      final userData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': user.email,
        'role': _role,
        'isProfileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_role == 'Vendor') {
        if (_latLong == null || _address == null) {
          _showErrorSnackbar('Please set your business location');
          setState(() => _isLoading = false);
          return;
        }
        if (_businessNameController.text.trim().isEmpty) {
          _showErrorSnackbar('Please enter your business name');
          setState(() => _isLoading = false);
          return;
        }
        userData['businessName'] =
            _businessNameController.text.trim(); // Add business name
        userData['location'] = {
          'coordinates': _latLong,
          'address': _address,
        };
        if (_base64Image != null && _base64Image!.isNotEmpty) {
          userData['img'] = _base64Image; // Store Base64 string in Firestore
        } else {
          _showErrorSnackbar('Please upload a business image');
          setState(() => _isLoading = false);
          return;
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      if (!mounted) return;

      if (_role == 'Consumer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ConsumerHomePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VendorHomePage()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Error saving profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // For camera
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (status.isDenied) {
          throw PlatformException(
            code: 'PERMISSION_DENIED',
            message: 'Camera permission is required',
          );
        }
      }

      // For gallery
      if (source == ImageSource.gallery) {
        final status = await Permission.storage.request();
        if (status.isDenied) {
          throw PlatformException(
            code: 'PERMISSION_DENIED',
            message: 'Storage permission is required',
          );
        }
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final File imageFile = File(pickedFile.path);
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);

      setState(() {
        _selectedImage = imageFile;
        _base64Image = base64String;
      });

      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackbar('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color.fromARGB(255, 255, 153, 0),
                  Color.fromARGB(255, 255, 178, 63),
                  Color.fromARGB(255, 250, 216, 165),
                ],
              ),
            ),
          ),
          // Container(color: Colors.black.withOpacity(0.5)),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 25.0, right: 25.0, top: 120),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Set Up Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8F4A3B),
                        fontSize: 25,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildTextField(
                      controller: _nameController,
                      labelText: 'Full Name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _phoneController,
                      labelText: 'Phone Number',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length != 10) {
                          return 'Please enter a valid 10-digit number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Select Role:',
                      style: TextStyle(color: Color(0xFF8F4A3B), fontSize: 16),
                    ),
                    Row(
                      children: [
                        _buildRadioButton('Consumer'),
                        _buildRadioButton('Vendor'),
                      ],
                    ),
                    if (_role == 'Vendor') ...[
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _businessNameController,
                        labelText: 'Business Name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your business name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _locationController,
                        labelText: 'Business Location',
                        enabled: false,
                        validator: (value) {
                          if (_role == 'Vendor' &&
                              (value == null || value.isEmpty)) {
                            return 'Please set your business location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      _buildButton(
                        text: _isLocationLoading
                            ? 'Fetching Location...'
                            : 'Fetch Current Location',
                        onPressed: _isLocationLoading ? null : _fetchLocation,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 249, 228, 196),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Color.fromARGB(255, 249, 228, 196),
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
                        child: InkWell(
                          onTap: _showImageSourceDialog,
                          child: _selectedImage == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: Color(0xFF8F4A3B),
                                      size: 40,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tap to add product image',
                                      style: TextStyle(
                                        color: Color(0xFF8F4A3B),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    _buildButton(
                      text: _isLoading ? 'Saving...' : 'Save Profile',
                      onPressed: _isLoading ? null : _saveProfile,
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

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color.fromARGB(255, 249, 228, 196),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                  title: const Text(
                    'Take a Photo',
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 16,
                    ),
                  ),
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      color: Color.fromARGB(255, 5, 4, 7),
                      fontSize: 16,
                    ),
                  ),
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled && !_isLoading,
      style: const TextStyle(
        color: Color(0xFF8F4A3B),
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(
          color: Color(0xFF8F4A3B),
        ),
        filled: true,
        fillColor: Color.fromARGB(255, 249, 228, 196),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
          borderSide: BorderSide(
            color: Color.fromARGB(255, 249, 228, 196),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
          borderSide:
              BorderSide(color: Color.fromARGB(255, 249, 228, 196), width: 2),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
          borderSide:
              BorderSide(color: Color.fromARGB(255, 249, 228, 196), width: 0.5),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildRadioButton(String value) {
    return Expanded(
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: _role,
            onChanged: _isLoading
                ? null
                : (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _role = newValue;
                        if (newValue == 'Consumer') {
                          _locationController.clear();
                          _latLong = null;
                          _address = null;
                        }
                      });
                    }
                  },
            activeColor: const Color(0xFF8F4A3B),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF8F4A3B),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade400,
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
      child: SizedBox(
        height: 50.0,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade400,
            elevation: 0,
            shadowColor: const Color(0xFF0E0E29),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
