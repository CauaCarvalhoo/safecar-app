import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/gps_location.dart';

class GpsEsp32Service {
  String baseUrl;

  GpsEsp32Service({
    this.baseUrl = 'http://192.168.4.1',
  });

  Future<GpsLocation> fetchLocation() async {
    final uri = Uri.parse('$baseUrl/gps/status');

    final response = await http.get(uri).timeout(
          const Duration(seconds: 4),
        );

    if (response.statusCode != 200) {
      throw Exception('ESP32 GPS respondeu com erro ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Resposta inválida do ESP32 GPS.');
    }

    return GpsLocation.fromJson(decoded);
  }
}