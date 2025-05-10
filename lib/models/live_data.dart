class LiveData {
  final double pvVoltage;
  final double pvCurrent;
  final double batteryVoltage;
  final double batteryCurrent;
  final double pvPower;
  final double scPower;
  final double dutyCycle;
  final String chargingStage;

  LiveData({
    required this.pvVoltage,
    required this.pvCurrent,
    required this.batteryVoltage,
    required this.batteryCurrent,
    required this.pvPower,
    required this.scPower,
    required this.dutyCycle,
    required this.chargingStage,
  });

  factory LiveData.fromJson(Map<String, dynamic> json) {
    return LiveData(
      pvVoltage: (json['pvVoltage'] ?? 0).toDouble(),
      pvCurrent: (json['pvCurrent'] ?? 0).toDouble(),
      batteryVoltage: (json['batteryVoltage'] ?? 0).toDouble(),
      batteryCurrent: (json['batteryCurrent'] ?? 0).toDouble(),
      pvPower: (json['pvPower'] ?? 0).toDouble(),
      scPower: (json['scPower'] ?? 0).toDouble(),
      dutyCycle: (json['dutyCycle'] ?? 0).toDouble(),
      chargingStage: (json['chargingStage'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'pvVoltage': pvVoltage,
    'pvCurrent': pvCurrent,
    'batteryVoltage': batteryVoltage,
    'batteryCurrent': batteryCurrent,
    'pvPower': pvPower,
    'scPower': scPower,
    'dutyCycle': dutyCycle,
    'chargingStage': chargingStage,
  };
}
