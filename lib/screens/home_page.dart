import 'package:flutter/material.dart';
import '../services/tcp_service.dart';
import '../models/live_data.dart';
import '../widgets/data_tile.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hive/hive.dart';
import '../services/data_controller.dart'; // ✅ Shared state

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TcpService tcpService = TcpService(ipAddress: '192.168.4.1', port: 12345);
  String status = "🔌 Connecting...";

  @override
  void initState() {
    super.initState();
    tcpService.connect(onDataReceived, onStatusChanged);
  }

  void onDataReceived(LiveData data) {
    final box = Hive.box('powerData');
    if (box.length >= 20) box.deleteAt(0);

    final record = {
      'timestamp': DateTime.now().toIso8601String(),
      'voltage': data.voltage,
      'current': data.current,
      'power': data.power,
      'pwm': data.pwm,
    };

    box.add(record);
    sharedDataController.update(data);

    FirebaseDatabase.instance.ref('logs').push().set(record);
  }


  void onStatusChanged(String newStatus) {
    setState(() => status = newStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("TaqaTap ☀️"),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: sharedDataController,
        builder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildConnectionStatus(),
            const SizedBox(height: 12),
            Expanded(child: _buildDataGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    Color iconColor = status.contains("✅")
        ? Colors.green
        : status.contains("❌")
        ? Colors.red
        : const Color(0xFF0EA5E9);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.wifi, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 18,
      mainAxisSpacing: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      childAspectRatio: 1.1,
      children: [
        DataTile(label: "🔋 Voltage", value: "${sharedDataController.voltage} V"),
        DataTile(label: "⚡ Current", value: "${sharedDataController.current} A"),
        DataTile(label: "💡 Power", value: "${sharedDataController.power} W"),
        DataTile(label: "🎛️ PWM", value: "${sharedDataController.pwm}"),
      ],
    );
  }
}
