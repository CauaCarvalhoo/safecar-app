import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/vehicle_status.dart';

class SafeCarService {
  bool simulationMode = true;
  String esp32BaseUrl = 'http://192.168.4.1';

  VehicleStatus _mockStatus = VehicleStatus.initial().copyWith(
    connected: true,
    doorsLocked: true,
    alarmActive: true,
    source: 'Simulação local',
  );

  int _simulationTick = 0;

  Future<VehicleStatus> fetchStatus() async {
    if (simulationMode) {
      return _fetchMockStatus();
    }

    final uri = Uri.parse('$esp32BaseUrl/status');
    final response = await http.get(uri).timeout(const Duration(seconds: 4));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('ESP32 respondeu com erro ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return VehicleStatus.fromJson(data).copyWith(
      connected: true,
      source: 'ESP32 conectado',
      updatedAt: DateTime.now(),
    );
  }

  Future<VehicleStatus> sendCommand(String command) async {
    if (simulationMode) {
      return _sendMockCommand(command);
    }

    final uri = Uri.parse('$esp32BaseUrl/command').replace(
      queryParameters: {'name': command},
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 4));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Falha ao enviar comando para o ESP32');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return VehicleStatus.fromJson(data).copyWith(
      connected: true,
      source: 'ESP32 conectado',
      updatedAt: DateTime.now(),
    );
  }

  Future<VehicleStatus> _fetchMockStatus() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _simulationTick++;

    // A cada algumas leituras, o simulador cria um evento para a tela não ficar parada.
    if (_simulationTick % 12 == 0) {
      _mockStatus = _mockStatus.copyWith(movementDetected: true, vibrationDetected: true);
    } else if (_simulationTick % 13 == 0) {
      _mockStatus = _mockStatus.copyWith(movementDetected: false, vibrationDetected: false);
    }

    return _mockStatus.copyWith(
      connected: true,
      source: 'Simulação local',
      updatedAt: DateTime.now(),
    );
  }

  Future<VehicleStatus> _sendMockCommand(String command) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    switch (command) {
      case 'lock_doors':
        _mockStatus = _mockStatus.copyWith(doorsLocked: true);
        break;
      case 'unlock_doors':
        _mockStatus = _mockStatus.copyWith(doorsLocked: false);
        break;
      case 'toggle_alarm':
        _mockStatus = _mockStatus.copyWith(alarmActive: !_mockStatus.alarmActive);
        break;
      case 'turn_off_lights':
        _mockStatus = _mockStatus.copyWith(headlightsOn: false);
        break;
      case 'toggle_lights':
        _mockStatus = _mockStatus.copyWith(headlightsOn: !_mockStatus.headlightsOn);
        break;
      case 'close_windows':
        _mockStatus = _mockStatus.copyWith(windowsClosed: true);
        break;
      case 'toggle_windows':
        _mockStatus = _mockStatus.copyWith(windowsClosed: !_mockStatus.windowsClosed);
        break;
      case 'simulate_impact':
        _mockStatus = _mockStatus.copyWith(vibrationDetected: true, movementDetected: true);
        break;
      case 'clear_events':
        _mockStatus = _mockStatus.copyWith(vibrationDetected: false, movementDetected: false);
        break;
    }

    return _mockStatus.copyWith(
      connected: true,
      source: 'Simulação local',
      updatedAt: DateTime.now(),
    );
  }
}
