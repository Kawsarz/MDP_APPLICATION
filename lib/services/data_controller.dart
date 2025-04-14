import 'package:flutter/material.dart';
import '../models/live_data.dart';


class DataController extends ChangeNotifier {
  double voltage = 0.0;
  double current = 0.0;
  double power = 0.0;
  int pwm = 0;

  final List<Map<String, dynamic>> _powerData = [];

  List<Map<String, dynamic>> get powerData {
    debugPrint("👀 Returning ${_powerData.length} data points");
    return _powerData;
  }

  void appendInitialData(List<Map<String, dynamic>> data) {
    debugPrint("📥 Appending initial data: ${data.length} items");
    _powerData.addAll(data);
    notifyListeners();
  }

  void update(LiveData data) {
    voltage = data.voltage;
    current = data.current;
    power = data.power;
    pwm = data.pwm;

    _powerData.add({
      'timestamp': DateTime.now().toIso8601String(),
      'power': data.power,
    });

    if (_powerData.length > 20) {
      _powerData.removeAt(0);
    }

    notifyListeners();
  }
}

final sharedDataController = DataController();
