import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/vehicle_status.dart';
import '../services/safecar_service.dart';
import '../theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SafeCarService _service = SafeCarService();
  final TextEditingController _ipController = TextEditingController(text: '192.168.4.1');

  VehicleStatus _status = VehicleStatus.initial();
  final List<AlertEvent> _history = [];
  Timer? _timer;
  bool _loading = false;
  bool _loadingHistory = false;
  String? _errorMessage;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadAlertHistoryFromFirestore();
    _refreshStatus();
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshStatus(silent: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus({bool silent = false}) async {
    if (!mounted) return;

    if (!silent) {
      setState(() => _loading = true);
    }

    try {
      final status = await _service.fetchStatus();

      if (!mounted) return;

      setState(() {
        _status = status;
        _errorMessage = null;
        _loading = false;
        _registerAlerts(status.activeAlerts);
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _status = _status.copyWith(
          connected: false,
          source: 'Sem conexão com ESP32',
          updatedAt: DateTime.now(),
        );
        _errorMessage = 'Não foi possível falar com o ESP32. Confira o Wi-Fi e o IP.';
        _loading = false;
      });
    }
  }

  Future<void> _sendCommand(String command, String successMessage) async {
    setState(() => _loading = true);

    try {
      final status = await _service.sendCommand(command);

      if (!mounted) return;

      setState(() {
        _status = status;
        _errorMessage = null;
        _loading = false;
        _registerAlerts(status.activeAlerts);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Comando não enviado. Confira se o ESP32 está ligado e conectado.';
        _loading = false;
      });
    }
  }

  void _registerAlerts(List<AlertEvent> alerts) {
    final now = DateTime.now();
    final newAlerts = <AlertEvent>[];

    for (final alert in alerts) {
      final alreadyInserted = _history.any(
        (item) =>
            item.title == alert.title &&
            item.message == alert.message &&
            now.difference(item.time).inSeconds < 30,
      );

      if (!alreadyInserted) {
        _history.insert(0, alert);
        newAlerts.add(alert);
      }
    }

    if (_history.length > 20) {
      _history.removeRange(20, _history.length);
    }

    for (final alert in newAlerts) {
      unawaited(_saveAlertToFirestore(alert));
    }
  }

  Future<void> _loadAlertHistoryFromFirestore() async {
    final user = _currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _loadingHistory = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('alerts')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final alerts = snapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['createdAt'];

        DateTime alertTime = DateTime.now();

        if (timestamp is Timestamp) {
          alertTime = timestamp.toDate();
        }

        return AlertEvent(
          title: data['title']?.toString() ?? 'Alerta SafeCar',
          message: data['message']?.toString() ?? 'Evento registrado no sistema.',
          time: alertTime,
          severity: _severityFromString(data['severity']?.toString() ?? 'warning'),
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        _history
          ..clear()
          ..addAll(alerts);
        _loadingHistory = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingHistory = false;
        _errorMessage = 'Não foi possível carregar o histórico do Firebase.';
      });
    }
  }

  Future<void> _saveAlertToFirestore(AlertEvent alert) async {
    final user = _currentUser;

    if (user == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('alerts').add({
        'title': alert.title,
        'message': alert.message,
        'severity': _severityToString(alert.severity),
        'source': _status.source,
        'createdAt': Timestamp.fromDate(alert.time),
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Alerta exibido localmente, mas não foi salvo no Firebase.';
      });
    }
  }

  Future<void> _clearHistory() async {
    final user = _currentUser;

    setState(() {
      _history.clear();
    });

    if (user == null) {
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('alerts')
          .limit(50)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Histórico de alertas limpo.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Histórico local limpo, mas houve falha ao limpar o Firebase.')),
      );
    }
  }

  AlertSeverity _severityFromString(String severity) {
    switch (severity) {
      case 'danger':
        return AlertSeverity.danger;
      case 'info':
        return AlertSeverity.info;
      case 'warning':
      default:
        return AlertSeverity.warning;
    }
  }

  String _severityToString(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.danger:
        return 'danger';
      case AlertSeverity.info:
        return 'info';
      case AlertSeverity.warning:
        return 'warning';
    }
  }

  void _applyEsp32Config() {
    final ip = _ipController.text.trim();

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o IP do ESP32.')),
      );
      return;
    }

    _service.esp32BaseUrl = ip.startsWith('http') ? ip : 'http://$ip';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ESP32 configurado em ${_service.esp32BaseUrl}')),
    );

    _refreshStatus();
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
    final userName = _currentUser?.displayName;
    final userEmail = _currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeCar'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _loading ? null : () => _refreshStatus(),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshStatus();
          await _loadAlertHistoryFromFirestore();
        },
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            if (userName != null || userEmail != null) ...[
              _buildUserCard(userName, userEmail),
              const SizedBox(height: 16),
            ],
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildConfigCard(),
            const SizedBox(height: 16),
            _buildStatusGrid(),
            const SizedBox(height: 16),
            _buildActionPanel(),
            const SizedBox(height: 16),
            _buildAlertHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(String? userName, String? userEmail) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              child: Icon(Icons.person_outline),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName ?? 'Usuário SafeCar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail ?? 'Conta conectada ao Firebase',
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

  Widget _buildHeaderCard() {
    final hasAlerts = _status.activeAlerts.isNotEmpty;
    final statusText = hasAlerts ? 'Atenção necessária' : 'Veículo monitorado';
    final statusIcon = hasAlerts ? Icons.warning_amber_rounded : Icons.shield_outlined;
    final statusColor = hasAlerts ? AppTheme.warning : AppTheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(statusIcon, color: statusColor, size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _status.connected
                        ? '${_status.source} • atualizado às ${_formatTime(_status.updatedAt)}'
                        : _status.source,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.danger),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conexão do protótipo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Modo simulação'),
              subtitle: Text(
                _service.simulationMode
                    ? 'Use enquanto ainda não tiver todos os sensores.'
                    : 'O app tentará ler dados reais do ESP32.',
              ),
              value: _service.simulationMode,
              activeColor: AppTheme.primary,
              onChanged: (value) {
                setState(() {
                  _service.simulationMode = value;
                });
                _refreshStatus();
              },
            ),
            if (!_service.simulationMode) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _ipController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'IP do ESP32',
                  hintText: '192.168.4.1',
                  prefixIcon: Icon(Icons.wifi),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _applyEsp32Config,
                  icon: const Icon(Icons.settings_ethernet),
                  label: const Text('Conectar ao ESP32'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusGrid() {
    final items = [
      _StatusItem(
        'Portas',
        _status.doorsLocked ? 'Trancadas' : 'Abertas',
        Icons.lock,
        _status.doorsLocked,
      ),
      _StatusItem(
        'Faróis',
        _status.headlightsOn ? 'Acesos' : 'Apagados',
        Icons.lightbulb_outline,
        !_status.headlightsOn,
      ),
      _StatusItem(
        'Vidros',
        _status.windowsClosed ? 'Fechados' : 'Abertos',
        Icons.window,
        _status.windowsClosed,
      ),
      _StatusItem(
        'Alarme',
        _status.alarmActive ? 'Ativo' : 'Inativo',
        Icons.notifications_active_outlined,
        _status.alarmActive,
      ),
      _StatusItem(
        'Impacto',
        _status.vibrationDetected ? 'Detectado' : 'Normal',
        Icons.vibration,
        !_status.vibrationDetected,
      ),
      _StatusItem(
        'Bateria',
        '${_status.batteryVoltage.toStringAsFixed(1)} V',
        Icons.battery_charging_full,
        _status.batteryVoltage >= 11.8,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.35,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final color = item.ok ? AppTheme.primary : AppTheme.warning;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(item.icon, color: color),
                    Icon(
                      item.ok ? Icons.check_circle : Icons.error,
                      color: color,
                      size: 20,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.value,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ações rápidas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _ActionButton(
              icon: _status.doorsLocked ? Icons.lock_open : Icons.lock,
              label: _status.doorsLocked ? 'Destrancar portas' : 'Trancar portas',
              onPressed: () => _sendCommand(
                _status.doorsLocked ? 'unlock_doors' : 'lock_doors',
                _status.doorsLocked ? 'Comando: destrancar portas' : 'Comando: trancar portas',
              ),
            ),
            _ActionButton(
              icon: Icons.notifications_active,
              label: _status.alarmActive ? 'Desativar alarme' : 'Ativar alarme',
              onPressed: () => _sendCommand(
                'toggle_alarm',
                'Comando do alarme enviado',
              ),
            ),
            _ActionButton(
              icon: Icons.lightbulb_outline,
              label: _status.headlightsOn ? 'Apagar faróis' : 'Simular faróis acesos',
              onPressed: () => _sendCommand(
                _status.headlightsOn ? 'turn_off_lights' : 'toggle_lights',
                'Estado dos faróis atualizado',
              ),
            ),
            _ActionButton(
              icon: Icons.window,
              label: _status.windowsClosed ? 'Simular vidro aberto' : 'Fechar vidros',
              onPressed: () => _sendCommand(
                _status.windowsClosed ? 'toggle_windows' : 'close_windows',
                'Estado dos vidros atualizado',
              ),
            ),
            _ActionButton(
              icon: Icons.car_crash_outlined,
              label: 'Simular impacto suspeito',
              onPressed: () => _sendCommand(
                'simulate_impact',
                'Impacto simulado',
              ),
            ),
            _ActionButton(
              icon: Icons.cleaning_services_outlined,
              label: 'Limpar eventos de impacto',
              onPressed: () => _sendCommand(
                'clear_events',
                'Eventos de impacto limpos',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _loadingHistory ? 'Carregando histórico...' : 'Histórico de alertas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: _history.isEmpty ? null : () => _clearHistory(),
                  child: const Text('Limpar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_history.isEmpty)
              const Text(
                'Nenhum alerta registrado até agora.',
                style: TextStyle(color: Colors.black54),
              )
            else
              ..._history.map((alert) {
                final color = alert.severity == AlertSeverity.danger
                    ? AppTheme.danger
                    : alert.severity == AlertSeverity.info
                        ? AppTheme.primary
                        : AppTheme.warning;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              alert.message,
                              style: const TextStyle(color: Colors.black87),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTime(alert.time),
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');

    return '$hour:$minute:$second';
  }
}

class _StatusItem {
  final String title;
  final String value;
  final IconData icon;
  final bool ok;

  const _StatusItem(this.title, this.value, this.icon, this.ok);
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }
}