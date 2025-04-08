import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/data_controller.dart'; // 👈 Shared source

class ChartPage extends StatelessWidget {
  const ChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("📊 Power Chart", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: sharedDataController,
        builder: (_, __) {
          final data = sharedDataController.powerData;
          final spots = data.asMap().entries.map((e) {
            return FlSpot(e.key.toDouble(), (e.value['power'] ?? 0.0).toDouble());
          }).toList();

          final labels = data.map((e) => e['timestamp'].toString().substring(11, 16)).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: data.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: spots.length.toDouble(),
                  minY: 0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      color: Colors.teal,
                      belowBarData: BarAreaData(show: true, color: Colors.teal.withOpacity(0.2)),
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
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  gridData: FlGridData(show: true),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
