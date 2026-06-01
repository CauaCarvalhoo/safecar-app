import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/gps_location.dart';
import '../services/gps_esp32_service.dart';
import '../theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _TelemetryPoint {
  final DateTime time;
  final double speedKmh;
  final int rpm;

  const _TelemetryPoint({
    required this.time,
    required this.speedKmh,
    required this.rpm,
  });
}

class _HomePageState extends State<HomePage> {
  final Random _random = Random();
  final GpsEsp32Service _gpsService = GpsEsp32Service();

  Map<String, dynamic>? _vehicleData;

  Timer? _tripTimer;
  Timer? _gpsTimer;

  bool _loadingVehicle = false;
  bool _tripActive = false;

  bool _gpsLoading = false;
  bool _gpsEsp32Connected = false;
  bool _gpsValid = false;
  int _gpsSatellites = 0;
  String _gpsSource = 'GPS simulado';

  DateTime? _tripStartedAt;

  double _latitude = -22.7371;
  double _longitude = -47.3331;

  double _currentSpeedKmh = 0;
  double _averageSpeedKmh = 0;
  double _maxSpeedKmh = 0;
  double _distanceKm = 0;

  int _rpm = 0;
  int _engineTemp = 82;
  int _fuelPercent = 61;
  int _driverScore = 100;
  int _harshEvents = 0;
  int _overspeedEvents = 0;

  final List<_TelemetryPoint> _telemetryHistory = [];

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  String get _vehicleNickname {
    return _vehicleData?['nickname']?.toString() ?? 'Veículo não cadastrado';
  }

  String get _vehicleDetails {
    final brand = _vehicleData?['brand']?.toString() ?? '';
    final model = _vehicleData?['model']?.toString() ?? '';
    final year = _vehicleData?['year']?.toString() ?? '';
    final plate = _vehicleData?['plate']?.toString() ?? '';

    final parts = [
      if (brand.isNotEmpty || model.isNotEmpty) '$brand $model'.trim(),
      if (year.isNotEmpty) year,
      if (plate.isNotEmpty) 'Placa: $plate',
    ];

    if (parts.isEmpty) {
      return 'Toque para cadastrar modelo, placa e imagem.';
    }

    return parts.join(' • ');
  }

  String get _statusText {
    return _tripActive ? 'Viagem em andamento' : 'Veículo parado';
  }

  Duration get _tripDuration {
    final startedAt = _tripStartedAt;

    if (startedAt == null) {
      return Duration.zero;
    }

    return DateTime.now().difference(startedAt);
  }

  @override
  void initState() {
    super.initState();
    _loadVehicleDataFromFirestore();
    _addTelemetryPoint(speed: 0, rpm: 0);
  }

  @override
  void dispose() {
    _tripTimer?.cancel();
    _gpsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadVehicleDataFromFirestore() async {
    final user = _currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _loadingVehicle = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('vehicles')
          .doc('main')
          .get();

      if (!mounted) return;

      setState(() {
        _vehicleData = doc.exists ? doc.data() : null;
        _loadingVehicle = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingVehicle = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar os dados do veículo.'),
        ),
      );
    }
  }

  Future<void> _openVehicleProfile() async {
    await Navigator.pushNamed(context, '/vehicle_profile');

    if (!mounted) return;

    await _loadVehicleDataFromFirestore();
  }

