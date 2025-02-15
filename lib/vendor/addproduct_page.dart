import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _categoryController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;
  File? _selectedImage;
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFF3FEBB),
              surface: Color(0xFF52B6ED),
            ),
            dialogBackgroundColor: Color(0xFF080F20),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      _showErrorSnackbar('Please select an expiry date');
      return;
    }
    if (_base64Image == null) {
      _showErrorSnackbar('Please select an image');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackbar('No user signed in');
        return;
      }

      // Fetch the business name from the user's document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        _showErrorSnackbar('User document not found');
        return;
      }

      final businessName = userDoc['businessName'] as String?;
      if (businessName == null || businessName.isEmpty) {
        _showErrorSnackbar('Business name not found');
        return;
      }

      final productData = {
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'quantity': int.parse(_quantityController.text.trim()),
        'category': _categoryController.text.trim(),
        'imageBase64': _base64Image,
        'expiryDate': Timestamp.fromDate(_selectedDate!),
        'timestamp': FieldValue.serverTimestamp(),
        'vendorId': user.uid,
        'businessName':
            businessName, // Add the business name to the product data
      };

      await FirebaseFirestore.instance.collection('inventory').add(productData);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Error saving product: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                  Color(0xFF52B6ED),
                  Color(0xFFB4E0CC),
                  Color(0xFFF3FEBB),
                ],
                transform: GradientRotation(3.14 / 4),
              ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 0, 0, 0)),
            ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add New Product',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 25,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildTextField(
                      controller: _nameController,
                      labelText: 'Product Name',
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _priceController,
                      labelText: 'Price',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _quantityController,
                      labelText: 'Quantity',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _categoryController,
                      labelText: 'Category',
                    ),
                    const SizedBox(height: 20),

                    // Image Picker Section with Preview
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB9E3EE),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF3FEBB)),
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
                                    color: Color(0xFF615482),
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to add product image',
                                    style: TextStyle(
                                      color: Color(0xFF615482),
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
                    const SizedBox(height: 20),

                    // Date Picker
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB9E3EE),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF3FEBB)),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate == null
                                  ? 'Select Expiry Date'
                                  : 'Expiry Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                              style: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontSize: 16,
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF615482),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Submit Button
                    _buildButton(
                      text: _isLoading ? 'Adding Product...' : 'Add Product',
                      onPressed: _isLoading ? null : _saveProduct,
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
      backgroundColor: const Color(0xFFB9E3EE),
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        filled: true,
        fillColor: const Color(0xFFB9E3EE),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
          borderSide: BorderSide(color: Color(0xFFF3FEBB)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
          borderSide: BorderSide(color: Color(0xFFF3FEBB), width: 2),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
          borderSide: BorderSide(color: Color(0xFFF3FEBB), width: 0.5),
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Please enter $labelText' : null,
    );
  }

  Widget _buildButton(
      {required String text, required VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF615482), // Button color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
