import 'package:flutter/material.dart';
import 'report_issue_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      

      appBar: AppBar(
        title: const Text("Community Reports"),
        
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            reportCard(
              "MG Road",
              "Poor Street Lighting",
              "Reported 4 times",
              Icons.lightbulb_outline,
            ),

            reportCard(
              "Majestic",
              "Harassment Report",
              "Reported 2 times",
              Icons.warning_amber,
            ),

            reportCard(
              "Indiranagar",
              "Suspicious Activity",
              "Reported 3 times",
              Icons.visibility,
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ReportIssueScreen(),
                    ),
                  );
                },

                icon: const Icon(Icons.add),

                label: const Text(
                  "Report Unsafe Area",
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFFF7FA7),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget reportCard(
    String location,
    String issue,
    String reports,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),

      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFEEF4),

          child: Icon(
            icon,
            color: Colors.pink,
          ),
        ),

        title: Text(location),

        subtitle: Text(
          "$issue\n$reports",
        ),

        isThreeLine: true,
      ),
    );
  }
}
