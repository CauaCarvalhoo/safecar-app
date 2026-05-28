enum TripStatus {
  idle,
  running,
  paused,
  finished,
}

class TripSession {
  final String? id;
  final String? userId;
  final String? vehicleId;
  final String? driverId;

  final TripStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;

  final double distanceKm;
  final double currentSpeedKmh;
  final double averageSpeedKmh;
  final double maxSpeedKmh;

  final int driverScore;
  final int harshEvents;
  final int overspeedEvents;

  final double? startLatitude;
  final double? startLongitude;
  final double? lastLatitude;
  final double? lastLongitude;

  const TripSession({
    this.id,
    this.userId,
    this.vehicleId,
    this.driverId,
    required this.status,
    required this.startedAt,
    required this.endedAt,
    required this.distanceKm,
    required this.currentSpeedKmh,
    required this.averageSpeedKmh,
    required this.maxSpeedKmh,
    required this.driverScore,
    required this.harshEvents,
    required this.overspeedEvents,
    required this.startLatitude,
    required this.startLongitude,
    required this.lastLatitude,
    required this.lastLongitude,
  });

  factory TripSession.initial() {
    return const TripSession(
      status: TripStatus.idle,
      startedAt: null,
      endedAt: null,
      distanceKm: 0,
      currentSpeedKmh: 0,
      averageSpeedKmh: 0,
      maxSpeedKmh: 0,
      driverScore: 100,
      harshEvents: 0,
      overspeedEvents: 0,
      startLatitude: null,
      startLongitude: null,
      lastLatitude: null,
      lastLongitude: null,
    );
  }

  Duration get duration {
    final start = startedAt;

    if (start == null) {
      return Duration.zero;
    }

    final end = endedAt ?? DateTime.now();

    return end.difference(start);
  }

  bool get isRunning => status == TripStatus.running;

  String get scoreLabel {
    if (driverScore >= 85) {
      return 'Excelente';
    }

    if (driverScore >= 65) {
      return 'Atenção';
    }

    return 'Risco';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'vehicleId': vehicleId,
      'driverId': driverId,
      'status': status.name,
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'distanceKm': distanceKm,
      'currentSpeedKmh': currentSpeedKmh,
      'averageSpeedKmh': averageSpeedKmh,
      'maxSpeedKmh': maxSpeedKmh,
      'driverScore': driverScore,
      'harshEvents': harshEvents,
      'overspeedEvents': overspeedEvents,
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'lastLatitude': lastLatitude,
      'lastLongitude': lastLongitude,
    };
  }

  factory TripSession.fromMap(Map<String, dynamic> map) {
    return TripSession(
      id: map['id']?.toString(),
      userId: map['userId']?.toString(),
      vehicleId: map['vehicleId']?.toString(),
      driverId: map['driverId']?.toString(),
      status: _statusFromString(map['status']?.toString()),
      startedAt: _toDateTimeOrNull(map['startedAt']),
      endedAt: _toDateTimeOrNull(map['endedAt']),
      distanceKm: _toDouble(map['distanceKm']),
      currentSpeedKmh: _toDouble(map['currentSpeedKmh']),
      averageSpeedKmh: _toDouble(map['averageSpeedKmh']),
      maxSpeedKmh: _toDouble(map['maxSpeedKmh']),
      driverScore: _toInt(map['driverScore'], fallback: 100),
      harshEvents: _toInt(map['harshEvents']),
      overspeedEvents: _toInt(map['overspeedEvents']),
      startLatitude: _toDoubleOrNull(map['startLatitude']),
      startLongitude: _toDoubleOrNull(map['startLongitude']),
      lastLatitude: _toDoubleOrNull(map['lastLatitude']),
      lastLongitude: _toDoubleOrNull(map['lastLongitude']),
    );
  }

  TripSession copyWith({
    String? id,
    String? userId,
    String? vehicleId,
    String? driverId,
    TripStatus? status,
    DateTime? startedAt,
    DateTime? endedAt,
    double? distanceKm,
    double? currentSpeedKmh,
    double? averageSpeedKmh,
    double? maxSpeedKmh,
    int? driverScore,
    int? harshEvents,
    int? overspeedEvents,
    double? startLatitude,
    double? startLongitude,
    double? lastLatitude,
    double? lastLongitude,
  }) {
    return TripSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      distanceKm: distanceKm ?? this.distanceKm,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      averageSpeedKmh: averageSpeedKmh ?? this.averageSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      driverScore: driverScore ?? this.driverScore,
      harshEvents: harshEvents ?? this.harshEvents,
      overspeedEvents: overspeedEvents ?? this.overspeedEvents,
      startLatitude: startLatitude ?? this.startLatitude,
      startLongitude: startLongitude ?? this.startLongitude,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
    );
  }

  static TripStatus _statusFromString(String? value) {
    switch (value) {
      case 'running':
        return TripStatus.running;
      case 'paused':
        return TripStatus.paused;
      case 'finished':
        return TripStatus.finished;
      case 'idle':
      default:
        return TripStatus.idle;
    }
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static DateTime? _toDateTimeOrNull(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }
}