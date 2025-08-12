import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with TickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  String _result = '';
  bool _isLoading = false;
  bool _isSafe = false;
  List<String> _threatTypes = [];
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Replace with your API key
  final String apiKey = "YOUR_API_KEY_HERE";

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  String _formatUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'https://$url';
    }
    return url;
  }

  Future<void> checkUrlSafety() async {
    final url = _urlController.text.trim();
    
    if (url.isEmpty) {
      _showErrorSnackBar("Please enter a URL.");
      return;
    }

    final formattedUrl = _formatUrl(url);
    
    if (!_isValidUrl(formattedUrl)) {
      _showErrorSnackBar("Please enter a valid URL.");
      return;
    }

    setState(() {
      _isLoading = true;
      _result = '';
      _threatTypes.clear();
    });

    // Hide keyboard
    _focusNode.unfocus();

    final apiUrl =
        "https://safebrowsing.googleapis.com/v4/threatMatches:find?key=$apiKey";

    final body = {
      "client": {
        "clientId": "safelinkguard-app", 
        "clientVersion": "1.0.0"
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
          {"url": formattedUrl}
        ]
      }
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "User-Agent": "SafeLinkGuard/1.0.0",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool hasThreats = data['matches'] != null && data['matches'].isNotEmpty;
        
        setState(() {
          _isSafe = !hasThreats;
          if (hasThreats) {
            _result = "This link contains security threats!";
            _threatTypes = (data['matches'] as List)
                .map((match) => match['threatType'] as String)
                .toSet()
                .toList();
          } else {
            _result = "This link appears to be safe.";
          }
        });
        
        _animationController.reset();
        _animationController.forward();
        
      } else if (response.statusCode == 400) {
        _showErrorSnackBar("Invalid request. Please check your URL format.");
      } else if (response.statusCode == 403) {
        _showErrorSnackBar("API key invalid or quota exceeded.");
      } else {
        _showErrorSnackBar("Error checking URL safety (${response.statusCode}).");
      }
    } catch (e) {
      _showErrorSnackBar("Network error. Please check your connection.");
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearUrl() {
    setState(() {
      _urlController.clear();
      _result = '';
      _threatTypes.clear();
    });
    _animationController.reset();
  }

  void _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      _urlController.text = clipboardData!.text!;
    }
  }

  String _getThreatDescription(String threatType) {
    switch (threatType) {
      case 'MALWARE':
        return 'Contains malicious software';
      case 'SOCIAL_ENGINEERING':
        return 'Phishing or deceptive content';
      case 'UNWANTED_SOFTWARE':
        return 'Unwanted software downloads';
      case 'POTENTIALLY_HARMFUL_APPLICATION':
        return 'Potentially harmful applications';
      default:
        return threatType.replaceAll('_', ' ').toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan a Link"),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 48,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Enter any URL to check its safety",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // URL Input Section
              TextField(
                controller: _urlController,
                focusNode: _focusNode,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => checkUrlSafety(),
                decoration: InputDecoration(
                  labelText: "Enter URL",
                  hintText: "https://example.com",
                  prefixIcon: const Icon(Icons.link),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_urlController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearUrl,
                          tooltip: "Clear",
                        ),
                      IconButton(
                        icon: const Icon(Icons.paste),
                        onPressed: _pasteFromClipboard,
                        tooltip: "Paste",
                      ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Scan Button
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : checkUrlSafety,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.security),
                  label: Text(
                    _isLoading ? "Scanning..." : "Scan URL",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Results Section
              if (_result.isNotEmpty)
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _isSafe ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isSafe ? Colors.green.shade200 : Colors.red.shade200,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _isSafe ? Icons.verified_rounded : Icons.warning_rounded,
                          size: 48,
                          color: _isSafe ? Colors.green.shade600 : Colors.red.shade600,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _result,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isSafe ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        // Threat Details
                        if (!_isSafe && _threatTypes.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            "Detected Threats:",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...(_threatTypes.map((threat) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 16,
                                  color: Colors.red.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getThreatDescription(threat),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))),
                        ],
                      ],
                    ),
                  ),
                ),
              
              // Safety Tips
              if (_result.isEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.orange.shade600),
                          const SizedBox(width: 8),
                          Text(
                            "Safety Tips",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...[
                        "Always verify URLs before clicking",
                        "Be cautious of shortened links",
                        "Check for HTTPS encryption",
                        "Avoid suspicious email links",
                      ].map((tip) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("• ", style: TextStyle(color: Colors.grey.shade600)),
                            Expanded(
                              child: Text(
                                tip,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}