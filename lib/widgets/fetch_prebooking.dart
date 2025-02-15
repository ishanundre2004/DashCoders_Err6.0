import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Widget fetchPreBookings() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('prebookings').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(child: Text('No pre-bookings available'));
      }

      return ListView.builder(
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) {
          var data = snapshot.data!.docs[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Product: ${data['productName']}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text("Business: ${data['businessName']}", style: const TextStyle(fontSize: 16)),
                  Text("Quantity: ${data['orderedQuantity']} kg", style: const TextStyle(fontSize: 16)),
                  Text("Price per Unit: \$${data['pricePerUnit']}", style: const TextStyle(fontSize: 16)),
                  Text("Total Price: \$${data['totalPrice']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("Status: ${data['status']}", style: const TextStyle(fontSize: 16, color: Colors.blue)),
                  const SizedBox(height: 8),
                  Text("Ordered on: ${data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate().toLocal().toString() : 'N/A'}", style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
