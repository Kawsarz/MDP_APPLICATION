import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;
  const SettingsPage({super.key, required this.onThemeChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = false;
  bool isFirebaseEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('darkMode') ?? false;
      isFirebaseEnabled = prefs.getBool('firebaseLogging') ?? true;
    });
  }

  Future<void> _updatePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _clearHiveData() async {
    final box = await Hive.openBox('powerData');
    await box.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("All local Hive data cleared."),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color color,
  }) =>
      Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        color: Theme.of(context).cardColor,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
          trailing: Switch(
            value: value,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: onChanged,
          ),
        ),
      );

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) =>
      Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        color: Theme.of(context).cardColor,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.15),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
          onTap: onTap,
        ),
      );

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B), // Fixed color
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/backgroun.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              ClipPath(
                clipper: WaveClipperTop(),
                child: Container(
                  width: double.infinity,
                  height: 190,
                  color: isDark ? Colors.black : Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.settings, size: 36, color: Colors.orange),
                      const SizedBox(height: 6),
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage theme, logging and data control',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('Appearance & Logging'),
                      _buildSwitchTile(
                        title: "Dark Mode",
                        subtitle: "Toggle between light and dark themes.",
                        value: isDarkMode,
                        onChanged: (val) {
                          setState(() => isDarkMode = val);
                          _updatePreference('darkMode', val);
                          widget.onThemeChanged(val);
                        },
                        icon: Icons.nights_stay,
                        color: Colors.yellow.shade700,
                      ),
                      _buildSwitchTile(
                        title: "Firebase Logging",
                        subtitle: "Enable or disable cloud logging.",
                        value: isFirebaseEnabled,
                        onChanged: (val) {
                          setState(() => isFirebaseEnabled = val);
                          _updatePreference('firebaseLogging', val);
                        },
                        icon: Icons.cloud,
                        color: Colors.blueAccent,
                      ),
                      _sectionHeader('Data Control'),
                      _buildActionTile(
                        title: 'Clear Local Data',
                        subtitle: 'Delete all locally stored sensor records.',
                        icon: Icons.delete,
                        iconColor: Colors.red,
                        onTap: _clearHiveData,
                      ),
                      _sectionHeader('About'),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        color: Theme.of(context).cardColor,
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: const [
                              CircleAvatar(
                                backgroundColor: Color(0xFFCBD5E1),
                                child: Icon(Icons.info_outline, color: Color(0xFF1E293B)),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TaqaTap',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Version 1.0.0',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Real-time solar power monitoring & logging tool.',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WaveClipperTop extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.85);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height * 0.85);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
