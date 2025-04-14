import 'package:flutter/material.dart';
import '../services/tcp_service.dart';
import '../models/live_data.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hive/hive.dart';
import '../services/data_controller.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final TcpService tcpService = TcpService(ipAddress: '192.168.4.1', port: 12345);
  String status = "🔌 Connecting...";
  String city = "Unknown";
  String temperature = "--";
  String weatherIcon = "☁️";

  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _initWeather();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      tcpService.connect(onDataReceived, onStatusChanged);
    });
  }

  Future<void> _initWeather() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      final lat = position.latitude;
      final lon = position.longitude;
      final apiKey = 'ebda90e3025bed773b4ee1ab28240bd7';

      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          city = data['name'];
          temperature = "${data['main']['temp'].round()}°C";
          final icon = data['weather'][0]['icon'];
          weatherIcon = _mapWeatherIcon(icon);
        });
      } else {
        setState(() {
          city = 'Unavailable';
          temperature = '--';
          weatherIcon = '❌';
        });
      }
    } catch (e) {
      setState(() {
        city = 'Unavailable';
        temperature = '--';
        weatherIcon = '❌';
      });
    }
  }

  String _mapWeatherIcon(String code) {
    switch (code) {
      case "01d": return "☀️";
      case "01n": return "🌙";
      case "02d":
      case "02n": return "🌤️";
      case "03d":
      case "03n": return "☁️";
      case "09d":
      case "09n": return "🌧️";
      case "10d":
      case "10n": return "🌦️";
      case "11d":
      case "11n": return "⛈️";
      default: return "☁️";
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFFDFDFD),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: sharedDataController,
          builder: (_, __) => SlideTransition(
            position: _offsetAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 90),
              child: Column(
                children: [
                  _buildHeader(isDark),
                  const SizedBox(height: 20),
                  _buildPowerCircle(isDark),
                  const SizedBox(height: 24),
                  _buildInfoCard(Icons.bolt, "Voltage", "${sharedDataController.voltage} V", isDark),
                  _buildInfoCard(Icons.flash_on, "Current", "${sharedDataController.current} A", isDark),
                  _buildInfoCard(Icons.tune, "PWM", "${sharedDataController.pwm}", isDark),
                  const SizedBox(height: 16),
                  _buildRefreshButton(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final date = DateFormat('EEEE, MMM d').format(DateTime.now());
    return Stack(
      children: [
        ClipPath(
          clipper: WaveClipper(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : const Color(0xFFFFFDF5),
              image: isDark
                  ? null
                  : const DecorationImage(
                image: AssetImage('assets/backgroun.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  "Good ${DateTime.now().hour < 12 ? "morning" : "afternoon"}",
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, color: Colors.blue.shade300, size: 18),
                    const SizedBox(width: 4),
                    Text(city, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black)),
                    const SizedBox(width: 6),
                    Text(weatherIcon, style: const TextStyle(fontSize: 16)),
                    Text("  $temperature", style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(date, style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        Positioned(top: 8, right: 20, child: _buildTcpNotificationIcon()),
      ],
    );
  }
  Widget _buildPowerCircle(bool isDark) {
    double power = sharedDataController.power.toDouble().clamp(0, 100);
    return Stack(
      alignment: Alignment.center,
      children: [
        CircularPercentIndicator(
          radius: 120.0,
          lineWidth: 16.0,
          percent: power / 100,
          circularStrokeCap: CircularStrokeCap.round,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Battery", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 19)),
              const SizedBox(height: 8),
              Text("${power.toStringAsFixed(0)}%",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            ],
          ),
          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          progressColor: Colors.orange,
        ),
        Positioned(
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.grey.shade900 : Colors.white,
            ),
            child: const Icon(Icons.flash_on, color: Colors.orange, size: 24),
          ),
        )
      ],
    );
  }
  Widget _buildInfoCard(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardColor : Colors.white,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: isDark ? Colors.white : Colors.black, size: 28),
                const SizedBox(width: 12),
                Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
              ],
            ),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          ],
        ),
      ),
    );
  }
  Widget _buildRefreshButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? Colors.orange : Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 6,
          ),
          onPressed: () {
            tcpService.connect(onDataReceived, onStatusChanged);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Reconnecting...")),
            );
          },
          icon: const Icon(Icons.refresh, color: Colors.white),
          label: const Text(
            "Refresh Connection",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildTcpNotificationIcon() {
    Color dotColor = Colors.orange;
    if (status.contains("✅")) dotColor = Colors.green;
    if (status.contains("❌")) dotColor = Colors.red;
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("TCP Status"),
            content: Text(status),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
          ),
        );
      },
      child: Stack(
        children: [
          const Icon(Icons.notifications_none, size: 28, color: Colors.black87),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
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
