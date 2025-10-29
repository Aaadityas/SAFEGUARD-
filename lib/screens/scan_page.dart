import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'result_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  // Your Google Safe Browsing API key
  static const String apiKey = "YOUR_API_KEY";

  Future<void> _scanUrl(String url) async {
    setState(() => _loading = true);

    String result = "✅ Safe";

    try {
      // 1. Google Safe Browsing API request
      final response = await http.post(
        Uri.parse(
            "https://safebrowsing.googleapis.com/v4/threatMatches:find?key=$apiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "client": {"clientId": "safeguard-app", "clientVersion": "1.0"},
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
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["matches"] != null && data["matches"].isNotEmpty) {
          final threatType = data["matches"][0]["threatType"];
          if (threatType == "MALWARE") result = "🦠 Malware detected!";
          if (threatType == "UNWANTED_SOFTWARE") result = "⚠️ Unwanted software site detected!";
          if (threatType == "SOCIAL_ENGINEERING") result = "🎭 Phishing attempt detected!";
        } else {
          // Fallback: heuristic detection
          result = _heuristicCheck(url);
        }
      } else {
        // API failed → use heuristics
        result = _heuristicCheck(url);
      }
    } catch (e) {
      result = _heuristicCheck(url);
    }

    setState(() => _loading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(result: result),
      ),
    );
  }

  /// 🔹 Simple Heuristic Detection (backup if API fails)
  String _heuristicCheck(String url) {
    final suspiciousWords = [
      "login",
      "verify",
      "update",
      "secure",
      "bank",
      "paypal",
      "account",
      "free",
      "lottery",
      "gift"
    ];
    final suspiciousTlds = [".xyz", ".top", ".tk", ".ga"];

    for (var word in suspiciousWords) {
      if (url.toLowerCase().contains(word)) {
        return "🎭 Possible Phishing site!";
      }
    }

    for (var tld in suspiciousTlds) {
      if (url.toLowerCase().endsWith(tld)) {
        return "⚠️ Suspicious domain extension detected!";
      }
    }

    if (RegExp(r"https?:\/\/\d{1,3}(\.\d{1,3}){3}").hasMatch(url)) {
      return "🦠 IP-based URL (possible malware)!";
    }

    return "✅ Safe";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.black87],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "🔍 SafeGuard Scanner",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Enter URL to scan",
                      hintStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.black45,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      elevation: 10,
                    ),
                    onPressed: _loading
                        ? null
                        : () {
                            final url = _controller.text.trim();
                            if (url.isNotEmpty) {
                              _scanUrl(url);
                            }
                          },
                    child: _loading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "Scan Now",
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
