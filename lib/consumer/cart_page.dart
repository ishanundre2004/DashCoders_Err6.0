import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateTotal();
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
      _isLoading = false;
    });
  }

  Future<void> _updateQuantity(String itemId, int newQuantity) async {
    if (newQuantity < 1) return _removeItem(itemId);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(itemId)
        .update({'quantity': newQuantity});

    _calculateTotal();
  }

  Future<void> _removeItem(String itemId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(itemId)
        .delete();

    _calculateTotal();
  }

  void _proceedToCheckout() {
    Navigator.pushNamed(context, '/checkout');
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
                ),
              ),
            ),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Text(
                              'My Cart',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
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
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text(
                                  'Your cart is empty',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.black54),
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                final item = snapshot.data!.docs[index];
                                final itemData =
                                    item.data() as Map<String, dynamic>;

                                return Dismissible(
                                  key: Key(item.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    color: Colors.red,
                                    child: const Icon(Icons.delete,
                                        color: Colors.white),
                                  ),
                                  onDismissed: (direction) {
                                    _removeItem(item.id);
                                  },
                                  child: Card(
                                    elevation: 4,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          // Product Image
                                          Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              image: DecorationImage(
                                                image: NetworkImage(
                                                    itemData['imageUrl'] ?? ''),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),

                                          // Product Details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  itemData['productName'] ??
                                                      'Unknown',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),

                                                // ✅ Display Vendor Name
                                                Text(
                                                  'Sold by: ${itemData['vendorName'] ?? 'Unknown'}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black54,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),

                                                // Price
                                                Text(
                                                  '₹${(itemData['price'] ?? 0.0).toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Quantity Controls
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove),
                                                onPressed: () =>
                                                    _updateQuantity(
                                                        item.id,
                                                        (itemData['quantity'] ??
                                                                1) -
                                                            1),
                                              ),
                                              Text(
                                                '${itemData['quantity'] ?? 1}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add),
                                                onPressed: () =>
                                                    _updateQuantity(
                                                        item.id,
                                                        (itemData['quantity'] ??
                                                                1) +
                                                            1),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Amount:',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₹${_totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _proceedToCheckout,
                                child: const Text('Proceed to Checkout'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
