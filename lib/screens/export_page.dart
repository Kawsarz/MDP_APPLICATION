import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';

class ExportPage extends StatelessWidget {
  const ExportPage({super.key});

  Future<void> exportCSV(BuildContext context) async {
    final box = Hive.box('powerData');

    if (box.isEmpty) {
      _showMessage(context, "⚠️ No data to export.");
      return;
    }

    List<List<dynamic>> rows = [
      ['Timestamp', 'Voltage (V)', 'Current (A)', 'Power (W)', 'PWM']
    ];

    for (var i = 0; i < box.length; i++) {
      final item = box.getAt(i);
      if (item is Map) {
        final timestamp = item['timestamp'] ?? '';
        final voltage = item['voltage'] is num ? item['voltage'].toStringAsFixed(2) : '';
        final current = item['current'] is num ? item['current'].toStringAsFixed(2) : '';
        final power = item['power'] is num ? item['power'].toStringAsFixed(2) : '';
        final pwm = item['pwm']?.toString() ?? '';
        rows.add([timestamp, voltage, current, power, pwm]);
      }
    }

    String csv = const ListToCsvConverter().convert(rows);

    final status = await Permission.storage.request();
    if (!status.isGranted) {
      _showMessage(context, "❌ Storage permission denied.");
      return;
    }

    final downloadsDir = Directory('/storage/emulated/0/Download');
    final file = File('${downloadsDir.path}/taqatap_data_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);

    _showMessage(context, "✅ File saved to Downloads.");
  }

  Future<void> shareCSV(BuildContext context) async {
    final box = Hive.box('powerData');

    if (box.isEmpty) {
      _showMessage(context, "⚠️ No data to share.");
      return;
    }

    List<List<dynamic>> rows = [
      ['Timestamp', 'Voltage (V)', 'Current (A)', 'Power (W)', 'PWM']
    ];

    for (var i = 0; i < box.length; i++) {
      final item = box.getAt(i);
      if (item is Map) {
        final timestamp = item['timestamp'] ?? '';
        final voltage = item['voltage'] is num ? item['voltage'].toStringAsFixed(2) : '';
        final current = item['current'] is num ? item['current'].toStringAsFixed(2) : '';
        final power = item['power'] is num ? item['power'].toStringAsFixed(2) : '';
        final pwm = item['pwm']?.toString() ?? '';
        rows.add([timestamp, voltage, current, power, pwm]);
      }
    }

    String csv = const ListToCsvConverter().convert(rows);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/taqatap_data.csv');
    await file.writeAsString(csv);

    Share.shareXFiles([XFile(file.path)], text: '📊 TaqaTap Full Dataset CSV');
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("📥 Export Data"),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionCard(
                icon: Icons.download_for_offline_rounded,
                title: "Download CSV",
                subtitle: "Save voltage, current, power, and PWM locally",
                color: Colors.green.shade400,
                onTap: () => exportCSV(context),
              ),
              const SizedBox(height: 24),
              _actionCard(
                icon: Icons.share_rounded,
                title: "Share CSV",
                subtitle: "Send the full dataset via any app",
                color: Colors.blue.shade400,
                onTap: () => shareCSV(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
