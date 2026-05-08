import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class VehicleProfilePage extends StatefulWidget {
  const VehicleProfilePage({super.key});

  @override
  State<VehicleProfilePage> createState() => _VehicleProfilePageState();
}

class _VehicleProfilePageState extends State<VehicleProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();
  final _imageUrlController = TextEditingController();

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
    _imageUrlController.dispose();
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
        _imageUrlController.text = data?['imageUrl']?.toString() ?? '';
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
        'imageUrl': _imageUrlController.text.trim(),
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
    final imageUrl = _imageUrlController.text.trim();

    if (imageUrl.isEmpty) {
      return Container(
        height: 180,
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
      child: Image.network(
        imageUrl,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Text(
                'Não foi possível carregar a imagem.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          );
        },
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
                                'Essas informações serão salvas no Firebase e usadas na tela principal do SafeCar.',
                                style: TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 18),

                              _buildVehiclePreview(),
                              const SizedBox(height: 18),

                              TextFormField(
                                controller: _imageUrlController,
                                keyboardType: TextInputType.url,
                                decoration: const InputDecoration(
                                  labelText: 'URL da imagem do veículo',
                                  hintText: 'https://exemplo.com/carro.jpg',
                                  prefixIcon: Icon(Icons.image_outlined),
                                ),
                                onChanged: (_) {
                                  setState(() {});
                                },
                              ),
                              const SizedBox(height: 16),

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