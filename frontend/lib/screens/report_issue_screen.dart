import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() =>
      _ReportIssueScreenState();
}

class _ReportIssueScreenState
    extends State<ReportIssueScreen> {

  String selectedIssue = "Harassment";
  String selectedSeverity = "Medium";

  final TextEditingController descriptionController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      

      appBar: AppBar(
        title: const Text("Report Unsafe Area"),
        
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Location",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(15),
              ),

              child: const Row(
                children: [
                  Icon(Icons.location_on),
                  SizedBox(width: 10),
                  Text("Current Location"),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Issue Type",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField(
              value: selectedIssue,

              items: const [
                DropdownMenuItem(
                  value: "Harassment",
                  child: Text("Harassment"),
                ),
                DropdownMenuItem(
                  value: "Poor Lighting",
                  child: Text("Poor Lighting"),
                ),
                DropdownMenuItem(
                  value: "Suspicious Activity",
                  child: Text("Suspicious Activity"),
                ),
                DropdownMenuItem(
                  value: "Stalking",
                  child: Text("Stalking"),
                ),
                DropdownMenuItem(
                  value: "Unsafe Walkway",
                  child: Text("Unsafe Walkway"),
                ),
              ],

              onChanged: (value) {
                setState(() {
                  selectedIssue = value!;
                });
              },
            ),

            const SizedBox(height: 25),

            const Text(
              "Description",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: descriptionController,
              maxLines: 4,

              decoration: InputDecoration(
                hintText:
                    "Describe what happened...",
                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Severity",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField(
              value: selectedSeverity,

              items: const [
                DropdownMenuItem(
                  value: "Low",
                  child: Text("Low"),
                ),
                DropdownMenuItem(
                  value: "Medium",
                  child: Text("Medium"),
                ),
                DropdownMenuItem(
                  value: "High",
                  child: Text("High"),
                ),
              ],

              onChanged: (value) {
                setState(() {
                  selectedSeverity = value!;
                });
              },
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(
                onPressed: () async {
                  final api = context.read<ApiService>();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Submitting...'), duration: Duration(seconds: 1)),
                  );
                  
                  final success = await api.reportHazard(
                    selectedIssue, 
                    37.7749, // mock lat
                    -122.4194, // mock lng
                    descriptionController.text
                  );

                  if (context.mounted) {
                    if (success) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Report Submitted"),
                          content: const Text("Thank you for helping keep the community safe."),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // close dialog
                                Navigator.pop(context); // go back
                              },
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to submit report'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFFF7FA7),
                ),

                child: const Text(
                  "Submit Report",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
