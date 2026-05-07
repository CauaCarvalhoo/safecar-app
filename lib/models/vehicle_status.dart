class AlertEvent {
  final String title;
  final String message;
  final DateTime time;
  final AlertSeverity severity;

  const AlertEvent({
    required this.title,
    required this.message,
    required this.time,
    required this.severity,
  });
}

enum AlertSeverity { info, warning, danger }

class VehicleStatus {
  final bool connected;
  final bool doorsLocked;
  final bool headlightsOn;
  final bool windowsClosed;
  final bool alarmActive;
  final bool vibrationDetected;
  final bool movementDetected;
  final double batteryVoltage;
  final String source;
  final DateTime updatedAt;

  const VehicleStatus({
    required this.connected,
    required this.doorsLocked,
    required this.headlightsOn,
    required this.windowsClosed,
    required this.alarmActive,
    required this.vibrationDetected,
    required this.movementDetected,
    required this.batteryVoltage,
    required this.source,
    required this.updatedAt,
  });

  factory VehicleStatus.initial() {
    return VehicleStatus(
      connected: false,
      doorsLocked: false,
      headlightsOn: false,
      windowsClosed: true,
      alarmActive: false,
      vibrationDetected: false,
      movementDetected: false,
      batteryVoltage: 12.4,
      source: 'Aguardando leitura',
      updatedAt: DateTime.now(),
    );
  }

  factory VehicleStatus.fromJson(Map<String, dynamic> json) {
    dynamic pick(List<String> keys) {
      for (final key in keys) {
        if (json.containsKey(key)) return json[key];
      }
      return null;
    }

    bool readBool(List<String> keys, bool fallback) {
      final value = pick(keys);
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.toLowerCase().trim();
        return normalized == 'true' || normalized == '1' || normalized == 'on';
      }
      return fallback;
    }

    double readDouble(List<String> keys, double fallback) {
      final value = pick(keys);
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? fallback;
      return fallback;
    }

    return VehicleStatus(
      connected: readBool(['connected', 'conectado'], true),
      doorsLocked: readBool(['doorsLocked', 'doors_locked', 'portasTrancadas'], false),
      headlightsOn: readBool(['headlightsOn', 'headlights_on', 'faroisAcesos'], false),
      windowsClosed: readBool(['windowsClosed', 'windows_closed', 'vidrosFechados'], true),
      alarmActive: readBool(['alarmActive', 'alarm_active', 'alarmeAtivo'], false),
      vibrationDetected: readBool(['vibrationDetected', 'vibration_detected', 'vibracaoDetectada'], false),
      movementDetected: readBool(['movementDetected', 'movement_detected', 'movimentoDetectado'], false),
      batteryVoltage: readDouble(['batteryVoltage', 'battery_voltage', 'tensaoBateria'], 12.4),
      source: pick(['source', 'fonte'])?.toString() ?? 'ESP32',
      updatedAt: DateTime.now(),
    );
  }

  VehicleStatus copyWith({
    bool? connected,
    bool? doorsLocked,
    bool? headlightsOn,
    bool? windowsClosed,
    bool? alarmActive,
    bool? vibrationDetected,
    bool? movementDetected,
    double? batteryVoltage,
    String? source,
    DateTime? updatedAt,
  }) {
    return VehicleStatus(
      connected: connected ?? this.connected,
      doorsLocked: doorsLocked ?? this.doorsLocked,
      headlightsOn: headlightsOn ?? this.headlightsOn,
      windowsClosed: windowsClosed ?? this.windowsClosed,
      alarmActive: alarmActive ?? this.alarmActive,
      vibrationDetected: vibrationDetected ?? this.vibrationDetected,
      movementDetected: movementDetected ?? this.movementDetected,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  List<AlertEvent> get activeAlerts {
    final now = DateTime.now();
    final alerts = <AlertEvent>[];

    if (vibrationDetected || movementDetected) {
      alerts.add(AlertEvent(
        title: 'Possível vandalismo detectado',
        message: 'O sistema identificou impacto ou movimento suspeito no veículo.',
        time: now,
        severity: AlertSeverity.danger,
      ));
    }

    if (headlightsOn) {
      alerts.add(AlertEvent(
        title: 'Faróis acesos',
        message: 'Os faróis continuam ligados e podem descarregar a bateria.',
        time: now,
        severity: AlertSeverity.warning,
      ));
    }

    if (!windowsClosed) {
      alerts.add(AlertEvent(
        title: 'Vidros abertos',
        message: 'Um ou mais vidros estão abertos. Verifique a segurança interna.',
        time: now,
        severity: AlertSeverity.warning,
      ));
    }

    if (batteryVoltage > 0 && batteryVoltage < 11.8) {
      alerts.add(AlertEvent(
        title: 'Bateria baixa',
        message: 'A tensão simulada da bateria está abaixo do ideal.',
        time: now,
        severity: AlertSeverity.warning,
      ));
    }

    return alerts;
  }
}
