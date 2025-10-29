import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  bool _autoScan = false;
  bool _notifications = true;
  bool _darkMode = false;
  bool _saveHistory = true;
  bool _biometricAuth = false;
  bool _autoUpdate = true;
  String _selectedLanguage = 'English';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
                            Icon(Icons.settings_rounded, color: Colors.white, size: 24),
                            SizedBox(width: 12),
                            Text(
                              "Settings",
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Card
                        FadeTransition(
                          opacity: _animationController,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00D4FF), Color(0xFF7B2CBF)],
                              ),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00D4FF).withOpacity(0.4),
                                  blurRadius: 25,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 44),
                                ),
                                const SizedBox(width: 18),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "SafeLinkGuard User",
                                        style: TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        "Premium Account",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Security Section
                        _buildSectionTitle("Security & Privacy", Icons.security_rounded, const Color(0xFFFF006E)),
                        const SizedBox(height: 16),
                        _buildSettingCard(
                          title: "Auto Scan Clipboard",
                          subtitle: "Automatically scan URLs from clipboard",
                          icon: Icons.content_paste_rounded,
                          gradientColors: const [Color(0xFF00D4FF), Color(0xFF0066FF)],
                          trailing: Switch(
                            value: _autoScan,
                            onChanged: (value) {
                              setState(() {
                                _autoScan = value;
                              });
                              _showSnackBar("Auto scan ${value ? 'enabled' : 'disabled'}");
                            },
                            activeColor: const Color(0xFF00D4FF),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildSettingCard(
                          title: "Save Scan History",
                          subtitle: "Keep record of all scanned URLs",
                          icon: Icons.history_rounded,
                          gradientColors: const [Color(0xFF00F260), Color(0xFF0575E6)],
                          trailing: Switch(
                            value: _saveHistory,
                            onChanged: (value) {
                              setState(() {
                                _saveHistory = value;
                              });
                            },
                            activeColor: const Color(0xFF00F260),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildSettingCard(
                          title: "Biometric Authentication",
                          subtitle: "Use fingerprint or face ID",
                          icon: Icons.fingerprint_rounded,
                          gradientColors: const [Color(0xFF7B2CBF), Color(0xFFFF006E)],
                          trailing: Switch(
                            value: _biometricAuth,
                            onChanged: (value) {
                              setState(() {
                                _biometricAuth = value;
                              });
                              _showSnackBar("Biometric auth ${value ? 'enabled' : 'disabled'}");
                            },
                            activeColor: const Color(0xFF7B2CBF),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Notifications Section
                        _buildSectionTitle("Notifications", Icons.notifications_rounded, const Color(0xFFFB5607)),
                        const SizedBox(height: 16),
                        _buildSettingCard(
                          title: "Push Notifications",
                          subtitle: "Get alerts about security threats",
                          icon: Icons.notification_important_rounded,
                          gradientColors: const [Color(0xFFFB5607), Color(0xFFFF006E)],
                          trailing: Switch(
                            value: _notifications,
                            onChanged: (value) {
                              setState(() {
                                _notifications = value;
                              });
                            },
                            activeColor: const Color(0xFFFB5607),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildSettingCard(
                          title: "Auto Update",
                          subtitle: "Automatically update threat database",
                          icon: Icons.cloud_download_rounded,
                          gradientColors: const [Color(0xFF00D4FF), Color(0xFF0066FF)],
                          trailing: Switch(
                            value: _autoUpdate,
                            onChanged: (value) {
                              setState(() {
                                _autoUpdate = value;
                              });
                            },
                            activeColor: const Color(0xFF00D4FF),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Appearance Section
                        _buildSectionTitle("Appearance", Icons.palette_rounded, const Color(0xFF7B2CBF)),
                        const SizedBox(height: 16),
                        _buildSettingCard(
                          title: "Dark Mode",
                          subtitle: "Enable dark theme",
                          icon: Icons.dark_mode_rounded,
                          gradientColors: const [Color(0xFF16213E), Color(0xFF0F3460)],
                          trailing: Switch(
                            value: _darkMode,
                            onChanged: (value) {
                              setState(() {
                                _darkMode = value;
                              });
                              _showSnackBar("Dark mode ${value ? 'enabled' : 'disabled'}");
                            },
                            activeColor: const Color(0xFF16213E),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildSettingCard(
                          title: "Language",
                          subtitle: _selectedLanguage,
                          icon: Icons.language_rounded,
                          gradientColors: const [Color(0xFF00F260), Color(0xFF0575E6)],
                          onTap: () => _showLanguageDialog(),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 20, color: Colors.white),
                        ),

                        const SizedBox(height: 32),

                        // About Section
                        _buildSectionTitle("About & Support", Icons.info_rounded, const Color(0xFF00D4FF)),
                        const SizedBox(height: 16),
                        _buildSettingCard(
                          title: "App Version",
                          subtitle: "1.0.0 (Latest)",
                          icon: Icons.info_outline_rounded,
                          gradientColors: const [Color(0xFF00D4FF), Color(0xFF7B2CBF)],
                        ),
                        const SizedBox(height: 14),
                        _buildSettingCard(
                          title: "Privacy Policy",
                          subtitle: "Read our privacy policy",
                          icon: Icons.privacy_tip_rounded,
                          gradientColors: const [Color(0xFF00F260), Color(0xFF0575E6)],
                          onTap: () => _showSnackBar("Opening privacy policy..."),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 20, color: Colors.white),
                        ),
                        const SizedBox(height: 14),
                        _buildSettingCard(
                          title: "Terms of Service",
                          subtitle: "Read our terms of service",
                          icon: Icons.description_rounded,
                          gradientColors: const [Color(0xFF7B2CBF), Color(0xFFFF006E)],
                          onTap: () => _showSnackBar("Opening terms of service..."),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 20, color: Colors.white),
                        ),
                        const SizedBox(height: 14),
                        _buildSettingCard(
                          title: "Rate App",
                          subtitle: "Share your feedback",
                          icon: Icons.star_rounded,
                          gradientColors: const [Color(0xFFFB5607), Color(0xFFFF006E)],
                          onTap: () => _showRatingDialog(),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 20, color: Colors.white),
                        ),
                        const SizedBox(height: 14),
                        _buildSettingCard(
                          title: "Help & Support",
                          subtitle: "Get help with the app",
                          icon: Icons.help_rounded,
                          gradientColors: const [Color(0xFF00D4FF), Color(0xFF0066FF)],
                          onTap: () => _showSnackBar("Opening support..."),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 20, color: Colors.white),
                        ),

                        const SizedBox(height: 32),

                        // Data Management
                        _buildSectionTitle("Data Management", Icons.storage_rounded, const Color(0xFF00F260)),
                        const SizedBox(height: 16),
                        _buildSettingCard(
                          title: "Clear Cache",
                          subtitle: "Free up storage space",
                          icon: Icons.cleaning_services_rounded,
                          gradientColors: const [Color(0xFF00D4FF), Color(0xFF7B2CBF)],
                          onTap: () => _showClearCacheDialog(),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 20, color: Colors.white),
                        ),
                        const SizedBox(height: 14),
                        _buildSettingCard(
                          title: "Export Data",
                          subtitle: "Export your scan history",
                          icon: Icons.download_rounded,
                          gradientColors: const [Color(0xFF00F260), Color(0xFF0575E6)],
                          onTap: () => _showSnackBar("Exporting data..."),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 20, color: Colors.white),
                        ),
                        const SizedBox(height: 14),
                        _buildSettingCard(
                          title: "Backup & Restore",
                          subtitle: "Backup your settings",
                          icon: Icons.backup_rounded,
                          gradientColors: const [Color(0xFF00D4FF), Color(0xFF0066FF)],
                          onTap: () => _showSnackBar("Backup feature coming soon..."),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 20, color: Colors.white),
                        ),

                        const SizedBox(height: 36),

                        // Danger Zone
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFF006E).withOpacity(0.2),
                                const Color(0xFFFF5E62).withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFFF006E).withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFF006E), Color(0xFFFF5E62)],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF006E).withOpacity(0.5),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.warning_rounded, color: Colors.white, size: 26),
                                  ),
                                  const SizedBox(width: 14),
                                  const Text(
                                    "Danger Zone",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF006E),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF006E), Color(0xFFFF5E62)],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF006E).withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    minimumSize: const Size(double.infinity, 0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () => _showDeleteAccountDialog(),
                                  icon: const Icon(Icons.delete_forever_rounded, size: 24),
                                  label: const Text(
                                    "Delete All Data",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 36),

                        // App Info Footer
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00D4FF), Color(0xFF7B2CBF)],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00D4FF).withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.shield_rounded,
                                  color: Colors.white,
                                  size: 44,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                "SafeLinkGuard",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Protecting you from malicious links",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF7B2CBF).withOpacity(0.3),
                                      const Color(0xFFFF006E).withOpacity(0.3),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  "Made with ❤️ by Your Team",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
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

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    final languages = [
      {'name': 'English', 'icon': '🇬🇧'},
      {'name': 'Spanish', 'icon': '🇪🇸'},
      {'name': 'French', 'icon': '🇫🇷'},
      {'name': 'German', 'icon': '🇩🇪'},
      {'name': 'Hindi', 'icon': '🇮🇳'},
      {'name': 'Japanese', 'icon': '🇯🇵'},
      {'name': 'Chinese', 'icon': '🇨🇳'},
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00F260), Color(0xFF0575E6)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F260).withOpacity(0.5),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(Icons.language_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            const Text(
              "Select Language",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final lang = languages[index];
              final isSelected = _selectedLanguage == lang['name'];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF00F260), Color(0xFF0575E6)],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.08),
                            Colors.white.withOpacity(0.03),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? Colors.transparent 
                        : Colors.white.withOpacity(0.15),
                    width: 1.5,
                  ),
                ),
                child: ListTile(
                  leading: Text(
                    lang['icon']!,
                    style: const TextStyle(fontSize: 32),
                  ),
                  title: Text(
                    lang['name']!,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: Colors.white, size: 26)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedLanguage = lang['name']!;
                    });
                    Navigator.pop(context);
                    _showSnackBar("Language changed to ${lang['name']}");
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showRatingDialog() {
    int rating = 0;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          title: Row(
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
                      color: const Color(0xFFFB5607).withOpacity(0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.star_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              const Text(
                "Rate SafeLinkGuard",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "How would you rate our app?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFB5607).withOpacity(0.2),
                      const Color(0xFFFF006E).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFFB5607).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                        color: const Color(0xFFFB5607),
                        size: 40,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFB5607), Color(0xFFFF006E)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: rating > 0
                    ? () {
                        Navigator.pop(context);
                        _showSnackBar("Thank you for your $rating ⭐ rating!");
                      }
                    : null,
                child: const Text("Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF7B2CBF)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D4FF).withOpacity(0.5),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(Icons.cleaning_services_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            const Text(
              "Clear Cache",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "This will clear all cached data including:",
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 16),
            _buildCacheItem("Temporary files", "~12 MB"),
            _buildCacheItem("Image cache", "~8 MB"),
            _buildCacheItem("API responses", "~3 MB"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00D4FF).withOpacity(0.2),
                    const Color(0xFF7B2CBF).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF00D4FF).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF00D4FF), size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Total: ~23 MB will be freed",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF7B2CBF)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _showSnackBar("Cache cleared successfully - 23 MB freed");
              },
              child: const Text("Clear"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheItem(String label, String size) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 20,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
          Text(
            size,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF006E), Color(0xFFFF5E62)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF006E).withOpacity(0.5),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            const Text(
              "Delete All Data",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "This will permanently delete:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildDeleteItem("All scan history"),
            _buildDeleteItem("Saved settings"),
            _buildDeleteItem("User preferences"),
            _buildDeleteItem("Cached data"),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF006E).withOpacity(0.2),
                    const Color(0xFFFF5E62).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFF006E).withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Color(0xFFFF006E), size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "This action cannot be undone!",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF006E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF006E), Color(0xFFFF5E62)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _showSnackBar("All data has been deleted");
              },
              child: const Text("Delete All"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.close_rounded, size: 20, color: Color(0xFFFF006E)),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00F260),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}