import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

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
    await Hive.box('powerData').clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🧹 All local data cleared."),
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
  }) => Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: Switch(value: value, onChanged: onChanged),
    ),
  );

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) => Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.15),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      onTap: onTap,
    ),
  );

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF334155),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('⚙️ Settings'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Appearance & Logging'),
            _buildSwitchTile(
              title: "🌙 Dark Mode",
              subtitle: "Toggle between light and dark themes.",
              value: isDarkMode,
              onChanged: (val) {
                setState(() => isDarkMode = val);
                _updatePreference('darkMode', val);
              },
              icon: Icons.brightness_6,
              color: Colors.deepPurple,
            ),
            _buildSwitchTile(
              title: "☁️ Firebase Logging",
              subtitle: "Enable or disable cloud logging.",
              value: isFirebaseEnabled,
              onChanged: (val) {
                setState(() => isFirebaseEnabled = val);
                _updatePreference('firebaseLogging', val);
              },
              icon: Icons.cloud_upload,
              color: Colors.blueAccent,
            ),

            _sectionHeader('Data Control'),
            _buildActionTile(
              title: '🧹 Clear Local Data',
              subtitle: 'Delete all locally stored sensor records.',
              icon: Icons.delete_forever,
              iconColor: Colors.red,
              onTap: _clearHiveData,
            ),

            _sectionHeader('About'),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFCBD5E1),
                  child: Icon(Icons.info_outline, color: Color(0xFF1E293B)),
                ),
                title: const Text('TaqaTap', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Version 1.0.0\nReal-time solar power monitoring & logging tool.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}