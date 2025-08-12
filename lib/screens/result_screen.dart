import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final bool isSafe; // true if safe, false if malicious
  final String message;

  const ResultScreen({
    super.key,
    required this.isSafe,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        backgroundColor: isSafe ? Colors.green : Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSafe ? Icons.check_circle : Icons.warning,
              color: isSafe ? Colors.green : Colors.red,
              size: 100,
            ),
            const SizedBox(height: 20),
            Text(
              isSafe ? "Safe Link" : "Malicious Link Detected",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSafe ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Go Back"),
            ),
          ],
        ),
      ),
    );
  }
}
