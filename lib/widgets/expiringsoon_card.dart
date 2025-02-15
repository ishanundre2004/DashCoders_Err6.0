import 'package:flutter/material.dart';

class ExpiringSoonCard extends StatelessWidget {
  final String name;
  final String quantity;
  final String expiring;
  final String imageUrl;

  const ExpiringSoonCard({
    Key? key,
    required this.name,
    required this.quantity,
    required this.expiring,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double cardHeight = MediaQuery.of(context).size.height * 0.25;
    double cardWidth =
        MediaQuery.of(context).size.width * 0.42; // 42% of screen width
    double imageHeight =
        MediaQuery.of(context).size.height * 0.12; // Dynamic image height

    return Container(
      width: cardWidth,
      height: cardHeight,
      margin: EdgeInsets.symmetric(
          horizontal: 10, vertical: 5), // Space between cards
      decoration: BoxDecoration(
        color: Color(0xFF080F20), // Dark background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)), // Rounded top
            child: Image.network(
              imageUrl,
              height: imageHeight,
              width: double.infinity,
              fit: BoxFit.cover, // Cover the space
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                Text("Qty: $quantity",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                Text("Expiring in $expiring",
                    style: TextStyle(
                        color: const Color.fromARGB(179, 249, 3, 3),
                        fontSize: 14),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExpiringSoonList extends StatelessWidget {
  final List<Map<String, String>> vegetables = [
    {
      "name": "Tomato",
      "quantity": "1 kg",
      "expiring": "2 days",
      "imageUrl":
          "https://upload.wikimedia.org/wikipedia/commons/8/89/Tomato_je.jpg"
    },
    {
      "name": "Carrot",
      "quantity": "1 kg",
      "expiring": "2 days",
      "imageUrl":
          "https://upload.wikimedia.org/wikipedia/commons/a/a2/Carrots_bunched.jpg"
    },
    {
      "name": "Potato",
      "quantity": "1 kg",
      "expiring": "2 days",
      "imageUrl":
          "https://upload.wikimedia.org/wikipedia/commons/a/ab/Patates.jpg"
    },
    {
      "name": "Onion",
      "quantity": "1 kg",
      "expiring": "2 days",
      "imageUrl":
          "https://upload.wikimedia.org/wikipedia/commons/7/7b/Onions.jpg"
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
            return ExpiringSoonCard(
              name: veg["name"]!,
              quantity: veg["quantity"]!,
              expiring: veg["expiring"]!,
              imageUrl: veg["imageUrl"]!,
            );
          }).toList(),
        ),
      ),
    );
  }
}
