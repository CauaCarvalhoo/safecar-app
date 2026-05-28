import 'dart:math';

import '../models/gps_location.dart';
import '../models/obd_telemetry.dart';
import '../models/trip_session.dart';

class FleetTelemetrySnapshot {
  final ObdTelemetry obd;
  final GpsLocation gps;
  final TripSession trip;
  final List<double> speedHistory;
  final DateTime updatedAt;

  const FleetTelemetrySnapshot({
    required this.obd,
    required this.gps,
    required this.trip,
    required this.speedHistory,
    required this.updatedAt,
  });
}

class FleetSimulatorService {
  final Random _random = Random();

  bool _active = false;

  DateTime? _startedAt;

  double _latitude = -22.7371;
  double _longitude = -47.3331;

  double _currentSpeedKmh = 0;
  double _averageSpeedKmh = 0;
  double _maxSpeedKmh = 0;
  double _distanceKm = 0;

  int _rpm = 0;
  int _engineTempC = 82;
  int _fuelPercent = 61;
  int _throttlePositionPercent = 0;

  int _driverScore = 100;
  int _harshEvents = 0;
  int _overspeedEvents = 0;

  final List<double> _speedHistory = [];

  bool get isActive => _active;

  FleetTelemetrySnapshot start() {
    _active = true;
    _startedAt ??= DateTime.now();

    return tick();
  }

  FleetTelemetrySnapshot pause() {
    _active = false;
    _currentSpeedKmh = 0;
    _rpm = 0;
    _throttlePositionPercent = 0;
    _addSpeed(0);
    _calculateAverageSpeed();

    return snapshot();
  }

  FleetTelemetrySnapshot reset() {
    _active = false;
    _startedAt = null;

    _latitude = -22.7371;
    _longitude = -47.3331;

    _currentSpeedKmh = 0;
    _averageSpeedKmh = 0;
    _maxSpeedKmh = 0;
    _distanceKm = 0;

    _rpm = 0;
    _engineTempC = 82;
    _fuelPercent = 61;
    _throttlePositionPercent = 0;

    _driverScore = 100;
    _harshEvents = 0;
    _overspeedEvents = 0;

    _speedHistory
      ..clear()
      ..add(0);

    return snapshot();
  }

  FleetTelemetrySnapshot tick() {
    if (!_active) {
      return snapshot();
    }

    final previousSpeed = _currentSpeedKmh;

    final baseSpeed = 42 + _random.nextInt(36);
    final variation = _random.nextDouble() * 18 - 9;
    final nextSpeed = (baseSpeed + variation).clamp(8.0, 105.0).toDouble();

    final speedDifference = (nextSpeed - previousSpeed).abs();

    const intervalSeconds = 2;
    final distanceIncrement = nextSpeed * intervalSeconds / 3600;

    final latitudeIncrement = (_random.nextDouble() - 0.5) * 0.00018;
    final longitudeIncrement = distanceIncrement * 0.010;

    _currentSpeedKmh = nextSpeed;
    _distanceKm += distanceIncrement;
    _latitude += latitudeIncrement;
    _longitude += longitudeIncrement;

    _rpm = (850 + nextSpeed * 32 + _random.nextInt(420)).round();
    _engineTempC = (82 + _random.nextInt(13)).clamp(82, 98);
    _throttlePositionPercent = (18 + nextSpeed / 2 + _random.nextInt(12)).clamp(0, 100).round();

    if (_distanceKm > 0 && _distanceKm % 2 < 0.02 && _fuelPercent > 0) {
      _fuelPercent--;
    }

    if (nextSpeed > _maxSpeedKmh) {
      _maxSpeedKmh = nextSpeed;
    }

    if (nextSpeed > 80) {
      _overspeedEvents++;
    }

    if (speedDifference > 28) {
      _harshEvents++;
    }

    _addSpeed(nextSpeed);
    _calculateAverageSpeed();
    _calculateDriverScore();

    return snapshot();
  }

  FleetTelemetrySnapshot snapshot() {
    final obd = ObdTelemetry.simulated(
      speedKmh: _currentSpeedKmh,
      rpm: _rpm,
      engineTempC: _engineTempC,
      fuelPercent: _fuelPercent,
      throttlePositionPercent: _throttlePositionPercent,
    );

    final gps = GpsLocation.simulated(
      latitude: _latitude,
      longitude: _longitude,
      gpsSpeedKmh: _currentSpeedKmh,
    );

    final trip = TripSession(
      status: _active ? TripStatus.running : TripStatus.paused,
      startedAt: _startedAt,
      endedAt: null,
      distanceKm: _distanceKm,
      currentSpeedKmh: _currentSpeedKmh,
      averageSpeedKmh: _averageSpeedKmh,
      maxSpeedKmh: _maxSpeedKmh,
      driverScore: _driverScore,
      harshEvents: _harshEvents,
      overspeedEvents: _overspeedEvents,
      startLatitude: null,
      startLongitude: null,
      lastLatitude: _latitude,
      lastLongitude: _longitude,
    );

    return FleetTelemetrySnapshot(
      obd: obd,
      gps: gps,
      trip: trip,
      speedHistory: List.unmodifiable(_speedHistory),
      updatedAt: DateTime.now(),
    );
  }

  void _addSpeed(double speedKmh) {
    _speedHistory.add(speedKmh);

    if (_speedHistory.length > 24) {
      _speedHistory.removeAt(0);
    }
  }

  void _calculateAverageSpeed() {
    final movingSpeeds = _speedHistory.where((speed) => speed > 0).toList();

    if (movingSpeeds.isEmpty) {
      _averageSpeedKmh = 0;
      return;
    }

    final total = movingSpeeds.reduce((a, b) => a + b);
    _averageSpeedKmh = total / movingSpeeds.length;
  }

  void _calculateDriverScore() {
    final overspeedPenalty = _overspeedEvents * 3;
    final harshPenalty = _harshEvents * 6;
    final maxSpeedPenalty = _maxSpeedKmh > 100 ? 8 : 0;
    final rpmPenalty = _rpm > 4200 ? 4 : 0;

    final score = 100 - overspeedPenalty - harshPenalty - maxSpeedPenalty - rpmPenalty;

    _driverScore = score.clamp(0, 100);
  }
}