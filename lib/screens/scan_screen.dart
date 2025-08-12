import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  String _scanResult = "";
  bool _isLoading = false;
  bool _isSafe = false;
  List<String> _threatTypes = [];
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // TODO: Move this to environment variables or secure storage
  // For now, use a placeholder - replace with your actual API key
  static const String _apiKey = "AIzaSyCZoTdGtjw-kAx2hAKN2MOtW7TYo4vBYLs";

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    // Listen to text changes to clear results
    _urlController.addListener(() {
      if (_urlController.text.isEmpty && _scanResult.isNotEmpty) {
        _clearResults();
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _clearResults() {
    setState(() {
      _scanResult = "";
      _threatTypes.clear();
    });
    _animationController.reset();
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.hasAuthority;
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> scanUrl(String url) async {
    // Input validation
    if (url.isEmpty) {
      _showErrorSnackBar("Please enter a URL to scan");
      return;
    }

    // Check if API key is configured
    if (_apiKey == "YOUR_GOOGLE_SAFE_BROWSING_API_KEY_HERE") {
      _showErrorSnackBar("API key not configured. Please add your Google Safe Browsing API key.");
      return;
    }

    final formattedUrl = _formatUrl(url);
    
    if (!_isValidUrl(formattedUrl)) {
      _showErrorSnackBar("Please enter a valid URL (e.g., https://example.com)");
      return;
    }

    final Map<String, dynamic> requestBody = {
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

    setState(() {
      _isLoading = true;
      _scanResult = "";
      _threatTypes.clear();
    });

    // Hide keyboard
    _focusNode.unfocus();

    try {
      final response = await http.post(
        Uri.parse("https://safebrowsing.googleapis.com/v4/threatMatches:find?key=$_apiKey"),
        headers: {
          "Content-Type": "application/json",
          "User-Agent": "SafeLinkGuard/1.0.0",
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool hasThreats = data["matches"] != null && data["matches"].isNotEmpty;
        
        setState(() {
          _isSafe = !hasThreats;
          if (hasThreats) {
            _scanResult = "This URL contains security threats!";
            _threatTypes = (data["matches"] as List)
                .map((match) => match["threatType"] as String)
                .toSet()
                .toList();
          } else {
            _scanResult = "This URL appears to be safe";
          }
        });
        
        _animationController.reset();
        _animationController.forward();
        
      } else if (response.statusCode == 400) {
        _showErrorSnackBar("Invalid request format. Please check the URL.");
      } else if (response.statusCode == 403) {
        _showErrorSnackBar("API access denied. Please check your API key and quota.");
      } else if (response.statusCode == 429) {
        _showErrorSnackBar("Too many requests. Please try again later.");
      } else {
        _showErrorSnackBar("Service temporarily unavailable (${response.statusCode})");
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        _showErrorSnackBar("Request timed out. Please check your connection and try again.");
      } else {
        _showErrorSnackBar("Network error. Please check your internet connection.");
      }
      debugPrint("Scan error: $e");
    }

    setState(() {
      _isLoading = false;
    });
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

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        setState(() {
          _urlController.text = clipboardData.text!.trim();
        });
      } else {
        _showErrorSnackBar("Clipboard is empty");
      }
    } catch (e) {
      _showErrorSnackBar("Failed to access clipboard");
    }
  }

  void _clearInput() {
    setState(() {
      _urlController.clear();
    });
    _clearResults();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan URL"),
        centerTitle: true,
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.security_rounded,
                      size: 48,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "URL Security Scanner",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Check any link for potential security threats",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade600,
                      ),
                      textAlign: TextAlign.center,
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
                onSubmitted: (value) => scanUrl(value.trim()),
                decoration: InputDecoration(
                  labelText: "Enter URL to scan",
                  hintText: "https://example.com",
                  prefixIcon: const Icon(Icons.link_rounded),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_urlController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: _clearInput,
                          tooltip: "Clear URL",
                        ),
                      IconButton(
                        icon: const Icon(Icons.content_paste_rounded),
                        onPressed: _pasteFromClipboard,
                        tooltip: "Paste from clipboard",
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
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  onPressed: _isLoading ? null : () => scanUrl(_urlController.text.trim()),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.scanner_rounded),
                  label: Text(
                    _isLoading ? "Scanning URL..." : "Scan URL",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Results Section
              if (_scanResult.isNotEmpty)
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
                          size: 56,
                          color: _isSafe ? Colors.green.shade600 : Colors.red.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _scanResult,
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
                          Divider(color: Colors.red.shade300),
                          const SizedBox(height: 12),
                          Text(
                            "Security Threats Detected:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...(_threatTypes.map((threat) => Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  size: 20,
                                  color: Colors.red.shade600,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _getThreatDescription(threat),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))),
                          
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 20,
                                  color: Colors.orange.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Do not visit this URL. It may harm your device or steal your information.",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        // Safe URL additional info
                        if (_isSafe) ...[
                          const SizedBox(height: 12),
                          Text(
                            "No known security threats detected. However, always exercise caution when browsing.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}