import 'package:flutter/material.dart';
import '../models/live_data.dart';

class DataController extends ChangeNotifier {
  double voltage = 0.0;
  double current = 0.0;
  double power = 0.0;
  int pwm = 0;

  final List<Map<String, dynamic>> powerData = [];

  void update(LiveData data) {
    voltage = data.voltage;
    current = data.current;
    power = data.power;
    pwm = data.pwm;

    powerData.add({
      'timestamp': DateTime.now().toIso8601String(),
      'power': data.power,
    });

    if (powerData.length > 20) {
      powerData.removeAt(0);
    }

    notifyListeners();
  }
}

final sharedDataController = DataController();
