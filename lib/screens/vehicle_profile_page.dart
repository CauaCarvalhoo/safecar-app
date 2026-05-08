import 'dart:convert';
import 'dart:typed_data';

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
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  final _nicknameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();

  Uint8List? _vehicleImageBytes;
  String? _vehicleImageBase64;
  String? _vehicleImageName;

  bool _loading = false;
  bool _saving = false;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
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

  Future<void> _loadVehicleData() async {
    final user = _currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('vehicles')
          .doc('main')
          .get();

      if (doc.exists) {
        final data = doc.data();

        _nicknameController.text = data?['nickname']?.toString() ?? '';
        _brandController.text = data?['brand']?.toString() ?? '';
        _modelController.text = data?['model']?.toString() ?? '';
        _yearController.text = data?['year']?.toString() ?? '';
        _plateController.text = data?['plate']?.toString() ?? '';
        _colorController.text = data?['color']?.toString() ?? '';

        final savedImageBase64 = data?['imageBase64']?.toString();

        if (savedImageBase64 != null && savedImageBase64.isNotEmpty) {
          _vehicleImageBase64 = savedImageBase64;
          _vehicleImageBytes = base64Decode(savedImageBase64);
          _vehicleImageName = data?['imageName']?.toString();
        }
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar os dados do veículo.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickVehicleImage() async {
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 55,
      );

      if (pickedImage == null) {
        return;
      }

      final bytes = await pickedImage.readAsBytes();
      final imageBase64 = base64Encode(bytes);

      if (imageBase64.length > 900000) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagem muito grande. Escolha uma imagem menor.'),
          ),
        );
        return;
      }

      setState(() {
        _vehicleImageBytes = bytes;
        _vehicleImageBase64 = imageBase64;
        _vehicleImageName = pickedImage.name;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível selecionar a imagem.'),
        ),
      );
    }
  }

  void _removeVehicleImage() {
    setState(() {
      _vehicleImageBytes = null;
      _vehicleImageBase64 = null;
      _vehicleImageName = null;
    });
  }

  Future<void> _saveVehicleData() async {
    final user = _currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login novamente para salvar.')),
      );
      return;
    }

    final formIsValid = _formKey.currentState?.validate() ?? false;

    if (!formIsValid) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('vehicles')
          .doc('main')
          .set({
        'nickname': _nicknameController.text.trim(),
        'brand': _brandController.text.trim(),
        'model': _modelController.text.trim(),
        'year': _yearController.text.trim(),
        'plate': _plateController.text.trim().toUpperCase(),
        'color': _colorController.text.trim(),
        'imageBase64': _vehicleImageBase64 ?? '',
        'imageName': _vehicleImageName ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veículo salvo com sucesso!')),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar o veículo. Tente novamente.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _buildVehiclePreview() {
    if (_vehicleImageBytes == null) {
      return Container(
        height: 190,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Icon(
            Icons.directions_car_filled_rounded,
            color: AppTheme.primary,
            size: 82,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.memory(
        _vehicleImageBytes!,
        height: 190,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _loading || _saving;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Veículo monitorado'),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Dados do veículo',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Cadastre as informações do veículo que será monitorado pelo SafeCar.',
                                style: TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 18),

                              _buildVehiclePreview(),
                              const SizedBox(height: 12),

                              ElevatedButton.icon(
                                onPressed: isBusy ? null : _pickVehicleImage,
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Escolher imagem do veículo'),
                              ),

                              if (_vehicleImageBytes != null) ...[
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: isBusy ? null : _removeVehicleImage,
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Remover imagem'),
                                ),
                              ],

                              if (_vehicleImageName != null && _vehicleImageName!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Imagem selecionada: $_vehicleImageName',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 18),

                              TextFormField(
                                controller: _nicknameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Apelido do veículo',
                                  hintText: 'Ex: Meu Civic',
                                  prefixIcon: Icon(Icons.drive_eta_outlined),
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';

                                  if (text.isEmpty) {
                                    return 'Informe um apelido para o veículo.';
                                  }

                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _brandController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Marca',
                                  hintText: 'Ex: Honda',
                                  prefixIcon: Icon(Icons.business_outlined),
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';

                                  if (text.isEmpty) {
                                    return 'Informe a marca.';
                                  }

                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _modelController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Modelo',
                                  hintText: 'Ex: Civic',
                                  prefixIcon: Icon(Icons.directions_car_outlined),
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';

                                  if (text.isEmpty) {
                                    return 'Informe o modelo.';
                                  }

                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _yearController,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText: 'Ano',
                                        hintText: 'Ex: 2018',
                                        prefixIcon: Icon(Icons.calendar_month_outlined),
                                      ),
                                      validator: (value) {
                                        final text = value?.trim() ?? '';

                                        if (text.isEmpty) {
                                          return 'Informe o ano.';
                                        }

                                        if (text.length != 4) {
                                          return 'Ano inválido.';
                                        }

                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _colorController,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText: 'Cor',
                                        hintText: 'Ex: Prata',
                                        prefixIcon: Icon(Icons.palette_outlined),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _plateController,
                                textCapitalization: TextCapitalization.characters,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  labelText: 'Placa',
                                  hintText: 'Ex: ABC1D23',
                                  prefixIcon: Icon(Icons.pin_outlined),
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';

                                  if (text.isEmpty) {
                                    return 'Informe a placa.';
                                  }

                                  if (text.length < 7) {
                                    return 'Placa inválida.';
                                  }

                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              ElevatedButton.icon(
                                onPressed: isBusy ? null : _saveVehicleData,
                                icon: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined),
                                label: Text(_saving ? 'Salvando...' : 'Salvar veículo'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}