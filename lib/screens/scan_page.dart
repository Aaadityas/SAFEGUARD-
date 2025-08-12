import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final TextEditingController _urlController = TextEditingController();
  String _result = '';
  bool _isLoading = false;

  // Replace with your API key
  final String apiKey = "YOUR_API_KEY_HERE";

  Future<void> checkUrlSafety() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _result = "Please enter a URL.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result = '';
    });

    final apiUrl =
        "https://safebrowsing.googleapis.com/v4/threatMatches:find?key=$apiKey";

    final body = {
      "client": {"clientId": "flutter-app", "clientVersion": "1.0"},
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

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _result = data['matches'] != null && data['matches'].isNotEmpty
              ? "⚠️ This link is unsafe!"
              : "✅ This link is safe.";
        });
      } else {
        setState(() {
          _result = "Error checking URL safety.";
        });
      }
    } catch (e) {
      setState(() {
        _result = "Network error: $e";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan a Link")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: "Enter URL",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: checkUrlSafety,
              child: const Text("Check Safety"),
            ),
            const SizedBox(height: 20),
            if (_isLoading) const CircularProgressIndicator(),
            if (_result.isNotEmpty)
              Text(
                _result,
                style: TextStyle(
                  fontSize: 18,
                  color: _result.contains("unsafe") ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
