import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _TrackingPoint {
  final DateTime time;
  final double speedKmh;

  const _TrackingPoint({
    required this.time,
    required this.speedKmh,
  });
}

class _HomePageState extends State<HomePage> {
  final Random _random = Random();

  Map<String, dynamic>? _vehicleData;

  Timer? _trackingTimer;

  bool _loadingVehicle = false;
  bool _trackingActive = false;

  double _latitude = -22.7371;
  double _longitude = -47.3331;
  double _currentSpeedKmh = 0;
  double _averageSpeedKmh = 0;
  double _distanceKm = 0;

  final List<_TrackingPoint> _speedHistory = [];

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
    return _trackingActive ? 'Em movimento' : 'Estacionado';
  }

  @override
  void initState() {
    super.initState();
    _loadVehicleDataFromFirestore();
    _addSpeedPoint(0);
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
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

  void _startTrackingSimulation() {
    _trackingTimer?.cancel();

    setState(() {
      _trackingActive = true;
    });

    _simulateTrackingTick();

    _trackingTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _simulateTrackingTick(),
    );
  }

  void _stopTrackingSimulation() {
    _trackingTimer?.cancel();

    setState(() {
      _trackingActive = false;
      _currentSpeedKmh = 0;
      _addSpeedPoint(0);
      _calculateAverageSpeed();
    });
  }

  void _resetTrackingSimulation() {
    _trackingTimer?.cancel();

    setState(() {
      _trackingActive = false;
      _latitude = -22.7371;
      _longitude = -47.3331;
      _currentSpeedKmh = 0;
      _averageSpeedKmh = 0;
      _distanceKm = 0;
      _speedHistory.clear();
      _addSpeedPoint(0);
    });
  }

  void _simulateTrackingTick() {
    final variation = _random.nextDouble() * 16 - 8;
    final nextSpeed = (38 + variation + _random.nextInt(34)).clamp(8.0, 92.0);

    const intervalSeconds = 2;
    final distanceIncrement = nextSpeed * intervalSeconds / 3600;

    final latitudeIncrement = (_random.nextDouble() - 0.5) * 0.00018;
    final longitudeIncrement = distanceIncrement * 0.010;

    setState(() {
      _currentSpeedKmh = nextSpeed;
      _distanceKm += distanceIncrement;
      _latitude += latitudeIncrement;
      _longitude += longitudeIncrement;
      _addSpeedPoint(nextSpeed);
      _calculateAverageSpeed();
    });
  }

  void _addSpeedPoint(double speed) {
    _speedHistory.add(
      _TrackingPoint(
        time: DateTime.now(),
        speedKmh: speed,
      ),
    );

    if (_speedHistory.length > 20) {
      _speedHistory.removeAt(0);
    }
  }

  void _calculateAverageSpeed() {
    final movingSpeeds = _speedHistory
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

  Future<void> _copyLocation() async {
    final locationText =
        '${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}';

    await Clipboard.setData(
      ClipboardData(text: locationText),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Localização copiada: $locationText'),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('SafeCar Tracker'),
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
            _buildMapCard(),
            const SizedBox(height: 16),
            _buildMetricGrid(),
            const SizedBox(height: 16),
            _buildTrackingControls(),
            const SizedBox(height: 16),
            _buildSpeedChart(),
            const SizedBox(height: 16),
            _buildTrackerInfoCard(),
            const SizedBox(height: 16),
            _buildVehicleSettingsCard(),
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
                  color: _trackingActive
                      ? AppTheme.primary.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      _trackingActive ? Icons.directions_car : Icons.local_parking,
                      color: _trackingActive ? AppTheme.primary : Colors.black54,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _statusText,
                      style: TextStyle(
                        color: _trackingActive ? AppTheme.primaryDark : Colors.black87,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
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

  Widget _buildMapCard() {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _copyLocation,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Localização', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              const Text(
                'Simulação de posição do veículo até a integração com GPS.',
                style: TextStyle(color: Colors.black54),
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
                          painter: _MockMapPainter(),
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
                          Icons.directions_car_filled_rounded,
                          color: Colors.white,
                          size: 32,
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
                              _trackingActive ? Icons.gps_fixed : Icons.gps_not_fixed,
                              color: _trackingActive ? AppTheme.success : Colors.black45,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _trackingActive ? 'Rastreando' : 'Parado',
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
                  const Icon(Icons.copy, color: Colors.black45, size: 20),
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
      childAspectRatio: 1.35,
      children: [
        _buildMetricCard(
          icon: Icons.speed_rounded,
          title: 'Velocidade atual',
          value: '${_currentSpeedKmh.toStringAsFixed(1)} km/h',
        ),
        _buildMetricCard(
          icon: Icons.timeline_rounded,
          title: 'Velocidade média',
          value: '${_averageSpeedKmh.toStringAsFixed(1)} km/h',
        ),
        _buildMetricCard(
          icon: Icons.route_outlined,
          title: 'Distância',
          value: '${_distanceKm.toStringAsFixed(2)} km',
        ),
        _buildMetricCard(
          icon: Icons.timer_outlined,
          title: 'Atualização',
          value: DateTime.now().toString().substring(11, 19),
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
        padding: const EdgeInsets.all(16),
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
                    fontSize: 20,
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

  Widget _buildTrackingControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Controle do rastreamento', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _trackingActive ? _stopTrackingSimulation : _startTrackingSimulation,
                icon: Icon(_trackingActive ? Icons.pause : Icons.play_arrow),
                label: Text(_trackingActive ? 'Parar simulação' : 'Iniciar simulação'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _resetTrackingSimulation,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Resetar dados'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedChart() {
    final spots = _speedHistory.asMap().entries.map((entry) {
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
              'Variação da velocidade durante o rastreamento simulado.',
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

  Widget _buildTrackerInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rastreador', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildInfoLine(
              icon: Icons.memory,
              label: 'Dispositivo',
              value: 'ESP32 preparado',
            ),
            _buildInfoLine(
              icon: Icons.gps_fixed,
              label: 'GPS',
              value: 'Simulado até módulo físico',
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
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSettingsCard() {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _openVehicleProfile,
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(Icons.directions_car_filled_rounded, color: AppTheme.primary),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalhes do veículo',
                      style: TextStyle(
                        color: AppTheme.primaryDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Apelido, placa, modelo e imagem',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockMapPainter extends CustomPainter {
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