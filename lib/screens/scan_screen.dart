import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

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
  Map<String, dynamic>? _urlAnalysis;
  
  late AnimationController _scanAnimationController;
  late AnimationController _resultAnimationController;
  late AnimationController _waveController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  static const String _apiKey = "AIzaSyCZoTdGtjw-kAx2hAKN2MOtW7TYo4vBYLs";

  @override
  void initState() {
    super.initState();
    
    _scanAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _resultAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _rotationAnimation = Tween<double>(begin: 0, end: 2).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.linear),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultAnimationController, curve: Curves.elasticOut),
    );
    
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
    _scanAnimationController.dispose();
    _resultAnimationController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _clearResults() {
    setState(() {
      _scanResult = "";
      _threatTypes.clear();
      _urlAnalysis = null;
    });
    _resultAnimationController.reset();
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

  Map<String, dynamic> _analyzeUrl(String url) {
    final uri = Uri.parse(url);
    final suspiciousKeywords = [
      'login', 'verify', 'update', 'secure', 'account', 
      'bank', 'paypal', 'password', 'confirm', 'signin'
    ];
    final suspiciousTlds = ['.xyz', '.top', '.tk', '.ga', '.ml', '.cf'];
    
    int riskScore = 0;
    List<String> warnings = [];
    
    if (RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(uri.host)) {
      riskScore += 30;
      warnings.add('IP address instead of domain');
    }
    
    for (var tld in suspiciousTlds) {
      if (uri.host.endsWith(tld)) {
        riskScore += 25;
        warnings.add('Suspicious domain extension');
        break;
      }
    }
    
    for (var keyword in suspiciousKeywords) {
      if (url.toLowerCase().contains(keyword)) {
        riskScore += 15;
        warnings.add('Contains suspicious keyword: $keyword');
        break;
      }
    }
    
    if (url.length > 75) {
      riskScore += 10;
      warnings.add('Unusually long URL');
    }
    
    if (url.contains('@')) {
      riskScore += 20;
      warnings.add('Contains @ symbol (potential spoofing)');
    }
    
    final subdomain = uri.host.split('.');
    if (subdomain.length > 3) {
      riskScore += 15;
      warnings.add('Multiple subdomains detected');
    }
    
    return {
      'riskScore': riskScore,
      'warnings': warnings,
      'domain': uri.host,
      'protocol': uri.scheme,
      'pathLength': uri.path.length,
    };
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                backgroundColor == Colors.green ? Icons.check_circle_rounded : Icons.error_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? const Color(0xFFFF006E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> scanUrl(String url) async {
    if (url.isEmpty) {
      _showSnackBar("Please enter a URL to scan");
      return;
    }

    if (_apiKey == "YOUR_API_KEY_HERE") {
      _showSnackBar("API key not configured");
      return;
    }

    final formattedUrl = _formatUrl(url);
    
    if (!_isValidUrl(formattedUrl)) {
      _showSnackBar("Please enter a valid URL");
      return;
    }

    setState(() {
      _isLoading = true;
      _scanResult = "";
      _threatTypes.clear();
      _urlAnalysis = null;
    });

    _scanAnimationController.repeat();
    _focusNode.unfocus();

    _urlAnalysis = _analyzeUrl(formattedUrl);

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

    try {
      final response = await http.post(
        Uri.parse("https://safebrowsing.googleapis.com/v4/threatMatches:find?key=$_apiKey"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool hasThreats = data["matches"] != null && data["matches"].isNotEmpty;
        
        setState(() {
          _isSafe = !hasThreats;
          if (hasThreats) {
            _scanResult = "⚠️ Security Threat Detected!";
            _threatTypes = (data["matches"] as List)
                .map((match) => match["threatType"] as String)
                .toSet()
                .toList();
          } else {
            _scanResult = _urlAnalysis!['riskScore'] > 50
                ? "⚠️ Potentially Suspicious"
                : "✅ URL Appears Safe";
            _isSafe = _urlAnalysis!['riskScore'] <= 50;
          }
        });
        
        _scanAnimationController.stop();
        _resultAnimationController.reset();
        _resultAnimationController.forward();
        
      } else if (response.statusCode == 400) {
        _showSnackBar("Invalid request format");
      } else if (response.statusCode == 403) {
        _showSnackBar("API access denied");
      } else {
        _showSnackBar("Service temporarily unavailable");
      }
    } catch (e) {
      _showSnackBar("Network error. Check your connection.");
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _getThreatDescription(String threatType) {
    switch (threatType) {
      case 'MALWARE':
        return '🦠 Malware - Contains malicious software';
      case 'SOCIAL_ENGINEERING':
        return '🎭 Phishing - Deceptive content';
      case 'UNWANTED_SOFTWARE':
        return '⚠️ Unwanted Software - Suspicious downloads';
      case 'POTENTIALLY_HARMFUL_APPLICATION':
        return '📱 Harmful App - Potentially dangerous';
      default:
        return threatType;
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        setState(() {
          _urlController.text = clipboardData.text!.trim();
        });
        _showSnackBar("Pasted from clipboard", backgroundColor: const Color(0xFF00F260));
      } else {
        _showSnackBar("Clipboard is empty");
      }
    } catch (e) {
      _showSnackBar("Failed to access clipboard");
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern App Bar
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D4FF), Color(0xFF7B2CBF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D4FF).withOpacity(0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.radar_rounded, color: Colors.white, size: 24),
                            SizedBox(width: 12),
                            Text(
                              "URL Scanner",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1E1E30),
                        const Color(0xFF16213E).withOpacity(0.95),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Scanning indicator
                        if (_isLoading)
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF00D4FF).withOpacity(0.2),
                                  const Color(0xFF7B2CBF).withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF00D4FF).withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                RotationTransition(
                                  turns: _rotationAnimation,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF00D4FF), Color(0xFF7B2CBF)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00D4FF).withOpacity(0.5),
                                          blurRadius: 15,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.sync_rounded, color: Colors.white, size: 28),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Analyzing URL...",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Checking for security threats",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // URL Input Section
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.08),
                                Colors.white.withOpacity(0.03),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF00D4FF).withOpacity(0.15),
                                      const Color(0xFF7B2CBF).withOpacity(0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: TextField(
                                  controller: _urlController,
                                  focusNode: _focusNode,
                                  keyboardType: TextInputType.url,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (value) => scanUrl(value.trim()),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: "Enter URL to scan",
                                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                    hintText: "https://example.com",
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(10),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF00D4FF), Color(0xFF7B2CBF)],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF00D4FF).withOpacity(0.4),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.link_rounded, color: Colors.white, size: 22),
                                    ),
                                    suffixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_urlController.text.isNotEmpty)
                                          IconButton(
                                            icon: const Icon(Icons.clear_rounded),
                                            onPressed: _clearInput,
                                            color: Colors.white.withOpacity(0.7),
                                          ),
                                        Container(
                                          margin: const EdgeInsets.only(right: 10),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFFFF006E).withOpacity(0.2),
                                                const Color(0xFF7B2CBF).withOpacity(0.2),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.content_paste_rounded),
                                            onPressed: _pasteFromClipboard,
                                            color: const Color(0xFFFF006E),
                                          ),
                                        ),
                                      ],
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.05),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF00D4FF),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Scan Button
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00D4FF),
                                      Color(0xFF7B2CBF),
                                      Color(0xFFFF006E),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00D4FF).withOpacity(0.5),
                                      blurRadius: 25,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _isLoading ? null : () => scanUrl(_urlController.text.trim()),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      height: 62,
                                      child: Center(
                                        child: _isLoading
                                            ? Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  RotationTransition(
                                                    turns: _rotationAnimation,
                                                    child: const Icon(Icons.sync_rounded, size: 26, color: Colors.white),
                                                  ),
                                                  const SizedBox(width: 14),
                                                  const Text(
                                                    "Scanning...",
                                                    style: TextStyle(
                                                      fontSize: 19,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.search_rounded, size: 26, color: Colors.white),
                                                  SizedBox(width: 12),
                                                  Text(
                                                    "Scan URL Now",
                                                    style: TextStyle(
                                                      fontSize: 19,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Results Section
                        if (_scanResult.isNotEmpty)
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Column(
                              children: [
                                // Main Result Card
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _isSafe
                                          ? [const Color(0xFF00F260), const Color(0xFF0575E6)]
                                          : [const Color(0xFFFF006E), const Color(0xFFFF5E62)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isSafe ? const Color(0xFF00F260) : const Color(0xFFFF006E)).withOpacity(0.5),
                                        blurRadius: 35,
                                        offset: const Offset(0, 15),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          _isSafe ? Icons.verified_user_rounded : Icons.error_rounded,
                                          size: 80,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        _scanResult,
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 14),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.25),
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                        child: Text(
                                          _isSafe ? "No threats detected" : "Immediate action required",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      
                                      // Threat Details
                                      if (!_isSafe && _threatTypes.isNotEmpty) ...[
                                        const SizedBox(height: 28),
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.3),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              const Text(
                                                "🚨 Detected Threats:",
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              ...(_threatTypes.map((threat) => Container(
                                                margin: const EdgeInsets.only(bottom: 10),
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red.shade50,
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Icon(
                                                        Icons.warning_amber_rounded,
                                                        color: Colors.red.shade700,
                                                        size: 22,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 14),
                                                    Expanded(
                                                      child: Text(
                                                        _getThreatDescription(threat),
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.red.shade700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ))),
                                            ],
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 18),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.3),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.shield_outlined, color: Colors.white, size: 22),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  "⚠️ Do not visit this URL. It may harm your device or steal information.",
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // URL Analysis Card
                                if (_urlAnalysis != null)
                                  Container(
                                    padding: const EdgeInsets.all(26),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.08),
                                          Colors.white.withOpacity(0.03),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(26),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.15),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF00D4FF), Color(0xFF7B2CBF)],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.analytics_rounded, color: Colors.white, size: 22),
                                              SizedBox(width: 10),
                                              Text(
                                                "URL Analysis Report",
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 22),
                                        
                                        _buildAnalysisRow("Domain", _urlAnalysis!['domain'], Icons.language_rounded, const Color(0xFF00D4FF)),
                                        _buildAnalysisRow("Protocol", _urlAnalysis!['protocol'].toUpperCase(), Icons.security_rounded, const Color(0xFF7B2CBF)),
                                        _buildAnalysisRow("Risk Score", "${_urlAnalysis!['riskScore']}/100", Icons.speed_rounded, 
                                          _urlAnalysis!['riskScore'] > 50 ? const Color(0xFFFF006E) : const Color(0xFF00F260)),
                                        
                                        if (_urlAnalysis!['warnings'].isNotEmpty) ...[
                                          const SizedBox(height: 20),
                                          Divider(color: Colors.white.withOpacity(0.2), thickness: 1.5),
                                          const SizedBox(height: 20),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      const Color(0xFFFB5607).withOpacity(0.3),
                                                      const Color(0xFFFF006E).withOpacity(0.3),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.warning_amber_rounded,
                                                  size: 22,
                                                  color: Color(0xFFFB5607),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Text(
                                                "Security Warnings:",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 14),
                                          ...(_urlAnalysis!['warnings'] as List).map((warning) => 
                                            Container(
                                              margin: const EdgeInsets.only(bottom: 10),
                                              padding: const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    const Color(0xFFFB5607).withOpacity(0.15),
                                                    const Color(0xFFFF006E).withOpacity(0.15),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: const Color(0xFFFB5607).withOpacity(0.3),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(
                                                    Icons.error_outline_rounded,
                                                    size: 20,
                                                    color: Color(0xFFFB5607),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      warning,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                        // Safety Tips
                        if (_scanResult.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF7B2CBF).withOpacity(0.2),
                                  const Color(0xFFFF006E).withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFF7B2CBF).withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFFB5607), Color(0xFFFF006E)],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFF006E).withOpacity(0.5),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    const Text(
                                      "Safety Tips",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildTipItem("Always verify sender before clicking links", Icons.verified_user_rounded),
                                _buildTipItem("Check for HTTPS in website URLs", Icons.lock_rounded),
                                _buildTipItem("Be cautious of shortened URLs", Icons.link_off_rounded),
                                _buildTipItem("Trust your instincts - if it looks suspicious, it probably is", Icons.psychology_rounded),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFB5607).withOpacity(0.3),
                  const Color(0xFFFF006E).withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFFFB5607)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.85),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}