  void _startTripSimulation() {
    _tripTimer?.cancel();

    setState(() {
      _tripActive = true;
      _tripStartedAt ??= DateTime.now();
    });

    _simulateObdTick();

    _tripTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _simulateObdTick(),
    );
  }

  void _pauseTripSimulation() {
    _tripTimer?.cancel();

    setState(() {
      _tripActive = false;
      _currentSpeedKmh = 0;
      _rpm = 0;
      _addTelemetryPoint(speed: 0, rpm: 0);
      _calculateTripStats();
    });
  }

  void _resetTripSimulation() {
    _tripTimer?.cancel();

    setState(() {
      _tripActive = false;
      _tripStartedAt = null;

      if (!_gpsEsp32Connected || !_gpsValid) {
        _latitude = -22.7371;
        _longitude = -47.3331;
      }

      _currentSpeedKmh = 0;
      _averageSpeedKmh = 0;
      _maxSpeedKmh = 0;
      _distanceKm = 0;

      _rpm = 0;
      _engineTemp = 82;
      _fuelPercent = 61;
      _driverScore = 100;
      _harshEvents = 0;
      _overspeedEvents = 0;

      _telemetryHistory.clear();
      _addTelemetryPoint(speed: 0, rpm: 0);
    });
  }

  void _simulateObdTick() {
    final previousSpeed = _currentSpeedKmh;

    final baseSpeed = 42 + _random.nextInt(36);
    final variation = _random.nextDouble() * 18 - 9;
    final nextSpeed = (baseSpeed + variation).clamp(8.0, 105.0).toDouble();

    final speedDifference = (nextSpeed - previousSpeed).abs();

    const intervalSeconds = 2;
    final distanceIncrement = nextSpeed * intervalSeconds / 3600;

    final latitudeIncrement = (_random.nextDouble() - 0.5) * 0.00018;
    final longitudeIncrement = distanceIncrement * 0.010;

    final simulatedRpm = (850 + nextSpeed * 32 + _random.nextInt(420)).round();
    final nextEngineTemp = (82 + _random.nextInt(13)).clamp(82, 98).toInt();
    final fuelLoss = _distanceKm > 0 && _distanceKm % 2 < 0.02 ? 1 : 0;

    setState(() {
      _currentSpeedKmh = nextSpeed;
      _rpm = simulatedRpm;
      _engineTemp = nextEngineTemp;
      _fuelPercent = max(0, _fuelPercent - fuelLoss);

      _distanceKm += distanceIncrement;

      if (!_gpsEsp32Connected || !_gpsValid) {
        _latitude += latitudeIncrement;
        _longitude += longitudeIncrement;
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

      _addTelemetryPoint(speed: nextSpeed, rpm: simulatedRpm);
      _calculateTripStats();
      _calculateDriverScore();
    });
  }

  void _addTelemetryPoint({
    required double speed,
    required int rpm,
  }) {
    _telemetryHistory.add(
      _TelemetryPoint(
        time: DateTime.now(),
        speedKmh: speed,
        rpm: rpm,
      ),
    );

    if (_telemetryHistory.length > 24) {
      _telemetryHistory.removeAt(0);
    }
  }

  void _calculateTripStats() {
    final movingSpeeds = _telemetryHistory
        .where((point) => point.speedKmh > 0)
        .map((point) => point.speedKmh)
        .toList();

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

    _driverScore = score.clamp(0, 100).toInt();
  }

  Future<void> _connectGpsEsp32() async {
    _gpsTimer?.cancel();

    setState(() {
      _gpsLoading = true;
    });

    await _refreshGpsEsp32(showSuccess: true);

    if (!_gpsEsp32Connected) {
      return;
    }

    _gpsTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshGpsEsp32(),
    );
  }

  Future<void> _refreshGpsEsp32({bool showSuccess = false}) async {
    try {
      final gps = await _gpsService.fetchLocation();

      if (!mounted) return;

      _applyGpsLocation(gps);

      if (showSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              gps.gpsValid
                  ? 'GPS conectado: ${gps.formattedCoordinates}'
                  : 'ESP32 conectado. Aguardando sinal GPS.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _gpsLoading = false;
        _gpsEsp32Connected = false;
        _gpsValid = false;
        _gpsSatellites = 0;
        _gpsSource = 'Sem conexão com ESP32 GPS';
      });

      if (showSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível conectar ao GPS do ESP32.'),
          ),
        );
      }
    }
  }

  void _applyGpsLocation(GpsLocation gps) {
    setState(() {
      _gpsLoading = false;
      _gpsEsp32Connected = gps.connected;
      _gpsValid = gps.gpsValid;
      _gpsSatellites = gps.satellites;
      _gpsSource = gps.source;

      if (gps.gpsValid) {
        _latitude = gps.latitude;
        _longitude = gps.longitude;
      }
    });
  }

  void _disconnectGpsEsp32() {
    _gpsTimer?.cancel();

    setState(() {
      _gpsLoading = false;
      _gpsEsp32Connected = false;
      _gpsValid = false;
      _gpsSatellites = 0;
      _gpsSource = 'GPS simulado';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GPS do ESP32 desconectado.'),
      ),
    );
  }

  Future<void> _openLocationInGoogleMaps() async {
    final latitude = _latitude.toStringAsFixed(6);
    final longitude = _longitude.toStringAsFixed(6);

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!mounted) return;

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir a localização no Google Maps.'),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login_choice',
      (route) => false,
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  Color _scoreColor() {
    if (_driverScore >= 85) {
      return AppTheme.success;
    }

    if (_driverScore >= 65) {
      return AppTheme.warning;
    }

    return AppTheme.danger;
  }

  String _scoreLabel() {
    if (_driverScore >= 85) {
      return 'Excelente';
    }

    if (_driverScore >= 65) {
      return 'Atenção';
    }

    return 'Risco';
  }

  String _mapStatusText() {
    if (_gpsLoading) {
      return 'Conectando';
    }

    if (_gpsEsp32Connected && _gpsValid) {
      return 'GPS real';
    }

    if (_gpsEsp32Connected && !_gpsValid) {
      return 'Sem fix';
    }

    if (_tripActive) {
      return 'Simulando';
    }

    return 'Aguardando';
  }

  IconData _mapStatusIcon() {
    if (_gpsEsp32Connected && _gpsValid) {
      return Icons.satellite_alt;
    }

    if (_gpsEsp32Connected && !_gpsValid) {
      return Icons.gps_not_fixed;
    }

    return _tripActive ? Icons.gps_fixed : Icons.gps_not_fixed;
  }

  Color _mapStatusColor() {
    if (_gpsEsp32Connected && _gpsValid) {
      return AppTheme.success;
    }

    if (_gpsEsp32Connected && !_gpsValid) {
      return AppTheme.warning;
    }

    return _tripActive ? AppTheme.success : Colors.black45;
  }

  String _locationDescription() {
    if (_gpsEsp32Connected && _gpsValid) {
      return 'Localização real recebida do ESP32 com GPS NEO-6M. Toque para abrir no Google Maps.';
    }

    if (_gpsEsp32Connected && !_gpsValid) {
      return 'ESP32 conectado. Aguardando fix do GPS NEO-6M.';
    }

    return 'Coordenadas simuladas até integração do ESP32 com GPS NEO-6M. Toque para abrir no Google Maps.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('SafeCar Fleet'),
        actions: [
          IconButton(
            tooltip: 'Atualizar veículo',
            icon: const Icon(Icons.refresh),
            onPressed: _loadVehicleDataFromFirestore,
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadVehicleDataFromFirestore,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _buildVehicleHeroCard(),
            const SizedBox(height: 16),
            _buildDriverScoreCard(),
            const SizedBox(height: 16),
            _buildMapCard(),
            const SizedBox(height: 16),
            _buildMetricGrid(),
            const SizedBox(height: 16),
            _buildTripControls(),
            const SizedBox(height: 16),
            _buildSpeedChart(),
            const SizedBox(height: 16),
            _buildFleetInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleHeroCard() {
    final imageBase64 = _vehicleData?['imageBase64']?.toString() ?? '';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _openVehicleProfile,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildVehicleImage(imageBase64),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_vehicleNickname, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          _loadingVehicle ? 'Carregando veículo...' : _vehicleDetails,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black45),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _tripActive
                      ? AppTheme.primary.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      _tripActive ? Icons.directions_car : Icons.local_parking,
                      color: _tripActive ? AppTheme.primary : Colors.black54,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusText,
                        style: TextStyle(
                          color: _tripActive ? AppTheme.primaryDark : Colors.black87,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(_tripDuration),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleImage(String imageBase64) {
    if (imageBase64.isEmpty) {
      return Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(
          Icons.directions_car_filled_rounded,
          color: AppTheme.primary,
          size: 44,
        ),
      );
    }

    try {
      final imageBytes = base64Decode(imageBase64);

      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.memory(
          imageBytes,
          width: 86,
          height: 86,
          fit: BoxFit.cover,
        ),
      );
    } catch (error) {
      return Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(
          Icons.broken_image_outlined,
          color: AppTheme.warning,
        ),
      );
    }
  }

  Widget _buildDriverScoreCard() {
    final scoreColor = _scoreColor();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scoreColor.withValues(alpha: 0.12),
                border: Border.all(
                  color: scoreColor,
                  width: 6,
                ),
              ),
              child: Center(
                child: Text(
                  '$_driverScore',
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Qualidade do motorista', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    _scoreLabel(),
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Eventos: $_harshEvents bruscos • $_overspeedEvents excesso de velocidade',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard() {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _openLocationInGoogleMaps,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Localização do veículo', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                _locationDescription(),
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 14),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: CustomPaint(
                          painter: _FleetMapPainter(),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 16,
                      top: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _mapStatusIcon(),
                              color: _mapStatusColor(),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _mapStatusText(),
                              style: const TextStyle(
                                color: AppTheme.primaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.map_outlined, color: Colors.black45, size: 22),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.28,
      children: [
        _buildMetricCard(
          icon: Icons.speed_rounded,
          title: 'Velocidade',
          value: '${_currentSpeedKmh.toStringAsFixed(1)} km/h',
        ),
        _buildMetricCard(
          icon: Icons.timeline_rounded,
          title: 'Média',
          value: '${_averageSpeedKmh.toStringAsFixed(1)} km/h',
        ),
        _buildMetricCard(
          icon: Icons.trending_up_rounded,
          title: 'Máxima',
          value: '${_maxSpeedKmh.toStringAsFixed(1)} km/h',
        ),
        _buildMetricCard(
          icon: Icons.route_outlined,
          title: 'KM rodados',
          value: '${_distanceKm.toStringAsFixed(2)} km',
        ),
        _buildMetricCard(
          icon: Icons.av_timer_rounded,
          title: 'RPM',
          value: _rpm == 0 ? '0 rpm' : '$_rpm rpm',
        ),
        _buildMetricCard(
          icon: Icons.thermostat_rounded,
          title: 'Motor',
          value: '$_engineTemp °C',
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AppTheme.primary),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.primaryDark,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Controle da viagem', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Modo simulado até a conexão real com ELM327 e GPS.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _tripActive ? _pauseTripSimulation : _startTripSimulation,
                icon: Icon(_tripActive ? Icons.pause : Icons.play_arrow),
                label: Text(_tripActive ? 'Pausar viagem' : 'Iniciar viagem simulada'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _resetTripSimulation,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Resetar telemetria'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _gpsLoading
                    ? null
                    : _gpsEsp32Connected
                        ? _disconnectGpsEsp32
                        : _connectGpsEsp32,
                icon: Icon(
                  _gpsEsp32Connected ? Icons.gps_off : Icons.gps_fixed,
                ),
                label: Text(
                  _gpsLoading
                      ? 'Conectando GPS...'
                      : _gpsEsp32Connected
                          ? 'Desconectar GPS ESP32'
                          : 'Conectar GPS ESP32',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedChart() {
    final spots = _telemetryHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.speedKmh);
    }).toList();

    final chartSpots = spots.isEmpty ? [const FlSpot(0, 0)] : spots;

    final maxSpeed = chartSpots.map((spot) => spot.y).reduce(max);
    final maxY = max(80.0, maxSpeed + 20);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gráfico de velocidade', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text(
              'Variação da velocidade coletada da telemetria OBD-II.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  minX: 0,
                  maxX: max(10, chartSpots.length - 1).toDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.black.withValues(alpha: 0.06),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 20,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 11,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartSpots,
                      isCurved: true,
                      barWidth: 4,
                      color: AppTheme.primary,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primary.withValues(alpha: 0.16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFleetInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Integrações da frota', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildInfoLine(
              icon: Icons.bluetooth,
              label: 'OBD-II',
              value: 'ELM327 simulado',
            ),
            _buildInfoLine(
              icon: Icons.memory,
              label: 'ESP32',
              value: 'Gateway GPS',
            ),
            _buildInfoLine(
              icon: Icons.gps_fixed,
              label: 'GPS',
              value: _gpsEsp32Connected
                  ? _gpsValid
                      ? 'NEO-6M ativo ($_gpsSatellites sat.)'
                      : 'Aguardando fix ($_gpsSatellites sat.)'
                  : 'Simulado até ESP32',
            ),
            _buildInfoLine(
              icon: Icons.satellite_alt,
              label: 'Fonte GPS',
              value: _gpsSource,
            ),
            _buildInfoLine(
              icon: Icons.local_gas_station,
              label: 'Combustível',
              value: '$_fuelPercent%',
            ),
            _buildInfoLine(
              icon: Icons.storage_outlined,
              label: 'Banco',
              value: 'Firebase conectado',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoLine({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FleetMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF244B44),
          Color(0xFF3A6A60),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final roadPaintThin = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.20),
      Offset(size.width * 0.88, size.height * 0.82),
      roadPaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.05, size.height * 0.72),
      Offset(size.width * 0.72, size.height * 0.18),
      roadPaintThin,
    );

    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.92),
      Offset(size.width * 0.95, size.height * 0.38),
      roadPaintThin,
    );

    canvas.drawLine(
      Offset(size.width * 0.00, size.height * 0.42),
      Offset(size.width * 0.42, size.height * 0.08),
      roadPaintThin,
    );

    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.50),
      18,
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );

    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.50),
      9,
      Paint()..color = Colors.white.withValues(alpha: 0.80),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}