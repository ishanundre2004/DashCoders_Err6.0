import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateTotal();
  }

  Future<void> updateProductQuantity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not signed in!')),
      );
      return;
    }

    // Reference to the cart collection
    final cartRef =
        _firestore.collection('users').doc(user.uid).collection('cart');

    // Fetch all cart items
    final cartItems = await cartRef.get();

    for (var cartItem in cartItems.docs) {
      final cartData = cartItem.data();
      String productName = cartData['productName'];
      String vendorName = cartData['vendorName'];
      int cartQuantity = cartData['quantity'];

      // Search for the matching product in Firestore based on vendor and product name
      final productQuery = await _firestore
          .collection('inventory') // Change this to your actual collection name
          .where('businessName', isEqualTo: vendorName)
          .where('name', isEqualTo: productName)
          .get();

      if (productQuery.docs.isNotEmpty) {
        final productDoc = productQuery.docs.first;
        final productData = productDoc.data();
        int currentStock = productData['quantity'] ?? 0;

        // Ensure stock doesn't go negative
        int updatedStock =
            (currentStock - cartQuantity).clamp(0, double.infinity).toInt();

        // Update the stock in Firestore
        await _firestore.collection('inventory').doc(productDoc.id).update({
          'quantity': updatedStock,
        });
      }
    }

    // Clear the cart after successful update
    await cartRef.get().then((snapshot) {
      for (DocumentSnapshot doc in snapshot.docs) {
        doc.reference.delete();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order Confirmed & Stock Updated!')),
    );

    // Navigate to a success page or back to home
    Navigator.pop(context);
  }

  Future<void> _calculateTotal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    double total = 0.0;
    final cartItems = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .get();

    for (var doc in cartItems.docs) {
      final data = doc.data();
      total += (data['quantity'] ?? 1) * (data['price'] ?? 0.0);
    }

    setState(() {
      _totalAmount = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.teal,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseAuth.instance.currentUser != null
                ? _firestore
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('cart')
                    .snapshots()
                : Stream.empty(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'Your cart is empty!',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final item = snapshot.data!.docs[index];
                        final itemData = item.data() as Map<String, dynamic>;

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              itemData['productName'] ?? 'Unknown Product',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Sold by: ${itemData['vendorName'] ?? 'Unknown Vendor'}",
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  "Quantity: ${itemData['quantity'] ?? 1}",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            trailing: Text(
                              "₹${((itemData['quantity'] ?? 1) * (itemData['price'] ?? 0.0)).toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total Amount:",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "₹${_totalAmount.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              await updateProductQuantity();
                              // ScaffoldMessenger.of(context).showSnackBar(
                              //   const SnackBar(
                              //     content: Text("Proceeding to payment..."),
                              //     backgroundColor: Colors.teal,
                              //   ),
                              // );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              'confirm',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
