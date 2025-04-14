import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';

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

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  final List<Map<String, dynamic>> _data = [];
  late Box powerBox;
  StreamSubscription? _subscription;

  String selectedMetric = 'power';
  final List<String> metrics = ['power', 'voltage', 'current', 'pwm'];
  final Map<String, IconData> metricIcons = {
    'power': Icons.flash_on,
    'voltage': Icons.electrical_services,
    'current': Icons.battery_charging_full,
    'pwm': Icons.speed,
  };

  @override
  void initState() {
    super.initState();
    powerBox = Hive.box('powerData');
    _loadInitial();
    _subscribeToHive();
  }

  void _loadInitial() {
    final start = powerBox.length > 20 ? powerBox.length - 20 : 0;
    for (int i = start; i < powerBox.length; i++) {
      final entry = powerBox.getAt(i);
      if (entry is Map) _data.add(Map<String, dynamic>.from(entry));
    }
  }

  void _subscribeToHive() {
    _subscription = powerBox.watch().listen((event) {
      if (!mounted) return;
      final entry = event.value;
      if (entry is! Map) return;

      setState(() {
        _data.add(Map<String, dynamic>.from(entry));
        if (_data.length > 20) _data.removeAt(0);
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spots = _data.asMap().entries.map((e) {
      final y = (e.value[selectedMetric] ?? 0.0).toDouble();
      return FlSpot(e.key.toDouble(), y);
    }).toList();

    final labels = _data.map((e) => e['timestamp'].toString().substring(11, 16)).toList();

    return Scaffold(
      body: Column(
        children: [
          // Top wave with background image and title
          ClipPath(
            clipper: WaveClipperTop(),
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/backgroun.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Charts',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Real-time sensor monitoring',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black45,
                    ),
                  ),
                  SizedBox(height: 10),
                  Icon(Icons.show_chart, size: 40, color: Colors.orange),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Orange bar with icons
          Container(
            decoration: BoxDecoration(
              color: Colors.amber[600],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: metrics.map((metric) {
                final isSelected = selectedMetric == metric;
                return GestureDetector(
                  onTap: () => setState(() => selectedMetric = metric),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        metricIcons[metric],
                        size: 20,
                        color: isSelected ? Colors.black : Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metric.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Chart Area
          Center(
            child: Container(
              height: 420,
              width: MediaQuery.of(context).size.width * 0.92,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.amber[50],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: spots.isEmpty
                  ? const Center(child: Text("🚫 No data available"))
                  : LineChart(
                LineChartData(
                  minX: 0,
                  maxX: spots.length.toDouble(),
                  minY: 0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 2.5,
                      color: Colors.orangeAccent,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orangeAccent.withOpacity(0.2),
                      ),
                      dotData: FlDotData(show: false),
                    )
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, _) {
                          int i = value.toInt();
                          return i >= 0 && i < labels.length
                              ? Text(labels[i], style: const TextStyle(fontSize: 9))
                              : const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                  ),
                  gridData: FlGridData(show: true),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
