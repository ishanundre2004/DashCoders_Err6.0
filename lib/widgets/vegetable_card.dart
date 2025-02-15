import 'dart:convert';
import 'package:flutter/material.dart';

class VegetableCard extends StatelessWidget {
  final String name;
  final String price;
  final String quantity;
  final String vendor;
  final String imageUrl;
  final bool isBase64;

  const VegetableCard({
    Key? key,
    required this.name,
    required this.price,
    required this.quantity,
    required this.vendor,
    required this.imageUrl,
    this.isBase64 = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double cardWidth = MediaQuery.of(context).size.width * 0.42;
    double imageHeight = MediaQuery.of(context).size.height * 0.12;

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF080F20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: isBase64
                ? Image.memory(
                    base64Decode(imageUrl),
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    imageUrl,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text("Price: ₹$price",
                    style: const TextStyle(
                        color: Colors.greenAccent, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                Text("Qty: $quantity",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                Text("Vendor: $vendor",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VegetableList extends StatelessWidget {
  final List<Map<String, String>> vegetables = [
    {
      "name": "Wheat",
      "price": "50/kg",
      "quantity": "1 kg",
      "vendor": "Fresh Farm",
      "imageUrl":
          "https://upload.wikimedia.org/wikipedia/commons/8/89/Tomato_j.jpg"
    },
    {
      "name": "Potato",
      "price": "30/kg",
      "quantity": "1 kg",
      "vendor": "Organic Mart",
      "imageUrl":
          "https://upload.wikimedia.org/wikipedia/commons/a/ab/Patates.jpg"
    },
    {
      "name": "Tomato",
      "price": "60/kg",
      "quantity": "1 kg",
      "vendor": "Agro Fresh",
      "imageUrl":
          "https://upload.wikimedia.org/wikipedia/commons/8/89/Tomato_je.jpg"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.30, // Dynamic height
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Enable horizontal scrolling
        child: Row(
          children: vegetables.map((veg) {
            return VegetableCard(
              name: veg["name"]!,
              price: veg["price"]!,
              quantity: veg["quantity"]!,
              vendor: veg["vendor"]!,
              imageUrl: veg["imageUrl"]!,
            );
          }).toList(),
        ),
      ),
    );
  }
}
