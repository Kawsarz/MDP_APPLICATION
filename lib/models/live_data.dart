class LiveData {
  final double voltage;
  final double current;
  final double power;
  final int pwm;

  LiveData({
    required this.voltage,
    required this.current,
    required this.power,
    required this.pwm,

  });

  factory LiveData.fromJson(Map<String, dynamic> json) {
    return LiveData(
      voltage: (json['voltage'] ?? 0.0).toDouble(),
      current: (json['current'] ?? 0.0).toDouble(),
      power: (json['power'] ?? 0.0).toDouble(),
      pwm: (json['pwm'] ?? 0).toInt(),
    );
  }
}
