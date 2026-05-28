class ObdTelemetry {
  final bool connected;
  final double speedKmh;
  final int rpm;
  final int engineTempC;
  final int fuelPercent;
  final int throttlePositionPercent;
  final String source;
  final DateTime updatedAt;

  const ObdTelemetry({
    required this.connected,
    required this.speedKmh,
    required this.rpm,
    required this.engineTempC,
    required this.fuelPercent,
    required this.throttlePositionPercent,
    required this.source,
    required this.updatedAt,
  });

  factory ObdTelemetry.initial() {
    return ObdTelemetry(
      connected: false,
      speedKmh: 0,
      rpm: 0,
      engineTempC: 0,
      fuelPercent: 0,
      throttlePositionPercent: 0,
      source: 'Sem conexão OBD-II',
      updatedAt: DateTime.now(),
    );
  }

  factory ObdTelemetry.simulated({
    required double speedKmh,
    required int rpm,
    required int engineTempC,
    required int fuelPercent,
    required int throttlePositionPercent,
  }) {
    return ObdTelemetry(
      connected: true,
      speedKmh: speedKmh,
      rpm: rpm,
      engineTempC: engineTempC,
      fuelPercent: fuelPercent,
      throttlePositionPercent: throttlePositionPercent,
      source: 'ELM327 simulado',
      updatedAt: DateTime.now(),
    );
  }

  factory ObdTelemetry.fromJson(Map<String, dynamic> json) {
    return ObdTelemetry(
      connected: json['connected'] == true,
      speedKmh: _toDouble(json['speedKmh']),
      rpm: _toInt(json['rpm']),
      engineTempC: _toInt(json['engineTempC']),
      fuelPercent: _toInt(json['fuelPercent']),
      throttlePositionPercent: _toInt(json['throttlePositionPercent']),
      source: json['source']?.toString() ?? 'OBD-II',
      updatedAt: _toDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'connected': connected,
      'speedKmh': speedKmh,
      'rpm': rpm,
      'engineTempC': engineTempC,
      'fuelPercent': fuelPercent,
      'throttlePositionPercent': throttlePositionPercent,
      'source': source,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ObdTelemetry copyWith({
    bool? connected,
    double? speedKmh,
    int? rpm,
    int? engineTempC,
    int? fuelPercent,
    int? throttlePositionPercent,
    String? source,
    DateTime? updatedAt,
  }) {
    return ObdTelemetry(
      connected: connected ?? this.connected,
      speedKmh: speedKmh ?? this.speedKmh,
      rpm: rpm ?? this.rpm,
      engineTempC: engineTempC ?? this.engineTempC,
      fuelPercent: fuelPercent ?? this.fuelPercent,
      throttlePositionPercent: throttlePositionPercent ?? this.throttlePositionPercent,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isMoving => speedKmh > 0;
  bool get engineRunning => rpm > 0;

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}