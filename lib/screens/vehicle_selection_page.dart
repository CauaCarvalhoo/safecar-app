import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class VehicleSelectionPage extends StatelessWidget {
  const VehicleSelectionPage({super.key});

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login_choice',
      (route) => false,
    );
  }

  Future<void> _openVehicleProfile(BuildContext context) async {
    await Navigator.pushNamed(context, '/vehicle_profile');
  }

  void _openDashboard(
    BuildContext context, {
    required String vehicleId,
    required Map<String, dynamic> vehicleData,
  }) {
    Navigator.pushNamed(
      context,
      '/fleet_dashboard',
      arguments: {
        'vehicleId': vehicleId,
        'vehicleData': vehicleData,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Selecionar veículo'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: user == null
          ? const Center(
              child: Text('Usuário não autenticado.'),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('vehicles')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Não foi possível carregar os veículos da frota.',
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

                final vehicles = snapshot.data?.docs ?? [];

                vehicles.sort((a, b) {
                  final aName = a.data()['nickname']?.toString() ?? '';
                  final bName = b.data()['nickname']?.toString() ?? '';
                  return aName.compareTo(bName);
                });

                return RefreshIndicator(
                  onRefresh: () async {},
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      _buildHeaderCard(context, vehicles.length),
                      const SizedBox(height: 16),
                      if (vehicles.isEmpty)
                        _buildEmptyFleetCard(context)
                      else
                        ...vehicles.map((doc) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildVehicleCard(
                              context,
                              vehicleId: doc.id,
                              data: doc.data(),
                            ),
                          );
                        }),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _openVehicleProfile(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Cadastrar ou editar veículo'),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, int vehicleCount) {
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
                Icons.local_shipping_outlined,
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
                    'Frota SafeCar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicleCount == 1
                        ? '1 veículo cadastrado'
                        : '$vehicleCount veículos cadastrados',
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

  Widget _buildEmptyFleetCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(
              Icons.directions_car_filled_rounded,
              color: AppTheme.primary,
              size: 58,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum veículo cadastrado',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cadastre um veículo para começar a acompanhar localização, velocidade, score do motorista e avisos da frota.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openVehicleProfile(context),
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar veículo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(
    BuildContext context, {
    required String vehicleId,
    required Map<String, dynamic> data,
  }) {
    final nickname = data['nickname']?.toString() ?? 'Veículo sem apelido';
    final brand = data['brand']?.toString() ?? '';
    final model = data['model']?.toString() ?? '';
    final year = data['year']?.toString() ?? '';
    final plate = data['plate']?.toString() ?? '';
    final color = data['color']?.toString() ?? '';
    final imageBase64 = data['imageBase64']?.toString() ?? '';

    final details = [
      if (brand.isNotEmpty || model.isNotEmpty) '$brand $model'.trim(),
      if (year.isNotEmpty) year,
      if (plate.isNotEmpty) 'Placa: $plate',
      if (color.isNotEmpty) 'Cor: $color',
    ].join(' • ');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openDashboard(
          context,
          vehicleId: vehicleId,
          vehicleData: data,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              _buildVehicleImage(imageBase64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details.isEmpty
                          ? 'Toque para abrir a telemetria do veículo.'
                          : details,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'Abrir dashboard',
                        style: TextStyle(
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleImage(String imageBase64) {
    if (imageBase64.isEmpty) {
      return Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(
          Icons.directions_car_filled_rounded,
          color: AppTheme.primary,
          size: 42,
        ),
      );
    }

    try {
      final bytes = base64Decode(imageBase64);

      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.memory(
          bytes,
          width: 82,
          height: 82,
          fit: BoxFit.cover,
        ),
      );
    } catch (error) {
      return Container(
        width: 82,
        height: 82,
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
}