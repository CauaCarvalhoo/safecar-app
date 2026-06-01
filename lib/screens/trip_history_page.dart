import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/trip_firestore_service.dart';
import '../theme/app_theme.dart';

class TripHistoryPage extends StatefulWidget {
  const TripHistoryPage({super.key});

  @override
  State<TripHistoryPage> createState() => _TripHistoryPageState();
}

class _TripHistoryPageState extends State<TripHistoryPage> {
  final TripFirestoreService _tripService = TripFirestoreService();

  String? _vehicleId;
  String? _vehicleName;
  bool _routeArgumentsLoaded = false;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_routeArgumentsLoaded) {
      return;
    }

    _routeArgumentsLoaded = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map) {
      _vehicleId = args['vehicleId']?.toString();
      _vehicleName = args['vehicleName']?.toString();
    }
  }

  Future<void> _openLocationInMaps({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}',
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

  Future<void> _deleteTrip(String tripId) async {
    final user = _currentUser;

    if (user == null) {
      return;
    }

    try {
      await _tripService.deleteTrip(
        userId: user.uid,
        tripId: tripId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viagem removida do histórico.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível remover a viagem.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          _vehicleName == null || _vehicleName!.isEmpty
              ? 'Histórico de viagens'
              : 'Viagens - $_vehicleName',
        ),
      ),
      body: user == null
          ? const Center(
              child: Text('Usuário não autenticado.'),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _tripService.watchTrips(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Não foi possível carregar o histórico de viagens.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                final filteredDocs = _vehicleId == null || _vehicleId!.isEmpty
                    ? docs
                    : docs.where((doc) {
                        final data = doc.data();
                        return data['vehicleId']?.toString() == _vehicleId;
                      }).toList();

                if (filteredDocs.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      _buildEmptyCard(),
                    ],
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    _buildSummaryCard(filteredDocs.length),
                    const SizedBox(height: 16),
                    ...filteredDocs.map((doc) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildTripCard(
                          tripId: doc.id,
                          data: doc.data(),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSummaryCard(int count) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.route_outlined,
                color: AppTheme.primary,
                size: 34,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count == 1 ? '1 viagem registrada' : '$count viagens registradas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Resumo das viagens salvas no Firebase.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(
              Icons.route_outlined,
              color: AppTheme.primary,
              size: 58,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhuma viagem salva',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Finalize uma viagem na dashboard para que ela apareça neste histórico.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard({
    required String tripId,
    required Map<String, dynamic> data,
  }) {
    final vehicleName = data['vehicleName']?.toString() ?? 'Veículo';
    final startedAt = _timestampToDate(data['startedAt']);
    final endedAt = _timestampToDate(data['endedAt']);
    final durationSeconds = _toInt(data['durationSeconds']);
    final distanceKm = _toDouble(data['distanceKm']);
    final averageSpeed = _toDouble(data['averageSpeedKmh']);
    final maxSpeed = _toDouble(data['maxSpeedKmh']);
    final driverScore = _toInt(data['driverScore'], fallback: 100);
    final harshEvents = _toInt(data['harshEvents']);
    final overspeedEvents = _toInt(data['overspeedEvents']);
    final endLatitude = _toDouble(data['endLatitude']);
    final endLongitude = _toDouble(data['endLongitude']);

    final scoreColor = _scoreColor(driverScore);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scoreColor.withValues(alpha: 0.14),
                  foregroundColor: scoreColor,
                  child: Text(
                    driverScore.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vehicleName, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        _formatDateTime(startedAt),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Excluir viagem',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteTrip(tripId),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildTripLine(
              icon: Icons.timer_outlined,
              label: 'Duração',
              value: _formatDuration(Duration(seconds: durationSeconds)),
            ),
            _buildTripLine(
              icon: Icons.route_outlined,
              label: 'Distância',
              value: '${distanceKm.toStringAsFixed(2)} km',
            ),
            _buildTripLine(
              icon: Icons.speed,
              label: 'Velocidade média',
              value: '${averageSpeed.toStringAsFixed(1)} km/h',
            ),
            _buildTripLine(
              icon: Icons.trending_up,
              label: 'Velocidade máxima',
              value: '${maxSpeed.toStringAsFixed(1)} km/h',
            ),
            _buildTripLine(
              icon: Icons.warning_amber_rounded,
              label: 'Eventos',
              value: '$harshEvents bruscos • $overspeedEvents excesso',
            ),
            if (endedAt != null)
              _buildTripLine(
                icon: Icons.flag_outlined,
                label: 'Finalizada em',
                value: _formatDateTime(endedAt),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openLocationInMaps(
                  latitude: endLatitude,
                  longitude: endLongitude,
                ),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Abrir localização final'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripLine({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
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

  Color _scoreColor(int score) {
    if (score >= 85) {
      return AppTheme.success;
    }

    if (score >= 65) {
      return AppTheme.warning;
    }

    return AppTheme.danger;
  }

  DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) {
      return 'Data não informada';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}