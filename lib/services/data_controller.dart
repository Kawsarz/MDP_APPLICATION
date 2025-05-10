import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/live_data.dart';

class DataController extends ChangeNotifier {
  double voltage = 0.0;
  double current = 0.0;
  double power = 0.0;
  int pwm = 0;

  final List<Map<String, dynamic>> _powerData = [];

  List<Map<String, dynamic>> get powerData {
    debugPrint("👀 Returning \${_powerData.length} data points");
    return _powerData;
  }

  void appendInitialData(List<Map<String, dynamic>> data) {
    debugPrint("📅 Appending initial data: \${data.length} items");
    _powerData.addAll(data);
    notifyListeners();
  }

  void update(LiveData data) async {
    voltage = data.voltage;
    current = data.current;
    power = data.power;
    pwm = data.pwm;

    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'voltage': voltage,
      'current': current,
      'power': power,
      'pwm': pwm,
    };

    _powerData.add(entry);

    if (_powerData.length > 100) { //8yaret hydekaw
      _powerData.removeAt(0);
    }

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final isFirebaseEnabled = prefs.getBool('firebaseLogging') ?? true;

    if (isFirebaseEnabled) {
      FirebaseDatabase.instance.ref("logs").push().set(entry);
    } else {
      debugPrint("⛔ Firebase logging is OFF. Skipping cloud upload.");
    }
  }

  void clearData() {
    _powerData.clear();
    notifyListeners();
    debugPrint("🧹 Power data cleared");
  }
}

final sharedDataController = DataController();
