import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';

class VehicleProfilePage extends StatefulWidget {
  const VehicleProfilePage({super.key});

  @override
  State<VehicleProfilePage> createState() => _VehicleProfilePageState();
}

class _VehicleProfilePageState extends State<VehicleProfilePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  String? _vehicleId;
  String _imageBase64 = '';

  bool _loading = false;
  bool _routeArgumentsLoaded = false;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  bool get _editingVehicle => _vehicleId != null && _vehicleId!.isNotEmpty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_routeArgumentsLoaded) {
      return;
    }

    _routeArgumentsLoaded = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map) {
      final receivedVehicleId = args['vehicleId']?.toString();
      final receivedVehicleData = args['vehicleData'];

      if (receivedVehicleId != null && receivedVehicleId.isNotEmpty) {
        _vehicleId = receivedVehicleId;
      }

      if (receivedVehicleData is Map<String, dynamic>) {
        _fillForm(receivedVehicleData);
      }
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _fillForm(Map<String, dynamic> data) {
    _nicknameController.text = data['nickname']?.toString() ?? '';
    _brandController.text = data['brand']?.toString() ?? '';
    _modelController.text = data['model']?.toString() ?? '';
    _yearController.text = data['year']?.toString() ?? '';
    _plateController.text = data['plate']?.toString() ?? '';
    _colorController.text = data['color']?.toString() ?? '';
    _imageBase64 = data['imageBase64']?.toString() ?? '';
  }

  Future<void> _pickVehicleImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 55,
      maxWidth: 900,
      maxHeight: 900,
    );

    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();

    setState(() {
      _imageBase64 = base64Encode(bytes);
    });
  }

  void _removeVehicleImage() {
    setState(() {
      _imageBase64 = '';
    });
  }

  Future<void> _saveVehicle() async {
    final user = _currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário não autenticado.'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    final vehiclesCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('vehicles');

    final vehicleData = {
      'nickname': _nicknameController.text.trim(),
      'brand': _brandController.text.trim(),
      'model': _modelController.text.trim(),
      'year': _yearController.text.trim(),
      'plate': _plateController.text.trim().toUpperCase(),
      'color': _colorController.text.trim(),
      'imageBase64': _imageBase64,
      'updatedAt': Timestamp.now(),
    };

    try {
      if (_editingVehicle) {
        await vehiclesCollection.doc(_vehicleId).set(
          vehicleData,
          SetOptions(merge: true),
        );
      } else {
        await vehiclesCollection.add({
          ...vehicleData,
          'createdAt': Timestamp.now(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingVehicle
                ? 'Veículo atualizado com sucesso.'
                : 'Veículo cadastrado com sucesso.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar o veículo.'),
        ),
      );
    }
  }

  Future<void> _confirmDeleteVehicle() async {
    if (!_editingVehicle) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir veículo'),
          content: const Text(
            'Tem certeza que deseja excluir este veículo da frota?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _deleteVehicle();
  }

  Future<void> _deleteVehicle() async {
    final user = _currentUser;

    if (user == null || _vehicleId == null) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('vehicles')
          .doc(_vehicleId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veículo excluído da frota.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível excluir o veículo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _editingVehicle ? 'Editar veículo' : 'Cadastrar veículo';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_editingVehicle)
            IconButton(
              tooltip: 'Excluir veículo',
              icon: const Icon(Icons.delete_outline),
              onPressed: _loading ? null : _confirmDeleteVehicle,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildFormCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _buildVehicleImagePreview(),
            const SizedBox(height: 14),
            Text(
              _editingVehicle
                  ? 'Atualize os dados do veículo'
                  : 'Adicione um veículo à frota',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Essas informações serão usadas na tela de seleção e na dashboard da frota.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _pickVehicleImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Imagem'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading || _imageBase64.isEmpty
                        ? null
                        : _removeVehicleImage,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remover'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleImagePreview() {
    if (_imageBase64.isEmpty) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(
          Icons.directions_car_filled_rounded,
          color: AppTheme.primary,
          size: 64,
        ),
      );
    }

    try {
      final bytes = base64Decode(_imageBase64);

      return ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.memory(
          bytes,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    } catch (error) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(
          Icons.broken_image_outlined,
          color: AppTheme.warning,
          size: 54,
        ),
      );
    }
  }

  Widget _buildFormCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Apelido do veículo',
                  prefixIcon: Icon(Icons.drive_eta_outlined),
                  hintText: 'Ex: Caminhão 01, Van Entregas, Carro Diretor',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe um apelido para o veículo.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Marca',
                  prefixIcon: Icon(Icons.factory_outlined),
                  hintText: 'Ex: Fiat, Ford, Volkswagen',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Modelo',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                  hintText: 'Ex: Fiorino, Ranger, Delivery',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(
                  labelText: 'Ano',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                  hintText: 'Ex: 2020',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return null;
                  }

                  if (text.length != 4 || int.tryParse(text) == null) {
                    return 'Informe um ano válido com 4 dígitos.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(
                  labelText: 'Placa',
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                  hintText: 'Ex: ABC1D23',
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Cor',
                  prefixIcon: Icon(Icons.palette_outlined),
                  hintText: 'Ex: Branco, Prata, Preto',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _saveVehicle,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _loading
                        ? 'Salvando...'
                        : _editingVehicle
                            ? 'Salvar alterações'
                            : 'Cadastrar veículo',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}