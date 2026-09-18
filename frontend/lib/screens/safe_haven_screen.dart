import 'package:flutter/material.dart';

class SafeHavenScreen extends StatelessWidget {
  const SafeHavenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      

      appBar: AppBar(
        title: const Text("Nearby Safe Havens"),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                categoryChip("All"),
                categoryChip("Police"),
                categoryChip("Hospital"),
                categoryChip("Pharmacy"),
              ],
            ),

            const SizedBox(height: 25),

            Expanded(
              child: ListView(
                children: [

                  safePlaceCard(
                    "Indiranagar Police Station",
                    "0.8 km",
                    Icons.local_police,
                    Colors.blue,
                  ),

                  safePlaceCard(
                    "Manipal Hospital",
                    "1.2 km",
                    Icons.local_hospital,
                    Colors.red,
                  ),

                  safePlaceCard(
                    "24x7 Pharmacy",
                    "0.5 km",
                    Icons.medication,
                    Colors.green,
                  ),

                  safePlaceCard(
                    "Metro Station",
                    "0.9 km",
                    Icons.train,
                    Colors.purple,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget categoryChip(String text) {
    return Chip(
      label: Text(text),
      backgroundColor: const Color(0xFFFFEEF4),
    );
  }

  static Widget safePlaceCard(
    String title,
    String distance,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),

      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),

        title: Text(title),

        subtitle: Text(distance),

        trailing: ElevatedButton(
          onPressed: () {},

          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF7FA7),
          ),

          child: const Text(
            "Directions",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
