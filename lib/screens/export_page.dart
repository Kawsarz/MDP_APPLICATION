import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  String lastExported = "-";
  bool isFirebaseEnabled = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    _loadFirebasePref();
  }

  Future<void> _loadFirebasePref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isFirebaseEnabled = prefs.getBool('firebaseLogging') ?? true;
    });
  }

  Future<bool> _requestStoragePermission() async {
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }
    return status.isGranted;
  }

  Future<List<List<dynamic>>> _getExportData() async {
    final box = Hive.box('powerData');
    List<List<dynamic>> rows = [
      ['Timestamp', 'Voltage (V)', 'Current (A)', 'Power (W)', 'PWM']
    ];

    if (box.isNotEmpty) {
      for (var i = 0; i < box.length; i++) {
        final item = box.getAt(i);
        if (item is Map) {
          rows.add([
            item['timestamp'] ?? '',
            item['voltage']?.toStringAsFixed(2) ?? '',
            item['current']?.toStringAsFixed(2) ?? '',
            item['power']?.toStringAsFixed(2) ?? '',
            item['pwm']?.toString() ?? '',
          ]);
        }
      }
    } else if (isFirebaseEnabled) {
      final snapshot = await FirebaseDatabase.instance.ref('logs').get();
      final data = snapshot.value;
      if (data is Map) {
        data.forEach((key, item) {
          if (item is Map) {
            rows.add([
              item['timestamp'] ?? '',
              item['voltage']?.toString() ?? '',
              item['current']?.toString() ?? '',
              item['power']?.toString() ?? '',
              item['pwm']?.toString() ?? '',
            ]);
          }
        });
      }
    }
    return rows;
  }

  Future<void> exportCSV(BuildContext context) async {
    if (!await _requestStoragePermission()) {
      _showMessage(context, "❌ Storage permission denied");
      return;
    }

    final rows = await _getExportData();
    if (rows.length == 1) return _showMessage(context, "⚠️ No data available to export.");

    final csv = const ListToCsvConverter().convert(rows);
    final downloadsDir = Directory('/storage/emulated/0/Download');
    final file = File('${downloadsDir.path}/taqatap_data_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);

    setState(() => lastExported = DateFormat('MMM d, yyyy – hh:mm a').format(DateTime.now()));
    _showMessage(context, "File saved to Downloads folder.");
  }

  Future<void> shareCSV(BuildContext context) async {
    final rows = await _getExportData();
    if (rows.length == 1) return _showMessage(context, "⚠️ No data available to share.");

    final csv = const ListToCsvConverter().convert(rows);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/taqatap_data.csv');
    await file.writeAsString(csv);

    Share.shareXFiles([XFile(file.path)], text: '📊 TaqaTap Full Dataset CSV');
  }

  void _showMessage(BuildContext context, String msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 80,
        left: MediaQuery.of(context).size.width * 0.1,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? Colors.orange.shade800 : Colors.black87,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    msg,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Export Data", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/backgroun.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // ✅ TOP WAVE
            ClipPath(
              clipper: WaveClipperTop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 120, bottom: 40),
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                child: const Center(
                  child: Icon(Icons.cloud_upload_outlined, size: 36, color: Colors.orange),
                ),
              ),
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _roundedActionCard(
                        icon: Icons.download_rounded,
                        title: "Download",
                        color: isDark ? Colors.orange : Colors.black,
                        onTap: () => exportCSV(context),
                      ),
                      const SizedBox(height: 24),
                      _roundedActionCard(
                        icon: Icons.share_rounded,
                        title: "Share",
                        color: isDark ? Colors.orange : Colors.black,
                        onTap: () => shareCSV(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ✅ BOTTOM WAVE
            ClipPath(
              clipper: WaveClipperInverseMedium(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 20, bottom: 30),
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                child: Column(
                  children: [
                    const Icon(Icons.folder_open, size: 24, color: Colors.orange),
                    const SizedBox(height: 4),
                    Text("Last Exported: $lastExported",
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
                    const SizedBox(height: 4),
                    Text("Tip: You can find your files in Downloads",
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? Colors.white60 : Colors.black45)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundedActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 60,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
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

class WaveClipperInverseMedium extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 25);
    path.quadraticBezierTo(size.width / 2, -25, size.width, 25);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
