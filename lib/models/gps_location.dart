class GpsLocation {
  final bool connected;
  final bool gpsValid;
  final double latitude;
  final double longitude;
  final double gpsSpeedKmh;
  final int satellites;
  final double altitudeMeters;
  final double courseDegrees;
  final String source;
  final DateTime updatedAt;

  const GpsLocation({
    required this.connected,
    required this.gpsValid,
    required this.latitude,
    required this.longitude,
    required this.gpsSpeedKmh,
    required this.satellites,
    required this.altitudeMeters,
    required this.courseDegrees,
    required this.source,
    required this.updatedAt,
  });

  factory GpsLocation.initial() {
    return GpsLocation(
      connected: false,
      gpsValid: false,
      latitude: -22.7371,
      longitude: -47.3331,
      gpsSpeedKmh: 0,
      satellites: 0,
      altitudeMeters: 0,
      courseDegrees: 0,
      source: 'Sem conexão GPS',
      updatedAt: DateTime.now(),
    );
  }

  factory GpsLocation.simulated({
    required double latitude,
    required double longitude,
    required double gpsSpeedKmh,
  }) {
    return GpsLocation(
      connected: true,
      gpsValid: true,
      latitude: latitude,
      longitude: longitude,
      gpsSpeedKmh: gpsSpeedKmh,
      satellites: 8,
      altitudeMeters: 545,
      courseDegrees: 0,
      source: 'ESP32 + NEO-6M simulado',
      updatedAt: DateTime.now(),
    );
  }

  factory GpsLocation.fromJson(Map<String, dynamic> json) {
    return GpsLocation(
      connected: json['connected'] == true,
      gpsValid: json['gpsValid'] == true,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      gpsSpeedKmh: _toDouble(json['gpsSpeedKmh']),
      satellites: _toInt(json['satellites']),
      altitudeMeters: _toDouble(json['altitudeMeters']),
      courseDegrees: _toDouble(json['courseDegrees']),
      source: json['source']?.toString() ?? 'GPS',
      updatedAt: _toDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'connected': connected,
      'gpsValid': gpsValid,
      'latitude': latitude,
      'longitude': longitude,
      'gpsSpeedKmh': gpsSpeedKmh,
      'satellites': satellites,
      'altitudeMeters': altitudeMeters,
      'courseDegrees': courseDegrees,
      'source': source,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  GpsLocation copyWith({
    bool? connected,
    bool? gpsValid,
    double? latitude,
    double? longitude,
    double? gpsSpeedKmh,
    int? satellites,
    double? altitudeMeters,
    double? courseDegrees,
    String? source,
    DateTime? updatedAt,
  }) {
    return GpsLocation(
      connected: connected ?? this.connected,
      gpsValid: gpsValid ?? this.gpsValid,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gpsSpeedKmh: gpsSpeedKmh ?? this.gpsSpeedKmh,
      satellites: satellites ?? this.satellites,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      courseDegrees: courseDegrees ?? this.courseDegrees,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedCoordinates {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

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