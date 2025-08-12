import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final TextEditingController _urlController = TextEditingController();
  String _scanResult = "";
  bool _isLoading = false;

  Future<void> scanUrl(String url) async {
    const String apiKey = "AIzaSyCZoTdGtjw-kAx2hAKN2MOtW7TYo4vBYLs"; // Replace with your API key

    final Map<String, dynamic> requestBody = {
      "client": {
        "clientId": "safelinkguard",
        "clientVersion": "1.0"
      },
      "threatInfo": {
        "threatTypes": [
          "MALWARE",
          "SOCIAL_ENGINEERING",
          "UNWANTED_SOFTWARE",
          "POTENTIALLY_HARMFUL_APPLICATION"
        ],
        "platformTypes": ["ANY_PLATFORM"],
        "threatEntryTypes": ["URL"],
        "threatEntries": [
          {"url": url}
        ]
      }
    };

    setState(() {
      _isLoading = true;
      _scanResult = "";
    });

    try {
      final response = await http.post(
        Uri.parse(
            "https://safebrowsing.googleapis.com/v4/threatMatches:find?key=$apiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["matches"] != null && data["matches"].isNotEmpty) {
          setState(() {
            _scanResult = "⚠️ This link is dangerous!";
          });
        } else {
          setState(() {
            _scanResult = "✅ This link is safe.";
          });
        }
      } else {
        setState(() {
          _scanResult =
              "Error scanning URL: ${response.statusCode} - ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _scanResult = "An error occurred: $e";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan URL"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: "Enter URL to scan",
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                if (_urlController.text.isNotEmpty) {
                  scanUrl(_urlController.text.trim());
                }
              },
              child: const Text(
                "Scan Link",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_scanResult.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _scanResult.contains("safe")
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _scanResult.contains("safe")
                          ? Icons.check_circle
                          : Icons.warning,
                      color: _scanResult.contains("safe")
                          ? Colors.green
                          : Colors.red,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _scanResult,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _scanResult.contains("safe")
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
